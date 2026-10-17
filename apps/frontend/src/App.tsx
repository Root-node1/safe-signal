import { useEffect, useState } from 'react'
import LandingScreen from './screens/LandingScreen'
import IncidentTypeScreen from './screens/IncidentTypeScreen'
import DetailsScreen from './screens/DetailsScreen'
import NextStepScreen from './screens/NextStepScreen'
import ConfirmationScreen from './screens/ConfirmationScreen'
import AdminScreen from './screens/AdminScreen'
import type { Details, IncidentType, NextChoice, Timing } from './types'

// State only. Nothing is persisted anywhere.
type Screen =
  | { name: 'landing' }
  | { name: 'incident'; timing: Timing }
  | { name: 'details'; timing: Timing; incident: IncidentType }
  | { name: 'next-step'; timing: Timing; incident: IncidentType; details: Details }
  | { name: 'confirmation'; choice: NextChoice }

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
    return (
      <NextStepScreen
        onSubmit={(choice) => setScreen({ name: 'confirmation', choice })}
        onBack={() =>
          setScreen({
            name: 'details',
            timing: screen.timing,
            incident: screen.incident,
          })
        }
      />
    )
  }

  return (
    <ConfirmationScreen
      choice={screen.choice}
      onRestart={() => setScreen({ name: 'landing' })}
    />
  )
}

export default App
