import { useEffect, useState } from 'react'
import { quickExit } from '../lib/quickExit'
import { applyTheme, getInitialTheme, toggleTheme, type Theme } from '../lib/theme'
import { PROTOTYPE } from '../lib/prototype'
import { shellMaxWidthClass, type ShellMaxWidth } from '../lib/layout'
import { GlassSurface, ThemeToggle } from './ui'

type SafeHeaderProps = {
  /** Tracks the Shell content ladder so the header edge aligns with the content edge (FR-11.4). */
  maxWidth?: ShellMaxWidth
}

/**
 * SafeHeader — WCAG 2.1.1 (keyboard), 2.4.7 (focus visible), 2.5.5 (target size).
 *
 * Sticky top header with the SafeSignal wordmark, prototype badge, theme
 * toggle, and a prominent Quick Exit button. The Escape key handler is
 * unaffected by theme changes.
 */
export default function SafeHeader({ maxWidth = 'default' }: SafeHeaderProps) {
  const [theme, setTheme] = useState<Theme>(getInitialTheme)

  useEffect(() => {
    // Apply the resolved theme on mount without writing to localStorage.
    applyTheme(theme, false)
  }, [theme])

  const handleToggle = () => {
    setTheme((prev) => toggleTheme(prev))
  }

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') quickExit()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  return (
    <GlassSurface as="header" borderBottom className="sticky top-0 z-30">
      <div className={`mx-auto flex w-full items-center justify-between px-5 py-3 ${shellMaxWidthClass(maxWidth)}`}>
        <span className="flex items-center gap-2 text-[16px] font-bold leading-5 tracking-tight text-[var(--color-text-primary)]">
          <span
            aria-hidden="true"
            className="flex h-6 w-6 items-center justify-center rounded-lg bg-[var(--color-teal)] text-[12px] font-black text-[var(--color-on-teal)]"
          >
            S
          </span>
          <span>SafeSignal</span>
          {PROTOTYPE && (
            <span className="rounded-full border border-[var(--color-border)] bg-[var(--color-surface)] px-2 py-0.5 text-[11px] font-medium text-[var(--color-text-muted)]">
              Prototype
            </span>
          )}
        </span>

        <div className="flex items-center gap-2">
          <ThemeToggle theme={theme} onToggle={handleToggle} />
          <button
            type="button"
            onClick={quickExit}
            aria-label="Quick exit to a neutral search page (Shortcut: Escape)"
            className="min-h-[44px] min-w-[44px] rounded-full bg-[var(--color-teal)] px-4 py-2 text-[15px] font-semibold leading-5 text-[var(--color-on-teal)] shadow-sm transition-colors hover:bg-[var(--color-teal-hover)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)] focus-visible:ring-offset-2 active:brightness-90 motion-reduce:transition-none"
          >
            Exit
          </button>
        </div>
      </div>
    </GlassSurface>
  )
}