import { useEffect } from 'react'
import { quickExit } from '../lib/quickExit'
import { PROTOTYPE } from '../lib/prototype'
import { GlassSurface } from './ui'

export default function SafeHeader() {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') quickExit()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  return (
    <GlassSurface as="header" borderBottom className="sticky top-0 z-30">
      <div className="mx-auto flex w-full max-w-[390px] items-center justify-between px-5 py-3 md:max-w-[560px] lg:max-w-[640px]">
        <span className="flex items-center gap-2 text-[16px] font-bold leading-5 tracking-tight text-[var(--color-text-primary)]">
          <span
            aria-hidden="true"
            className="flex h-6 w-6 items-center justify-center rounded-lg bg-[var(--color-teal)] text-[12px] font-black text-white"
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
        <button
          type="button"
          onClick={quickExit}
          aria-label="Quick exit to a neutral search page (Shortcut: Escape)"
          className="min-h-[44px] min-w-[44px] rounded-full bg-[var(--color-ocean-dark)] px-4 py-2 text-[15px] font-semibold leading-5 text-white shadow-sm transition-colors hover:bg-[var(--color-ocean)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)] focus-visible:ring-offset-2 active:brightness-90 motion-reduce:transition-none"
        >
          Exit
        </button>
      </div>
    </GlassSurface>
  )
}
