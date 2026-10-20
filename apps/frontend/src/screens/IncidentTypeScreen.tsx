import { useState, type ReactNode } from 'react'
import Shell from '../components/Shell'
import { Card } from '../components/ui'
import type { IncidentType } from '../types'

interface Option {
  id: IncidentType
  label: string
  description: string
  icon: ReactNode
}

const OPTIONS: Option[] = [
  {
    id: 'harassment',
    label: 'Someone is harassing me',
    description: 'Persistent verbal remarks, intimidation, or aggressive behavior.',
    icon: (
      <svg className="h-6 w-6 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2} aria-hidden="true">
        <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
      </svg>
    ),
  },
  {
    id: 'threats',
    label: 'Someone is threatening me',
    description: 'Direct verbal or physical threats of harm or extortion.',
    icon: (
      <svg className="h-6 w-6 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2} aria-hidden="true">
        <path strokeLinecap="round" strokeLinejoin="round" d="M20.618 5.984A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016zM12 9v2m0 4h.01" />
      </svg>
    ),
  },
  {
    id: 'touching',
    label: 'Unwanted touching',
    description: 'Non-consensual physical contact, crowding, or invasion of space.',
    icon: (
      <svg className="h-6 w-6 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2} aria-hidden="true">
        <path strokeLinecap="round" strokeLinejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
      </svg>
    ),
  },
  {
    id: 'followed',
    label: "I think I'm being followed",
    description: 'Someone tailing you at a stage, terminal, or after alighting.',
    icon: (
      <svg className="h-6 w-6 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2} aria-hidden="true">
        <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        <path strokeLinecap="round" strokeLinejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
      </svg>
    ),
  },
  {
    id: 'dangerous-driving',
    label: 'The driver is driving dangerously',
    description: 'Excessive speeding, overlapping, reckless overtaking, or impaired driving.',
    icon: (
      <svg className="h-6 w-6 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2} aria-hidden="true">
        <path strokeLinecap="round" strokeLinejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z" />
      </svg>
    ),
  },
  {
    id: 'unsure',
    label: 'Something else / not sure',
    description: 'Unusual disturbance, theft, baggage interference, or other safety concern.',
    icon: (
      <svg className="h-6 w-6 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2} aria-hidden="true">
        <path strokeLinecap="round" strokeLinejoin="round" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    ),
  },
]

type Props = {
  onSelect: (id: IncidentType) => void | Promise<void>
  onBack: () => void
}

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
      {/* Progress / Step Indication */}
      <div className="flex items-center justify-between text-[13px] font-semibold tracking-wide text-[var(--color-teal)]">
        <span>Step 1 of 3</span>
        <span className="font-mono text-[12px] uppercase">Incident Type</span>
      </div>

      {/* Heading & Instructions */}
      <header className="mt-3">
        <h1 className="text-[28px] sm:text-[32px] font-black leading-tight tracking-tight text-[var(--color-ocean-dark)]">
          What is happening?
        </h1>
        <p className="mt-2 text-[16px] sm:text-[17px] leading-[24px] text-[var(--color-text-muted)]">
          Select the category that best fits your situation. You remain in control of what happens next.
        </p>
      </header>

      {/* Accessible Error Announcement */}
      {error && (
        <div
          role="alert"
          className="mt-4 flex items-center gap-2.5 rounded-xl border-2 border-[var(--color-coral)] bg-[var(--color-coral-subtle)] px-4 py-3 text-[15px] font-semibold text-[var(--color-coral)]"
        >
          <span aria-hidden="true" className="text-lg">⚠</span>
          <span>We could not process that selection. Please tap again.</span>
        </div>
      )}

      {/* Category Selection List */}
      <ul
        role="list"
        aria-label="Incident categories"
        className="mt-6 flex flex-col gap-3"
      >
        {OPTIONS.map((o) => {
          const selected = pickedId === o.id
          const disabled = pickedId !== null && !selected

          return (
            <li key={o.id}>
              <button
                type="button"
                aria-pressed={selected}
                disabled={disabled}
                onClick={() => choose(o.id)}
                className={`group flex min-h-[72px] w-full items-start gap-3.5 rounded-2xl border-2 p-4 text-left transition-all motion-reduce:transition-none focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)] focus-visible:ring-offset-2 ${
                  selected
                    ? 'border-[var(--color-teal)] bg-[var(--color-teal)] text-white shadow-md'
                    : 'border-[var(--color-border-subtle)] bg-[var(--color-surface)] text-[var(--color-text-primary)] hover:border-[var(--color-teal)] hover:bg-[var(--color-teal-subtle)] active:bg-[var(--color-teal-subtle)] disabled:opacity-40'
                }`}
              >
                {/* Visual Icon */}
                <div
                  aria-hidden="true"
                  className={`mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-xl transition-colors ${
                    selected
                      ? 'bg-white/20 text-white'
                      : 'bg-[var(--color-teal-subtle)] text-[var(--color-teal)] group-hover:bg-[var(--color-teal)] group-hover:text-white'
                  }`}
                >
                  {o.icon}
                </div>

                {/* Text Content */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between gap-2">
                    <span className="text-[17px] sm:text-[18px] font-bold leading-6">
                      {o.label}
                    </span>
                    {/* Visual Checkmark indicator for selected state */}
                    {selected && (
                      <span
                        aria-hidden="true"
                        className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-white text-[13px] font-black text-[var(--color-teal)]"
                      >
                        ✓
                      </span>
                    )}
                  </div>
                  <p
                    className={`mt-1 text-[13px] sm:text-[14px] leading-5 ${
                      selected ? 'text-white/90' : 'text-[var(--color-text-muted)]'
                    }`}
                  >
                    {o.description}
                  </p>
                </div>
              </button>
            </li>
          )
        })}
      </ul>

      {/* Navigation Controls */}
      <div className="mt-6 flex items-center justify-between pt-2">
        <button
          type="button"
          onClick={onBack}
          disabled={pickedId !== null}
          className="inline-flex min-h-[44px] items-center gap-1.5 px-2 text-[16px] font-bold text-[var(--color-teal)] underline underline-offset-4 hover:text-[var(--color-teal-hover)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)] focus-visible:ring-offset-2 rounded-lg disabled:opacity-50"
        >
          <span aria-hidden="true">←</span>
          <span>Back</span>
        </button>

        <span className="text-[13px] font-medium text-[var(--color-text-muted)]">
          Nothing is shared yet
        </span>
      </div>

      {/* Safety Notice Card */}
      <Card className="mt-8 border-[var(--color-border-subtle)] bg-[var(--color-surface)] p-4 text-[13px] leading-5 text-[var(--color-text-muted)]">
        <p>
          <strong className="font-semibold text-[var(--color-text-primary)]">Discreet & flexible:</strong> You can add specific route or vehicle details on the next screen, or skip straight to support options.
        </p>
      </Card>
    </Shell>
  )
}
