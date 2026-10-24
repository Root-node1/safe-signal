import { useState, type KeyboardEvent } from 'react'
import Shell from '../components/Shell'
import { Button, Card, InlineBanner, ProgressRail, SelectionTile, HelplineCard } from '../components/ui'
import { SUPPORT_RESOURCES } from '../lib/support'
import type { NextChoice, NextStep } from '../types'

const PROGRESS_STEPS = ['Incident type', 'Details', 'Support'] as const

// T-09 (FR-6.3, RR-3.3): the reload limitation is disclosed, not fixed. Fixing it
// would mean keeping the submission key across a reload, which needs persistent
// storage of the report itself in the browser (FR-6.1). Shown in the failure
// banner, in both the timeout and the network branch.
const RELOAD_CAVEAT =
  'Tapping Submit report again is safe as long as you stay on this page. Reloading the page loses the submission key, so a report sent after a reload may be stored twice.'

interface StepOption {
  id: NextStep
  title: string
  hint: string
  statusNote: string
  disabled: boolean
}

const STEPS: StepOption[] = [
  {
    id: 'private',
    title: 'Submit without contacting anyone',
    hint: 'Submitting sends your report to the configured SafeSignal backend store. Nobody is contacted.',
    statusNote: 'Available now',
    disabled: false,
  },
  {
    id: 'support',
    title: 'Show emergency and support phone numbers',
    hint: 'Displays official national helplines for you to dial manually. SafeSignal does not make calls for you.',
    statusNote: 'Numbers available below',
    disabled: false,
  },
  {
    id: 'trusted-contact',
    title: 'Alert someone I trust',
    hint: 'Automated SMS notification to a nominated contact is in development and currently unavailable.',
    statusNote: 'Service unavailable · In development',
    disabled: true,
  },
  {
    id: 'check-in',
    title: 'Ask for a partner check-in',
    hint: 'Follow-up safety check-in calls by a partner organization are in development and currently unavailable.',
    statusNote: 'Service unavailable · In development',
    disabled: true,
  },
]

type Props = {
  onSubmit: (choice: NextChoice) => Promise<void>
  onBack: () => void
}

