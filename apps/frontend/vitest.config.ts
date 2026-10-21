import react from '@vitejs/plugin-react'
import { defineConfig } from 'vitest/config'

// Test-only configuration. The production build keeps using vite.config.ts, so
// nothing here can reach the shipped bundle.
export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
    include: ['src/**/*.test.ts', 'src/**/*.test.tsx'],
  },
})
