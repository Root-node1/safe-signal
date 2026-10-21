import { type FC } from 'react'
import type { Theme } from '../../lib/theme'

export interface ThemeToggleProps {
  theme: Theme
  onToggle: () => void
}

/**
 * ThemeToggle — WCAG 2.1.1 (keyboard), 2.4.7 (focus visible), 2.5.5 (target size).
 *
 * A 44 × 44 px toggle button that switches between light and dark themes.
 * Renders a sun icon in light mode and a moon icon in dark mode. Both icons
 * are decorative (`aria-hidden`). The button exposes its state via
 * `aria-pressed` and a descriptive `aria-label`.
 */
export const ThemeToggle: FC<ThemeToggleProps> = ({ theme, onToggle }) => {
  const isDark = theme === 'dark'

  return (
    <button
      type="button"
      aria-label={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
      aria-pressed={isDark}
      onClick={onToggle}
      className="inline-flex min-h-[44px] min-w-[44px] items-center justify-center rounded-lg text-[var(--color-text-primary)] transition-colors duration-[var(--duration-base)] motion-reduce:transition-none hover:bg-[var(--color-teal-subtle)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)] focus-visible:ring-offset-2 focus-visible:ring-offset-[var(--color-canvas)]"
    >
      <span aria-hidden="true" className="flex h-5 w-5">
        {isDark ? (
          <svg
            className="h-5 w-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
          </svg>
        ) : (
          <svg
            className="h-5 w-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <circle cx="12" cy="12" r="4" />
            <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41" />
          </svg>
        )}
      </span>
    </button>
  )
}