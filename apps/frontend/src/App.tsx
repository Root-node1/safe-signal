import { useEffect, useState } from 'react'
import LandingScreen from './screens/LandingScreen'
import IncidentTypeScreen from './screens/IncidentTypeScreen'
import DetailsScreen from './screens/DetailsScreen'
import NextStepScreen from './screens/NextStepScreen'
import ConfirmationScreen from './screens/ConfirmationScreen'
import AdminScreen from './screens/AdminScreen'
import { buildPayload, createReport } from './lib/api'
import { PROTOTYPE } from './lib/prototype'
import { newReferenceCode } from './lib/referenceCode'
import type { Details, IncidentType, NextChoice, Timing } from './types'

// State only. Nothing is persisted in the browser.
type Screen =
  | { name: 'landing' }
  | { name: 'incident'; timing: Timing }
  | { name: 'details'; timing: Timing; incident: IncidentType }
  | { name: 'next-step'; timing: Timing; incident: IncidentType; details: Details }
  | { name: 'confirmation'; choice: NextChoice; code: string; saved: boolean }

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

  // Admin is reached by URL only (/#admin). It is never linked from the public flow.
  if (hash === '#admin') return <AdminScreen />

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
          try {
            const { code } = await createReport(
              buildPayload(timing, incident, details, choice),
            )
            setScreen({ name: 'confirmation', choice, code, saved: true })
          } catch (err) {
            // A real build must never show a code that was not saved.
            if (!PROTOTYPE) throw err
            setScreen({
              name: 'confirmation',
              choice,
              code: newReferenceCode(),
              saved: false,
            })
          }
        }}
        onBack={() => setScreen({ name: 'details', timing, incident })}
      />
    )
  }

  return (
    <ConfirmationScreen
      choice={screen.choice}
      code={screen.code}
      saved={screen.saved}
      onRestart={() => setScreen({ name: 'landing' })}
    />
  )
}

export default App
