import { useEffect, useRef, useState } from 'react'
import LandingScreen from './screens/LandingScreen'
import IncidentTypeScreen from './screens/IncidentTypeScreen'
import DetailsScreen from './screens/DetailsScreen'
import NextStepScreen from './screens/NextStepScreen'
import ConfirmationScreen from './screens/ConfirmationScreen'
import AdminScreen from './screens/AdminScreen'
import { AssistantLauncher, AssistantModal } from './assistant'
import { buildPayload, createReport, newSubmissionKey } from './lib/api'
import { resolveSubmissionKey, type SubmissionKeyPolicy } from './lib/submissionKeyPolicy'
import type { Details, IncidentType, NextChoice, Timing } from './types'

// State only. Nothing is persisted in the browser.
type Screen =
  | { name: 'landing' }
  | { name: 'incident'; timing: Timing }
  | { name: 'details'; timing: Timing; incident: IncidentType }
  | { name: 'next-step'; timing: Timing; incident: IncidentType; details: Details }
  | { name: 'confirmation'; choice: NextChoice; code: string }

function useHash(): string {
  const [hash, setHash] = useState(() => window.location.hash)
  useEffect(() => {
    const onChange = () => setHash(window.location.hash)
    window.addEventListener('hashchange', onChange)
    return () => window.removeEventListener('hashchange', onChange)
  }, [])
  return hash
}

function App() {
  const hash = useHash()
  const [screen, setScreen] = useState<Screen>({ name: 'landing' })
  const [assistantOpen, setAssistantOpen] = useState(false)
  const contentRef = useRef<HTMLDivElement>(null)
  const prevScreen = useRef(screen.name)
  // Identity of the in-flight logical submission. Memory only; cleared on success/restart.
  const submission = useRef<SubmissionKeyPolicy>(null)

  // On a real screen change only: reset scroll and move focus to the new heading.
  // Skipped on first load and on unrelated state updates (typing, assistant).
  useEffect(() => {
    if (prevScreen.current === screen.name) return
    prevScreen.current = screen.name
    window.scrollTo(0, 0)
    const h1 = contentRef.current?.querySelector<HTMLElement>('main h1')
    if (h1) {
      h1.tabIndex = -1
      h1.focus({ preventScroll: true })
    }
  }, [screen.name])

  // Admin is reached by URL only (/#admin). It is never linked from the public flow.
  if (hash === '#admin') return <AdminScreen />

  // Only show assistant launcher on non-critical informational screens (landing).
  // Do NOT render on reporting screens (incident, details, next-step) to keep form viewports completely unobstructed.
  const showAssistantLauncher = screen.name === 'landing'

  const renderScreen = () => {
    if (screen.name === 'landing') {
      return (
        <LandingScreen
          onStart={(timing) => setScreen({ name: 'incident', timing })}
        />
      )
    }

    if (screen.name === 'incident') {
      return (
        <IncidentTypeScreen
          onSelect={(incident) =>
            setScreen({ name: 'details', timing: screen.timing, incident })
          }
          onBack={() => setScreen({ name: 'landing' })}
        />
      )
    }

    if (screen.name === 'details') {
      return (
        <DetailsScreen
          onContinue={(details) =>
            setScreen({
              name: 'next-step',
              timing: screen.timing,
              incident: screen.incident,
              details,
            })
          }
          onBack={() => setScreen({ name: 'incident', timing: screen.timing })}
        />
      )
    }

    if (screen.name === 'next-step') {
      const { timing, incident, details } = screen
      return (
        <NextStepScreen
          onSubmit={async (choice) => {
            // Only transition to confirmation on real backend success.
            const payload = buildPayload(timing, incident, details, choice)
            // Same payload as actually sent => same key (safe retry, even after Back/Forward).
            // Changed payload => new key, avoiding a 409 from the backend.
            const sig = JSON.stringify(payload)
            const policy = resolveSubmissionKey(submission.current, sig, newSubmissionKey)
            submission.current = policy
            // resolveSubmissionKey always returns a policy for a signature.
            const { code } = await createReport(payload, policy!.key)
            submission.current = null
            setScreen({ name: 'confirmation', choice, code })
          }}
          onBack={() => setScreen({ name: 'details', timing, incident })}
        />
      )
    }

    return (
      <ConfirmationScreen
        choice={screen.choice}
        code={screen.code}
        onRestart={() => {
          submission.current = null
          setScreen({ name: 'landing' })
        }}
      />
    )
  }

  return (
    <>
      {/* Sibling of the modal so the page can be made inert without hiding the dialog. */}
      <div ref={contentRef} inert={assistantOpen}>
        {renderScreen()}
        {showAssistantLauncher && (
          <AssistantLauncher
            onClick={() => setAssistantOpen(true)}
          />
        )}
      </div>
      <AssistantModal
        isOpen={assistantOpen}
        onClose={() => setAssistantOpen(false)}
        returnFocusId="assistant-launcher-btn"
      />
    </>
  )
}

export default App
