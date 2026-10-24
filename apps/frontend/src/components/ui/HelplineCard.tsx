export interface HelplineCardProps {
  name: string
  detail: string
  tel: string
}

/**
 * HelplineCard — WCAG 2.4.4 (link purpose), 2.5.5 (target size).
 *
 * Renders a single helpline row as a list item: name, descriptive detail,
 * and a `tel:` call-to-action link styled as a button. The call button is a
 * minimum 44 × 44 px touch target.
 */
export function HelplineCard({ name, detail, tel }: HelplineCardProps) {
  return (
    <li className="flex items-center justify-between gap-3 rounded-2xl border border-[var(--color-border-subtle)] bg-[var(--color-surface)] p-3.5 shadow-[var(--shadow-sm)]">
      <div>
        <p className="text-[var(--text-sm)] sm:text-[var(--text-base)] font-bold text-[var(--color-ocean)]">
          {name}
        </p>
        <p className="text-[var(--text-xs)] sm:text-[13px] text-[var(--color-text-muted)]">
          {detail}
        </p>
      </div>
      <a
        href={`tel:${tel}`}
        aria-label={`Call ${name} at ${tel}`}
        className="inline-flex min-h-[44px] min-w-[72px] items-center justify-center rounded-xl bg-[var(--color-teal)] px-4 text-[var(--text-sm)] font-bold text-[var(--color-on-teal)] shadow-sm transition-colors duration-[var(--duration-base)] motion-reduce:transition-none hover:bg-[var(--color-teal-hover)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)] focus-visible:ring-offset-2"
      >
        {tel}
      </a>
    </li>
  )
}