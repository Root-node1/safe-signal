import { type KeyboardEventHandler, type ReactNode } from 'react'

export interface SelectionTileProps {
  id: string
  label: string
  description: string
  icon?: ReactNode
  badge?: string
  badgeVariant?: 'available' | 'unavailable' | 'selected'
  selected: boolean
  disabled?: boolean
  tabIndex?: number
  onClick: () => void
  onKeyDown?: KeyboardEventHandler<HTMLButtonElement>
}

/**
 * SelectionTile — WCAG 1.4.3 (contrast), 2.1.1 (keyboard), 2.4.7 (focus visible),
 * 4.1.2 (name, role, value).
 *
 * A radio-style selection tile. Renders as a `<button role="radio">` with
 * `aria-checked`, `aria-disabled`, a decorative icon container, label,
 * description, optional badge, and a selected-state check indicator. The
 * caller supplies arrow-key navigation via `onKeyDown`.
 */
export function SelectionTile({
  id,
  label,
  description,
  icon,
  badge,
  badgeVariant = 'available',
  selected,
  disabled = false,
  tabIndex,
  onClick,
  onKeyDown,
}: SelectionTileProps) {
  const badgeStyles: Record<NonNullable<SelectionTileProps['badgeVariant']>, string> = {
    available:
      'border-[var(--color-teal)]/30 bg-[var(--color-teal-subtle)] text-[var(--color-teal)]',
    unavailable:
      'border-[var(--color-border)] bg-[var(--color-surface)] text-[var(--color-text-muted)]',
    selected:
      'border-[var(--color-ocean)] bg-[var(--color-ocean)] text-[var(--color-on-teal)]',
  }

  return (
    <li>
      <button
        id={id}
        type="button"
        role="radio"
        aria-checked={selected}
        aria-disabled={disabled}
        tabIndex={tabIndex}
        disabled={disabled}
        onClick={onClick}
        onKeyDown={onKeyDown}
        className={`group flex w-full items-start gap-3 rounded-2xl border p-3.5 text-left transition-[background-color,border-color,box-shadow] duration-[var(--duration-base)] motion-reduce:transition-none focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)] focus-visible:ring-offset-2 focus-visible:ring-offset-[var(--color-canvas)] disabled:cursor-not-allowed ${
          selected
            ? 'border-[var(--color-teal)] bg-[var(--color-teal-subtle)] shadow-[var(--shadow-md)]'
            : disabled
              ? 'border-[var(--color-border-subtle)] bg-[var(--color-canvas)] text-[var(--color-text-muted)] opacity-55'
              : 'border-[var(--color-border-subtle)] bg-[var(--color-surface)] shadow-[var(--shadow-sm)] hover:border-[var(--color-teal)] hover:bg-[var(--color-teal-subtle)]'
        }`}
      >
        {icon && (
          <span
            aria-hidden="true"
            className={`mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-xl transition-colors duration-[var(--duration-base)] motion-reduce:transition-none ${
              selected
                ? 'bg-[var(--color-teal)] text-[var(--color-on-teal)]'
                : disabled
                  ? 'bg-[var(--color-border-subtle)] text-[var(--color-text-muted)]'
                  : 'bg-[var(--color-teal-subtle)] text-[var(--color-teal)]'
            }`}
          >
            {icon}
          </span>
        )}

        <span className="min-w-0 flex-1">
          <span className="flex items-center justify-between gap-3">
            <span
              className={`text-[var(--text-sm)] sm:text-[var(--text-base)] font-semibold leading-6 tracking-[-0.01em] ${
                selected ? 'text-[var(--color-ocean-dark)]' : 'text-[var(--color-text-primary)]'
              }`}
            >
              {label}
            </span>
            {selected && (
              <span
                aria-hidden="true"
                className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-[var(--color-teal)] text-[var(--color-on-teal)]"
              >
                <svg
                  className="h-3 w-3"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={3.5}
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="m4.5 12.5 5 5 10-11" />
                </svg>
              </span>
            )}
          </span>
          <span className="mt-0.5 block text-[var(--text-xs)] sm:text-[13px] leading-5 text-[var(--color-text-muted)]">
            {description}
          </span>
        </span>

        {badge && (
          <span
            aria-hidden="true"
            className={`mt-2 inline-flex items-center rounded-full px-2.5 py-0.5 text-[11px] font-semibold border ${badgeStyles[badgeVariant]}`}
          >
            {badge}
          </span>
        )}
      </button>
    </li>
  )
}