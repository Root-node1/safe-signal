// Registers the jest-dom matchers with Vitest (for example `toBeInTheDocument`).
// Test-only: this file is never part of the production bundle.
import '@testing-library/jest-dom/vitest'

import { cleanup } from '@testing-library/react'
import { afterEach } from 'vitest'

// Unmount anything a test rendered. The automatic cleanup needs a global
// `afterEach`, which this project does not enable, so it is registered here.
afterEach(() => cleanup())

// jsdom implements neither matchMedia nor scrollTo. The app reads matchMedia for
// the colour scheme and the reduced-motion preference, and calls scrollTo when
// the screen changes. These stubs are environment-only; no application code changes.
if (!window.matchMedia) {
  window.matchMedia = ((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => false,
  })) as unknown as typeof window.matchMedia
}

window.scrollTo = () => {}
