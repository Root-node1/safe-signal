import { useState } from 'react'
import Shell from '../components/Shell'
import { Button, Card } from '../components/ui'
import { SUPPORT_RESOURCES } from '../lib/support'
import type { NextChoice } from '../types'

type Props = {
  choice: NextChoice
  code: string
  onRestart: () => void
}

type CopyStatus = 'idle' | 'done' | 'failed'

export default function ConfirmationScreen({ choice, code, onRestart }: Props) {
  const [copyStatus, setCopyStatus] = useState<CopyStatus>('idle')

  const copyCode = async () => {
    try {
      if ('clipboard' in navigator && navigator.clipboard.writeText) {
        await navigator.clipboard.writeText(code)
        setCopyStatus('done')
      } else {
        setCopyStatus('failed')
      }
    } catch {
      setCopyStatus('failed')
    }
  }

  return (
    <Shell>
      {/* Confirmation Heading & Receipt Banner */}
      <header className="pt-2">
        <div className="inline-flex items-center gap-2 rounded-full border border-[var(--color-teal)]/30 bg-[var(--color-teal-subtle)] px-3.5 py-1 text-[13px] font-semibold text-[var(--color-teal)] tracking-wide">
          <span className="flex h-4 w-4 items-center justify-center rounded-full bg-[var(--color-teal)] text-[11px] text-white font-bold" aria-hidden="true">
            ✓
          </span>
          <span>Report received</span>
        </div>

        <h1 className="mt-3 text-[28px] sm:text-[34px] font-black leading-tight tracking-tight text-[var(--color-ocean-dark)]">
          Report Submitted
        </h1>
        <p className="mt-2 text-[16px] sm:text-[17px] leading-[24px] text-[var(--color-text-muted)]">
          The SafeSignal server accepted your report. This is a prototype, so reports are stored temporarily and may be cleared.
        </p>
      </header>

      {/* Reference Code Card */}
      {code ? (
        <Card elevated className="mt-6 border-2 border-[var(--color-teal)]/40 bg-[var(--color-surface)] p-6 shadow-md">
          <div className="flex items-center justify-between">
            <span className="text-[13px] font-bold uppercase tracking-wider text-[var(--color-text-muted)]">
              Reference Code
            </span>
            <span className="rounded-full border border-[var(--color-border)] bg-[var(--color-canvas)] px-2 py-0.5 font-mono text-[11px] font-semibold text-[var(--color-text-muted)]">
              Backend issued
            </span>
          </div>

          <p
            aria-label={`Your reference code is ${code}`}
            className="mt-3 font-mono text-[28px] sm:text-[32px] font-black tracking-widest text-[var(--color-ocean-dark)] select-all"
          >
            {code}
          </p>

          <div className="mt-4 flex flex-col sm:flex-row sm:items-center gap-3">
            <Button
              type="button"
              variant="secondary"
              size="sm"
              onClick={copyCode}
              aria-label="Copy reference code to clipboard"
            >
              {copyStatus === 'done' ? '✓ Copied to clipboard' : 'Copy code'}
            </Button>

            {/* Accessible screen-reader announcement */}
            <span role="status" aria-live="polite" className="sr-only">
              {copyStatus === 'done' && 'Reference code copied to clipboard.'}
              {copyStatus === 'failed' && 'Could not automatically copy code to clipboard.'}
            </span>

            {copyStatus === 'failed' && (
              <p role="status" className="text-[13px] leading-5 text-[var(--color-text-muted)]">
                Copy shortcut unavailable. You can highlight and copy the code above, or write it down.
              </p>
            )}
          </div>

          <p className="mt-4 border-t border-[var(--color-border-subtle)] pt-3 text-[12px] leading-5 text-[var(--color-text-muted)]">
            You can note this code privately, but it cannot be looked up yet, and because storage is temporary it may stop being valid.
          </p>
        </Card>
      ) : null}

      {/* Honest What Happened / What Did NOT Happen Notice */}
      <section aria-labelledby="status-breakdown-heading" className="mt-6">
        <Card className="border-[var(--color-border-subtle)] bg-[var(--color-surface)] p-5">
          <h2 id="status-breakdown-heading" className="text-[16px] font-bold text-[var(--color-ocean)]">
            Submission Status
          </h2>
          <ul className="mt-3 flex flex-col gap-2.5 text-[14px] leading-5 text-[var(--color-text-muted)]">
            <li className="flex items-start gap-2">
              <span className="font-bold text-[var(--color-teal)]" aria-hidden="true">✓</span>
              <span>Your details were received by the SafeSignal server. Storage is temporary in this prototype.</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="font-bold text-[var(--color-text-muted)]" aria-hidden="true">•</span>
              <span>Nobody has been contacted automatically. No SMS or calls were dispatched.</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="font-bold text-[var(--color-text-muted)]" aria-hidden="true">•</span>
              <span>This report has not been verified, reviewed, dispatched, or forwarded. SafeSignal is not an emergency response service.</span>
            </li>
          </ul>
        </Card>
      </section>

      {/* Support Numbers Section (If selected or needed) */}
      {choice.step === 'support' && (
        <section aria-labelledby="confirmed-helplines-title" className="mt-6">
          <h2 id="confirmed-helplines-title" className="text-[17px] font-bold text-[var(--color-ocean)]">
            Emergency & Support Contacts (Kenya)
          </h2>
          <p className="mt-1 text-[13px] leading-5 text-[var(--color-text-muted)]">
            If you need immediate assistance, call these official national numbers:
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

      {/* Completion & Navigation Actions */}
      <div className="mt-8 flex flex-col gap-3">
        <Button
          type="button"
          variant="primary"
          size="lg"
          fullWidth
          onClick={onRestart}
        >
          Done
        </Button>

        <Button
          type="button"
          variant="secondary"
          size="md"
          fullWidth
          onClick={onRestart}
        >
          Start another report
        </Button>
      </div>

      {/* Emergency Helpline Reassurance */}
      <footer className="mt-8 text-center text-[13px] leading-5 text-[var(--color-text-muted)]">
        <p>
          Need to exit now? Press <kbd className="rounded border border-[var(--color-border)] bg-[var(--color-surface)] px-1.5 py-0.5 font-mono text-[11px] font-semibold text-[var(--color-ocean)]">Esc</kbd> or tap the Exit button at the top of the page.
        </p>
      </footer>
    </Shell>
  )
}
