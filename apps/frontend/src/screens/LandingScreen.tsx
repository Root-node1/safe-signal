import Shell from '../components/Shell'
import { Button, Card, GlassSurface } from '../components/ui'
import type { Timing } from '../types'

type Props = { onStart: (timing: Timing) => void }

interface ProcessStep {
  number: string
  title: string
  detail: string
  status: 'Available now' | 'Planned'
  isAvailable: boolean
}

const PROCESS_STEPS: ProcessStep[] = [
  {
    number: '01',
    title: 'Commuters submit reports',
    detail: 'Log incidents quickly with route, matatu SACCO, or location details. Every detail is optional.',
    status: 'Available now',
    isAvailable: true,
  },
  {
    number: '02',
    title: 'Reports are structured & assessed',
    detail: 'Incident details will be standardized to extract key patterns like route corridors and incident types.',
    status: 'Planned',
    isAvailable: false,
  },
  {
    number: '03',
    title: 'Related reports contribute to signals',
    detail: 'Clustering and corroboration help identify broader corridor trends. A single report never verifies an incident alone.',
    status: 'Planned',
    isAvailable: false,
  },
  {
    number: '04',
    title: 'Commuters travel with more awareness',
    detail: 'Public alerts and corridor safety summaries will help passengers choose safer stages, vehicles, and travel times.',
    status: 'Planned',
    isAvailable: false,
  },
]

