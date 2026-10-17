import { useState } from 'react'
import Shell from './components/Shell'
import LandingScreen from './screens/LandingScreen'
import IncidentTypeScreen from './screens/IncidentTypeScreen'
import type { IncidentType, Timing } from './types'

// State only. Nothing is persisted anywhere.
type Screen =
  | { name: 'landing' }
  | { name: 'incident'; timing: Timing }
  | { name: 'details'; timing: Timing; incident: IncidentType }

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

  // Placeholder until Screen 3 is built.
  return (
    <Shell>
      <h1 className="text-[28px] font-bold leading-[34px]">Next: details</h1>
      <p className="mt-2 text-[18px] leading-[26px] text-[#4A5259]">
        Picked: {screen.incident} ({screen.timing})
      </p>
      <button
        type="button"
        onClick={() => setScreen({ name: 'incident', timing: screen.timing })}
        className="mt-6 min-h-[44px] self-start px-1 text-[17px] font-medium leading-6 text-[#0F5C5C] underline underline-offset-4"
      >
        Back
      </button>
    </Shell>
  )
}

export default App