export default function NextStepScreen({ onSubmit, onBack }: Props) {
  const [step, setStep] = useState<NextStep | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [errorType, setErrorType] = useState<'network' | 'timeout' | null>(null)

  const canSubmit = step === 'private' || step === 'support'

  const handleSubmit = async () => {
    if (!step || !canSubmit || submitting) return

    setErrorType(null)
    setSubmitting(true)
    try {
      await onSubmit({
        step,
        contact: null,
      })
    } catch (err: unknown) {
      if (err instanceof Error && err.name === 'TimeoutError') {
        setErrorType('timeout')
      } else {
        setErrorType('network')
      }
      setSubmitting(false)
    }
  }

  return (
    <Shell>
      <ProgressRail steps={PROGRESS_STEPS} current={2} />

      {/* Screen Heading */}
      <header className="mt-3">
        <h1 className="text-[var(--text-2xl)] sm:text-[var(--text-3xl)] font-black leading-tight tracking-tight text-[var(--color-ocean-dark)]">
          What would help most?
        </h1>
        <p className="mt-2 text-[var(--text-base)] sm:text-[var(--text-md)] leading-[24px] text-[var(--color-text-muted)]">
          Choose an option below. Submitting will send the details you provided to the SafeSignal backend store.
        </p>
      </header>

      {/* Support Options Radiogroup */}
      <ul role="radiogroup" aria-label="How to handle your report" className="mt-6 flex flex-col gap-3">
        {STEPS.map((s, index) => {
          const selected = step === s.id
          const enabledIndices = STEPS.map((x, i) => (x.disabled ? -1 : i)).filter((i) => i >= 0)
          const focusable =
            selected ||
            (step === null && enabledIndices.length > 0 && index === enabledIndices[0])
          const onKeyDown = (e: KeyboardEvent<HTMLButtonElement>) => {
            const enabled = STEPS.map((x, i) => (x.disabled ? -1 : i)).filter((i) => i >= 0)
            if (enabled.length === 0) return
            const pos = enabled.indexOf(index)
            if (pos < 0) return
            let nextPos: number
            if (e.key === 'ArrowDown' || e.key === 'ArrowRight') nextPos = (pos + 1) % enabled.length
            else if (e.key === 'ArrowUp' || e.key === 'ArrowLeft') nextPos = (pos - 1 + enabled.length) % enabled.length
            else if (e.key === 'Home') nextPos = 0
            else if (e.key === 'End') nextPos = enabled.length - 1
            else return
            e.preventDefault()
            const nextId = STEPS[enabled[nextPos]].id
            if (!STEPS[enabled[nextPos]].disabled) {
              setStep(nextId)
              window.setTimeout(() => {
                document.getElementById(nextId)?.focus()
              }, 0)
            }
          }
          return (
            <SelectionTile
              key={s.id}
              id={s.id}
              label={s.title}
              description={s.hint}
              badge={s.statusNote}
              badgeVariant={s.disabled ? 'unavailable' : selected ? 'selected' : 'available'}
              selected={selected}
              disabled={submitting || s.disabled}
              tabIndex={focusable ? 0 : -1}
              onClick={() => {
                if (!s.disabled) setStep(s.id)
              }}
              onKeyDown={onKeyDown}
            />
          )
        })}
      </ul>

      {/* Immediate Support Resource Numbers (When 'support' chosen) */}
      {step === 'support' && (
        <section aria-labelledby="support-resources-title" className="mt-5">
          <h2 id="support-resources-title" className="text-[var(--text-base)] font-bold text-[var(--color-ocean)]">
            Emergency & Support Helplines (Kenya)
          </h2>
          <p className="mt-1 text-[var(--text-xs)] leading-5 text-[var(--color-text-muted)]">
            These are established national helplines in Kenya. Tap any button to open your phone dialer:
          </p>

<ul className="mt-3 flex flex-col gap-2.5">
            {SUPPORT_RESOURCES.map((r) => (
              <HelplineCard key={r.tel} name={r.name} detail={r.detail} tel={r.tel} />
            ))}
          </ul>
        </section>
      )}

{errorType !== null && (
        <InlineBanner variant="error">
          <div className="flex flex-col gap-1.5">
            <div className="flex items-center gap-2 font-bold text-[var(--text-base)]">
              <span aria-hidden="true">⚠</span>
              <span>
                {errorType === 'timeout'
                  ? 'Request timed out after 8 seconds.'
                  : 'Could not connect to SafeSignal server.'}
              </span>
            </div>
            <p>
              {errorType === 'timeout'
                ? 'The server took too long to respond. The report may or may not have reached the server. You can safely tap Submit report again: retrying the same submission will not create a duplicate while the server stays running.'
                : 'Please check your connection and tap Submit report to retry.'}{' '}
              {RELOAD_CAVEAT}
            </p>
          </div>
        </InlineBanner>
      )}

      {/* Action Buttons */}
      <div className="mt-8 flex flex-col gap-3">
        <Button
          type="button"
          variant="primary"
          size="lg"
          fullWidth
          onClick={handleSubmit}
          disabled={!canSubmit || submitting}
        >
          {submitting ? 'Submitting to SafeSignal…' : 'Submit report'}
        </Button>

        <div className="flex items-center justify-between pt-2">
          <button
            type="button"
            onClick={onBack}
            disabled={submitting}
            className="inline-flex min-h-[44px] items-center gap-1.5 px-2 text-[var(--text-base)] font-bold text-[var(--color-teal)] underline underline-offset-4 hover:text-[var(--color-teal-hover)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)] focus-visible:ring-offset-2 rounded-lg disabled:opacity-50"
          >
            <span aria-hidden="true">←</span>
            <span>Back</span>
          </button>

          <span className="text-[var(--text-xs)] font-medium text-[var(--color-text-muted)]">
            Transmits details upon tapping Submit
          </span>
        </div>
      </div>

      {/* Emergency Disclaimer */}
      <Card className="mt-8 border-[var(--color-border-subtle)] bg-[var(--color-surface)] p-4 text-[var(--text-xs)] leading-5 text-[var(--color-text-muted)]">
        <p>
          <strong className="font-semibold text-[var(--color-text-primary)]">Emergency reminder:</strong> SafeSignal does not dispatch emergency units or automatically alert police. If you are in immediate physical danger, please dial <strong className="font-semibold text-[var(--color-ocean)]">999</strong> or <strong className="font-semibold text-[var(--color-ocean)]">112</strong> directly.
        </p>
      </Card>
    </Shell>
  )
}
