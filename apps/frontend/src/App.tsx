import { useState } from 'react'
import Shell from './components/Shell'
import LandingScreen from './screens/LandingScreen'
import IncidentTypeScreen from './screens/IncidentTypeScreen'
import DetailsScreen from './screens/DetailsScreen'
import type { Details, IncidentType, Timing } from './types'

// State only. Nothing is persisted anywhere.
type Screen =
  | { name: 'landing' }
  | { name: 'incident'; timing: Timing }
  | { name: 'details'; timing: Timing; incident: IncidentType }
  | { name: 'next-step'; timing: Timing; incident: IncidentType; details: Details }

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

  // Placeholder until Screen 4 is built.
  return (
    <Shell>
      <h1 className="text-[28px] font-bold leading-[34px]">Next: your options</h1>
      <p className="mt-2 text-[18px] leading-[26px] text-[#4A5259]">
        {screen.incident} / {screen.timing}
        {screen.details.route ? ` / ${screen.details.route}` : ''}
        {screen.details.location ? ' / location added' : ''}
      </p>
      <button
        type="button"
        onClick={() =>
          setScreen({
            name: 'details',
            timing: screen.timing,
            incident: screen.incident,
          })
        }
        className="mt-6 min-h-[44px] self-start px-1 text-[17px] font-medium leading-6 text-[#0F5C5C] underline underline-offset-4"
      >
        Back
      </button>
    </Shell>
  )
}

export default App