export default function LandingScreen({ onStart }: Props) {
  return (
    <Shell maxWidth="wide">
      {/* Hero Section */}
      <section
        aria-labelledby="hero-title"
        className="pt-2 md:pt-6 lg:pt-10"
      >
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between lg:gap-12">
          {/* Headline & Value Proposition */}
          <div className="max-w-2xl">
            <div className="inline-flex items-center gap-2 rounded-full border border-[var(--color-teal)]/30 bg-[var(--color-teal-subtle)] px-3.5 py-1 text-[13px] font-semibold text-[var(--color-teal)] tracking-wide">
              <span className="h-2 w-2 rounded-full bg-[var(--color-teal)]" aria-hidden="true" />
              <span>For matatu and boda-boda journeys</span>
            </div>

            <h1
              id="hero-title"
              className="mt-4 text-[var(--text-3xl)] sm:text-[var(--text-4xl)] lg:text-[var(--text-5xl)] font-black leading-[1.15] tracking-tight text-[var(--color-ocean-dark)]"
            >
              Report incidents. <br className="hidden sm:inline" />
              <span className="text-[var(--color-teal)]">Travel with more awareness.</span>
            </h1>

            <p className="mt-4 text-[var(--text-base)] sm:text-[var(--text-lg)] leading-[27px] text-[var(--color-text-muted)] max-w-xl">
              SafeSignal turns commuter experiences into structured safety intelligence, helping Nairobi matatu and boda-boda commuters travel with confidence.
            </p>
          </div>

          {/* Primary Action Card */}
          <div className="mt-8 lg:mt-0 w-full lg:max-w-[380px] shrink-0">
            <Card elevated className="border-2 border-[var(--color-teal)]/40 p-6 shadow-md bg-[var(--color-surface)]">
              <h2 className="text-[var(--text-md)] font-bold text-[var(--color-ocean)]">
                Take Action
              </h2>
              <p className="mt-1 text-[var(--text-sm)] leading-5 text-[var(--color-text-muted)]">
                Fast, discreet reporting. No account required.
              </p>

              <div className="mt-5 flex flex-col gap-3">
                <Button
                  variant="primary"
                  size="lg"
                  fullWidth
                  onClick={() => onStart('after')}
                  aria-label="Report an incident after it happened"
                >
                  Report an incident
                </Button>

                <a
                  href="#safety-alerts"
                  className="inline-flex min-h-[52px] w-full items-center justify-center rounded-2xl border-2 border-[var(--color-teal)] bg-transparent px-5 py-3 text-center text-[var(--text-base)] font-semibold text-[var(--color-teal)] transition-colors hover:bg-[var(--color-teal-subtle)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)] focus-visible:ring-offset-2 motion-reduce:transition-none"
                >
                  Explore safety alerts
                </a>
              </div>

              {/* Immediate Danger / Urgent Entry */}
              <div className="mt-5 border-t border-[var(--color-border-subtle)] pt-4 text-center">
                <p className="text-[var(--text-sm)] leading-5 text-[var(--color-text-muted)]">
                  Need immediate support?{' '}
                  <button
                    type="button"
                    onClick={() => onStart('now')}
                    className="font-semibold text-[var(--color-coral)] underline underline-offset-4 hover:text-[var(--color-coral-hover)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-coral)] rounded-sm"
                  >
                    Report what is happening now
                  </button>
                </p>
              </div>
            </Card>
          </div>
        </div>
      </section>

      {/* How SafeSignal Works */}
      <section
        aria-labelledby="how-it-works-heading"
        className="mt-14 sm:mt-20"
      >
        <div className="max-w-2xl">
          <span className="text-[var(--text-xs)] font-bold uppercase tracking-wider text-[var(--color-teal)]">
            Our Process
          </span>
          <h2
            id="how-it-works-heading"
            className="mt-1 text-[var(--text-2xl)] sm:text-[var(--text-3xl)] font-bold leading-tight text-[var(--color-ocean)]"
          >
            How SafeSignal works
          </h2>
          <p className="mt-2 text-[var(--text-base)] leading-[24px] text-[var(--color-text-muted)]">
            Every report contributes to collective safety intelligence while maintaining commuter privacy.
          </p>
        </div>

        <div className="mt-8 grid grid-cols-1 md:grid-cols-2 gap-4 lg:gap-5">
          {PROCESS_STEPS.map((step) => (
            <Card
              key={step.number}
              as="article"
              className="flex flex-col justify-between p-6 transition-all hover:border-[var(--color-teal)]"
            >
              <div>
                <div className="flex items-center justify-between">
                  <span
                    aria-hidden="true"
                    className="font-mono text-[var(--text-sm)] font-bold text-[var(--color-teal)]"
                  >
                    {step.number}
                  </span>
                  <span
                    className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[var(--text-xs)] font-semibold border ${
                      step.isAvailable
                        ? 'border-[var(--color-teal)]/40 bg-[var(--color-teal-subtle)] text-[var(--color-teal)]'
                        : 'border-[var(--color-border)] bg-[var(--color-canvas)] text-[var(--color-text-muted)]'
                    }`}
                  >
                    <span
                      aria-hidden="true"
                      className="inline-block h-1.5 w-1.5 rounded-full bg-current"
                    />
                    <span>{step.status}</span>
                  </span>
                </div>

                <h3 className="mt-4 text-[var(--text-md)] font-bold leading-6 text-[var(--color-ocean-dark)]">
                  {step.title}
                </h3>
                <p className="mt-2 text-[var(--text-base)] leading-[23px] text-[var(--color-text-muted)]">
                  {step.detail}
                </p>
              </div>
            </Card>
          ))}
        </div>
      </section>

      {/* Safety Alerts Preview (Coming Soon) */}
      <section
        id="safety-alerts"
        aria-labelledby="alerts-preview-title"
        className="mt-14 sm:mt-20 scroll-mt-24"
      >
        <Card className="border-2 border-[var(--color-teal)]/30 bg-[var(--color-surface)] p-6 sm:p-8">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
              <span className="inline-flex items-center gap-1.5 rounded-full border border-[var(--color-amber)] bg-[var(--color-amber-subtle)] px-2.5 py-0.5 text-[var(--text-xs)] font-bold text-[var(--color-amber-dark)]">
                <span aria-hidden="true">⏱</span>
                <span>Coming soon</span>
              </span>
              <h2
                id="alerts-preview-title"
                className="mt-2 text-[var(--text-xl)] sm:text-[var(--text-2xl)] font-bold text-[var(--color-ocean)]"
              >
                Corridor Safety Intelligence & Alerts
              </h2>
              <p className="mt-1 text-[15px] sm:text-[var(--text-base)] leading-[24px] text-[var(--color-text-muted)] max-w-2xl">
                A public live safety alert feed and corridor status map are currently in development.
                No live alerts or incident counts are displayed here yet.
              </p>
            </div>
          </div>

          {/* Planned Features Preview Grid */}
          <div className="mt-6 grid grid-cols-1 sm:grid-cols-3 gap-3 pt-6 border-t border-[var(--color-border-subtle)]">
            <GlassSurface className="rounded-xl p-4 bg-[var(--color-canvas)]/70">
              <p className="font-mono text-[var(--text-xs)] font-semibold text-[var(--color-teal)]">Planned</p>
              <h3 className="mt-1 text-[var(--text-base)] font-bold text-[var(--color-ocean)]">Corridor Insights</h3>
              <p className="mt-1 text-[var(--text-xs)] leading-[19px] text-[var(--color-text-muted)]">
                Aggregated safety patterns along key commuter arteries like Thika Road and Jogoo Road.
              </p>
            </GlassSurface>

            <GlassSurface className="rounded-xl p-4 bg-[var(--color-canvas)]/70">
              <p className="font-mono text-[var(--text-xs)] font-semibold text-[var(--color-teal)]">Planned</p>
              <h3 className="mt-1 text-[var(--text-base)] font-bold text-[var(--color-ocean)]">Corroborated Signals</h3>
              <p className="mt-1 text-[var(--text-xs)] leading-[19px] text-[var(--color-text-muted)]">
                Signals cross-referenced across multiple commuter reports before public alert issuance.
              </p>
            </GlassSurface>

            <GlassSurface className="rounded-xl p-4 bg-[var(--color-canvas)]/70">
              <p className="font-mono text-[var(--text-xs)] font-semibold text-[var(--color-teal)]">Planned</p>
              <h3 className="mt-1 text-[var(--text-base)] font-bold text-[var(--color-ocean)]">Route Safety Intelligence</h3>
              <p className="mt-1 text-[var(--text-xs)] leading-[19px] text-[var(--color-text-muted)]">
                Route and stage safety information based on reports. Not available yet; the assistant cannot tell you whether a route is safe.
              </p>
            </GlassSurface>
          </div>
        </Card>
      </section>

      {/* Trust & Privacy Notice */}
      <section
        aria-labelledby="privacy-heading"
        className="mt-14 sm:mt-18"
      >
        <Card className="bg-[var(--color-surface)] border-[var(--color-border-subtle)] p-6 sm:p-7">
          <div className="flex items-start gap-3">
            <div
              aria-hidden="true"
              className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-[var(--color-teal)] text-[var(--color-on-teal)] text-[var(--text-xs)] font-bold"
            >
              🛡
            </div>
            <div>
              <h2
                id="privacy-heading"
                className="text-[var(--text-md)] font-bold leading-6 text-[var(--color-ocean)]"
              >
                Commuter Privacy & Report Integrity
              </h2>
              <p className="mt-2 text-[var(--text-base)] leading-[23px] text-[var(--color-text-muted)]">
                No account is required to start a report. Location input is optional.
                The reporting flow does not silently collect background GPS or phone numbers;
                submitted details are sent to the SafeSignal server when you continue. In this prototype, reports are stored temporarily and may be cleared when the server restarts.
                The assistant (button on this page) offers general commuter guidance and explains how SafeSignal works. Do not include personal names, sensitive contact data, or other identifying information in report descriptions.
              </p>
              <p className="mt-3 text-[var(--text-sm)] leading-5 text-[var(--color-text-muted)]">
                <strong className="text-[var(--color-ocean)] font-semibold">Important safety note:</strong> SafeSignal is a safety intelligence system, not an emergency response service.
                If you are in immediate physical danger, contact emergency services directly at <strong className="font-semibold text-[var(--color-ocean)]">999</strong> or <strong className="font-semibold text-[var(--color-ocean)]">112</strong>.
              </p>
            </div>
          </div>
        </Card>
      </section>

      {/* Footer / Quick Exit Reassurance */}
      <footer className="mt-12 text-center text-[var(--text-xs)] leading-5 text-[var(--color-text-muted)]">
        <p>
          SafeSignal Kenya &middot; Designed for commuter safety on matatu & boda-boda routes.
        </p>
        <p className="mt-1">
          Need to close quickly? Press <kbd className="rounded border border-[var(--color-border)] bg-[var(--color-surface)] px-1.5 py-0.5 font-mono text-[11px] font-semibold text-[var(--color-ocean)]">Esc</kbd> or tap the Exit button at any time.
        </p>
      </footer>
    </Shell>
  )
}
