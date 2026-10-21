import { beforeEach, describe, expect, it, vi } from 'vitest'

import { applyTheme, getInitialTheme, toggleTheme } from './theme'

describe('the theme preference key', () => {
  beforeEach(() => {
    localStorage.clear()
    document.documentElement.removeAttribute('data-theme')
    vi.unstubAllGlobals()
  })

  it('remains safesignal-theme, and is the only browser storage key', () => {
    applyTheme('dark', true)
    expect(localStorage.getItem('safesignal-theme')).toBe('dark')
    expect(localStorage.length).toBe(1)
  })

  it('reads the stored preference back', () => {
    localStorage.setItem('safesignal-theme', 'light')
    expect(getInitialTheme()).toBe('light')
  })

  it('falls back to the OS scheme without writing a preference', () => {
    vi.stubGlobal(
      'matchMedia',
      vi.fn().mockReturnValue({ matches: true }),
    )
    expect(getInitialTheme()).toBe('dark')
    expect(localStorage.length).toBe(0)
  })

  it('persists the toggled theme under the same key', () => {
    expect(toggleTheme('light')).toBe('dark')
    expect(localStorage.getItem('safesignal-theme')).toBe('dark')
    expect(toggleTheme('dark')).toBe('light')
    expect(localStorage.getItem('safesignal-theme')).toBe('light')
  })
})
