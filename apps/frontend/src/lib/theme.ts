export type Theme = 'light' | 'dark'

const KEY = 'safesignal-theme'

/**
 * getInitialTheme — resolves the theme to apply on first load.
 *
 * Priority: explicit user preference in `localStorage` → OS colour scheme.
 * Never writes to storage; this is read-only resolution.
 */
export function getInitialTheme(): Theme {
  if (typeof window === 'undefined') return 'light'
  const stored = localStorage.getItem(KEY)
  if (stored === 'dark' || stored === 'light') return stored
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
}

/**
 * applyTheme — sets the `data-theme` attribute on the document root.
 *
 * When `persist` is false (initial mount), the attribute is applied without
 * touching `localStorage`, so a missing preference entry is never created.
 * When `persist` is true (explicit user toggle), the preference is written.
 */
export function applyTheme(t: Theme, persist = false): void {
  if (typeof document === 'undefined') return
  document.documentElement.dataset.theme = t === 'dark' ? 'dark' : ''
  if (persist) localStorage.setItem(KEY, t)
}

/**
 * toggleTheme — flips the theme and persists the new preference.
 * Returns the new theme so callers can update React state in one step.
 */
export function toggleTheme(current: Theme): Theme {
  const next: Theme = current === 'dark' ? 'light' : 'dark'
  applyTheme(next, true)
  return next
}