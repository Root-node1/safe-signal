import { useState } from 'react'
import Shell from './components/Shell'
import LandingScreen from './screens/LandingScreen'
import IncidentTypeScreen from './screens/IncidentTypeScreen'
import DetailsScreen from './screens/DetailsScreen'
import NextStepScreen from './screens/NextStepScreen'
import type { Details, IncidentType, NextChoice, Timing } from './types'

// State only. Nothing is persisted anywhere.
type Screen =
  | { name: 'landing' }
  | { name: 'incident'; timing: Timing }
  | { name: 'details'; timing: Timing; incident: IncidentType }
  | { name: 'next-step'; timing: Timing; incident: IncidentType; details: Details }
  | {
      name: 'confirmation'
      timing: Timing
      incident: IncidentType
      details: Details
      choice: NextChoice
    }

function App() {
  const [screen, setScreen] = useState<Screen>({ name: 'landing' })

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
        onSubmit={(choice) =>
          setScreen({
            name: 'confirmation',
            timing: screen.timing,
            incident: screen.incident,
            details: screen.details,
            choice,
          })
        }
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

  // Placeholder until Screen 5 (confirmation + reference code) is built.
  return (
    <Shell>
      <h1 className="text-[28px] font-bold leading-[34px]">Next: confirmation</h1>
      <p className="mt-2 text-[18px] leading-[26px] text-[#4A5259]">
        {screen.incident} / {screen.choice.step}
        {screen.choice.contact ? ` / ${screen.choice.contact.phone}` : ''}
      </p>
    </Shell>
  )
}

export default App
