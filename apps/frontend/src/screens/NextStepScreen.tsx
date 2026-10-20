import { useState } from 'react'
import Shell from '../components/Shell'
import { Button, Card } from '../components/ui'
import { SUPPORT_RESOURCES } from '../lib/support'
import type { NextChoice, NextStep } from '../types'

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
      {/* Step / Progress Indicator */}
      <div className="flex items-center justify-between text-[13px] font-semibold tracking-wide text-[var(--color-teal)]">
        <span>Step 3 of 3</span>
        <span className="font-mono text-[12px] uppercase">Review & Submit</span>
      </div>

      {/* Screen Heading */}
      <header className="mt-3">
        <h1 className="text-[28px] sm:text-[32px] font-black leading-tight tracking-tight text-[var(--color-ocean-dark)]">
          What would help most?
        </h1>
        <p className="mt-2 text-[16px] sm:text-[17px] leading-[24px] text-[var(--color-text-muted)]">
          Choose an option below. Submitting will send the details you provided to the SafeSignal backend store.
        </p>
      </header>

      {/* Support Options Radiogroup */}
      <div
        role="radiogroup"
        aria-label="How to handle your report"
        className="mt-6 flex flex-col gap-3"
      >
        {STEPS.map((s) => {
          const selected = step === s.id
          return (
            <button
              key={s.id}
              type="button"
              role="radio"
              aria-checked={selected}
              aria-disabled={s.disabled}
              disabled={submitting || s.disabled}
              onClick={() => {
                if (!s.disabled) setStep(s.id)
              }}
              className={`flex min-h-[72px] w-full flex-col items-start justify-center rounded-2xl border-2 p-4 text-left transition-all motion-reduce:transition-none focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)] focus-visible:ring-offset-2 ${
                s.disabled
                  ? 'border-[var(--color-border-subtle)] bg-[var(--color-canvas)] text-[var(--color-text-muted)] opacity-60 cursor-not-allowed'
                  : selected
                  ? 'border-[var(--color-teal)] bg-[var(--color-teal)] text-white shadow-md'
                  : 'border-[var(--color-border-subtle)] bg-[var(--color-surface)] text-[var(--color-text-primary)] hover:border-[var(--color-teal)] hover:bg-[var(--color-teal-subtle)] active:bg-[var(--color-teal-subtle)]'
              }`}
            >
              <div className="flex w-full items-center justify-between gap-2">
                <span className="text-[17px] sm:text-[18px] font-bold leading-6">
                  {s.title}
                </span>
                {selected && (
                  <span
                    aria-hidden="true"
                    className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-white text-[13px] font-black text-[var(--color-teal)]"
                  >
                    ✓
                  </span>
                )}
              </div>

              <span
                className={`mt-1 text-[13px] sm:text-[14px] leading-5 ${
                  selected ? 'text-white/90' : 'text-[var(--color-text-muted)]'
                }`}
              >
                {s.hint}
              </span>

              <span
                className={`mt-2 inline-flex items-center rounded-full px-2.5 py-0.5 text-[11px] font-semibold border ${
                  s.disabled
                    ? 'border-[var(--color-border)] bg-[var(--color-surface)] text-[var(--color-text-muted)]'
                    : selected
                    ? 'border-white/40 bg-white/10 text-white'
                    : 'border-[var(--color-teal)]/30 bg-[var(--color-teal-subtle)] text-[var(--color-teal)]'
                }`}
              >
                {s.statusNote}
              </span>
            </button>
          )
        })}
      </div>

      {/* Immediate Support Resource Numbers (When 'support' chosen) */}
      {step === 'support' && (
        <section aria-labelledby="support-resources-title" className="mt-5">
          <h2 id="support-resources-title" className="text-[16px] font-bold text-[var(--color-ocean)]">
            Emergency & Support Helplines (Kenya)
          </h2>
          <p className="mt-1 text-[13px] leading-5 text-[var(--color-text-muted)]">
            These are established national helplines in Kenya. Tap any button to open your phone dialer:
          </p>

          <ul className="mt-3 flex flex-col gap-2.5">
            {SUPPORT_RESOURCES.map((r) => (
              <li
                key={r.tel}
                className="flex items-center justify-between gap-3 rounded-xl border border-[var(--color-border-subtle)] bg-[var(--color-surface)] p-3.5 shadow-sm"
              >
                <div>
                  <p className="text-[16px] font-bold text-[var(--color-ocean)]">{r.name}</p>
                  <p className="text-[13px] text-[var(--color-text-muted)]">{r.detail}</p>
                </div>
                <a
                  href={`tel:${r.tel}`}
                  aria-label={`Call ${r.name} at ${r.tel}`}
                  className="inline-flex min-h-[44px] min-w-[72px] items-center justify-center rounded-xl bg-[var(--color-teal)] px-4 text-[15px] font-bold text-white shadow-sm transition-colors hover:bg-[var(--color-teal-hover)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)] focus-visible:ring-offset-2"
                >
                  {r.tel}
                </a>
              </li>
            ))}
          </ul>
        </section>
      )}

      {/* Accessible Error Banner */}
      {errorType !== null && (
        <div
          role="alert"
          className="mt-6 flex flex-col gap-1.5 rounded-xl border-2 border-[var(--color-coral)] bg-[var(--color-coral-subtle)] p-4 text-[14px] leading-5 text-[var(--color-coral)]"
        >
          <div className="flex items-center gap-2 font-bold text-[15px]">
            <span aria-hidden="true" className="text-lg">⚠</span>
            <span>
              {errorType === 'timeout'
                ? 'Request timed out after 8 seconds.'
                : 'Could not connect to SafeSignal server.'}
            </span>
          </div>
          <p>
            {errorType === 'timeout'
              ? 'The server took too long to respond. The report may or may not have reached the server. You can safely tap Submit report again: retrying the same submission will not create a duplicate while the server stays running.'
              : 'Please check your connection and tap Submit report to retry.'}
          </p>
        </div>
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
            className="inline-flex min-h-[44px] items-center gap-1.5 px-2 text-[16px] font-bold text-[var(--color-teal)] underline underline-offset-4 hover:text-[var(--color-teal-hover)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)] focus-visible:ring-offset-2 rounded-lg disabled:opacity-50"
          >
            <span aria-hidden="true">←</span>
            <span>Back</span>
          </button>

          <span className="text-[13px] font-medium text-[var(--color-text-muted)]">
            Transmits details upon tapping Submit
          </span>
        </div>
      </div>

      {/* Emergency Disclaimer */}
      <Card className="mt-8 border-[var(--color-border-subtle)] bg-[var(--color-surface)] p-4 text-[13px] leading-5 text-[var(--color-text-muted)]">
        <p>
          <strong className="font-semibold text-[var(--color-text-primary)]">Emergency reminder:</strong> SafeSignal does not dispatch emergency units or automatically alert police. If you are in immediate physical danger, please dial <strong className="font-semibold text-[var(--color-ocean)]">999</strong> or <strong className="font-semibold text-[var(--color-ocean)]">112</strong> directly.
        </p>
      </Card>
    </Shell>
  )
}
