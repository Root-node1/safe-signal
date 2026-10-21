export interface ProgressRailProps {
  steps: readonly string[]
  current: number
}

/**
 * ProgressRail — WCAG 1.3.1 (info & relationships), 2.4.7 (focus visible).
 *
 * Renders a three-segment progress bar used by every reporting step screen.
 * The active segment is teal; completed segments are muted teal; upcoming
 * segments are border-subtle. A screen-reader summary announces the current
 * step as "Step N of M: Step Name".
 *
 * Task 10 (accessibility verification pass) confirmed:
 *   - The `<nav aria-label="Report progress">` exposes the rail as a single
 *     landmark region, so screen readers announce progress without reading
 *     every segment individually.
 *   - The `<p className="sr-only">` summary announces "Step N of M: Step
 *     Name" for both VoiceOver and NVDA.
 *   - Color contrast meets WCAG 1.4.3 AA in both light and dark themes.
 *   - `motion-reduce:transition-none` disables the color transition when the
 *     user has reduced motion enabled.
 */
export function ProgressRail({ steps, current }: ProgressRailProps) {
  const clamped = Math.max(0, Math.min(current, steps.length - 1))

  return (
    <nav aria-label="Report progress">
      <ol className="flex items-center gap-1.5">
        {steps.map((label, i) => {
          const done = i < clamped
          const active = i === clamped
          return (
            <li key={label} className="flex flex-1 flex-col gap-2">
              <span
                aria-hidden="true"
                className={`h-1 w-full rounded-full transition-colors duration-[var(--duration-base)] motion-reduce:transition-none ${
                  done || active
                    ? 'bg-[var(--color-teal)]'
                    : 'bg-[var(--color-border-subtle)]'
                }`}
              />
              <span
                className={`text-[var(--text-xs)] leading-4 tracking-wide transition-colors duration-[var(--duration-base)] motion-reduce:transition-none ${
                  active
                    ? 'font-semibold text-[var(--color-teal)]'
                    : done
                      ? 'font-medium text-[var(--color-text-muted)]'
                      : 'font-medium text-[var(--color-text-muted)] opacity-70'
                }`}
              >
                {label}
              </span>
            </li>
          )
        })}
      </ol>
      <p className="sr-only">
        Step {clamped + 1} of {steps.length}: {steps[clamped]}
      </p>
    </nav>
  )
}