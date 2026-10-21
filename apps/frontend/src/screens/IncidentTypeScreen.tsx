import { useState, type KeyboardEvent, type ReactNode } from 'react'
import Shell from '../components/Shell'
import { ProgressRail, SelectionTile, InlineBanner } from '../components/ui'
import type { IncidentType } from '../types'

interface Option {
  id: IncidentType
  label: string
  description: string
  icon: ReactNode
}

/**
 * One consistent icon family for every category: 20px outline, 1.75 stroke,
 * round caps and joins. Icons are decorative and hidden from assistive tech.
 */
function Icon({ children }: { children: ReactNode }) {
  return (
    <svg
      className="h-5 w-5 shrink-0"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={1.75}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
    >
      {children}
    </svg>
  )
}

const OPTIONS: Option[] = [
  {
    id: 'harassment',
    label: 'Someone is harassing me',
    description: 'Persistent verbal remarks, intimidation, or aggressive behavior.',
    icon: (
      <Icon>
        <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5Z" />
        <path d="M8.5 10.5h7M8.5 14h4" />
      </Icon>
    ),
  },
  {
    id: 'threats',
    label: 'Someone is threatening me',
    description: 'Direct verbal or physical threats of harm or extortion.',
    icon: (
      <Icon>
        <path d="M12 3 4 6v6c0 4.4 3.4 8.1 8 9 4.6-.9 8-4.6 8-9V6l-8-3Z" />
        <path d="M12 8v4.5M12 16h.01" />
      </Icon>
    ),
  },
  {
    id: 'touching',
    label: 'Unwanted touching',
    description: 'Non-consensual physical contact, crowding, or invasion of space.',
    icon: (
      <Icon>
        <path d="M18.4 18.4A9 9 0 0 1 5.6 5.6m12.8 12.8A9 9 0 0 1 5.6 5.6" />
        <path d="M8.5 12.5 11 10m4.5 4.5L15 15" />
      </Icon>
    ),
  },
  {
    id: 'followed',
    label: "I think I'm being followed",
    description: 'Someone tailing you at a stage, terminal, or after alighting.',
    icon: (
      <Icon>
        <path d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
        <path d="M2.5 12C3.7 7.9 7.5 5 12 5s8.3 2.9 9.5 7c-1.2 4.1-5 7-9.5 7s-8.3-2.9-9.5-7Z" />
      </Icon>
    ),
  },
  {
    id: 'dangerous-driving',
    label: 'The driver is driving dangerously',
    description: 'Excessive speeding, overlapping, reckless overtaking, or impaired driving.',
    icon: (
      <Icon>
        <path d="M13 10V4l-8 10h6v6l8-10h-6V4Z" />
      </Icon>
    ),
  },
  {
    id: 'unsure',
    label: 'Something else / not sure',
    description: 'Unusual disturbance, theft, baggage interference, or other safety concern.',
    icon: (
      <Icon>
        <circle cx="12" cy="12" r="9" />
        <path d="M9.6 9.3a2.5 2.5 0 0 1 4.8.9c0 1.7-2.4 2-2.4 3.3M12 17h.01" />
      </Icon>
    ),
  },
]

type Props = {
  onSelect: (id: IncidentType) => void | Promise<void>
  onBack: () => void
}

const STEPS = ['Incident type', 'Details', 'Support'] as const

export default function IncidentTypeScreen({ onSelect, onBack }: Props) {
  const [pickedId, setPickedId] = useState<IncidentType | null>(null)
  const [error, setError] = useState(false)

  const choose = async (id: IncidentType) => {
    if (pickedId) return
    setError(false)
    setPickedId(id)
    try {
      await onSelect(id)
    } catch {
      setPickedId(null)
      setError(true)
    }
  }

  return (
    <Shell>
      <ProgressRail steps={STEPS} current={0} />

      <header className="mt-6">
        <h1 className="text-[var(--text-2xl)] font-bold leading-[1.2] tracking-[-0.02em] text-[var(--color-ocean-dark)] sm:text-[var(--text-3xl)]">
          What is happening?
        </h1>
        <p className="mt-2 max-w-[46ch] text-[var(--text-base)] leading-6 text-[var(--color-text-muted)] sm:text-[var(--text-md)]">
          Choose the category that best describes your situation. You stay in control of what happens next.
        </p>
      </header>

      {error && (
        <InlineBanner variant="error">
          <span>We could not process that selection. Please try again.</span>
        </InlineBanner>
      )}

      <div role="radiogroup" aria-label="Incident categories" className="mt-6">
        <ul className="flex flex-col gap-2.5">
        {OPTIONS.map((o, index) => {
          const selected = pickedId === o.id
          const disabled = pickedId !== null && !selected
          const focusable = selected || (pickedId === null && index === 0)

          const onKeyDown = (e: KeyboardEvent<HTMLButtonElement>) => {
            const last = OPTIONS.length - 1
            let next: number
            if (e.key === 'ArrowDown' || e.key === 'ArrowRight') next = index === last ? 0 : index + 1
            else if (e.key === 'ArrowUp' || e.key === 'ArrowLeft') next = index === 0 ? last : index - 1
            else if (e.key === 'Home') next = 0
            else if (e.key === 'End') next = last
            else return
            e.preventDefault()
            void choose(OPTIONS[next].id)
          }

          return (
            <SelectionTile
              key={o.id}
              id={o.id}
              label={o.label}
              description={o.description}
              icon={o.icon}
              selected={selected}
              disabled={disabled}
              tabIndex={focusable ? 0 : -1}
              onClick={() => choose(o.id)}
              onKeyDown={onKeyDown}
            />
          )
        })}
        </ul>
      </div>

      <div className="mt-7 flex items-center justify-between gap-4 border-t border-[var(--color-border-subtle)] pt-5">
        <button
          type="button"
          onClick={onBack}
          disabled={pickedId !== null}
          className="inline-flex min-h-[44px] items-center gap-1.5 rounded-lg px-1 text-[var(--text-base)] font-semibold text-[var(--color-teal)] transition-colors motion-reduce:transition-none hover:text-[var(--color-teal-hover)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-focus)] focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-45"
        >
          <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M19 12H5m0 0 6-6m-6 6 6 6" />
          </svg>
          <span>Back</span>
        </button>

        <p className="text-right text-[var(--text-xs)] leading-4 text-[var(--color-text-muted)]">
          Nothing is shared yet
        </p>
      </div>

      <InlineBanner variant="info">
        <span>
          <span className="font-semibold text-[var(--color-text-primary)]">Discreet and flexible.</span>{' '}
          Add route or vehicle details on the next screen, or skip straight to support options.
        </span>
      </InlineBanner>
    </Shell>
  )
}
