import type { ReactNode } from 'react'
import SafeHeader from './SafeHeader'
import { shellMaxWidthClass, type ShellMaxWidth } from '../lib/layout'

type ShellProps = {
  children: ReactNode
  maxWidth?: ShellMaxWidth
}

// Shared page frame: accessible skip link + header + responsive layout column.
// The header receives the same maxWidth so its edge always tracks the content
// edge (FR-11.4). Default maxWidth is optimized for focused reporting forms
// (up to 640px). 'wide' lets rich content (landing, map, dashboard) breathe on
// tablets & desktop (up to 1040px).
export default function Shell({ children, maxWidth = 'default' }: ShellProps) {
  const containerWidthClass = shellMaxWidthClass(maxWidth)

  return (
    <div className="flex min-h-screen flex-col bg-[var(--color-canvas)] font-sans text-[var(--color-text-primary)]">
      <a href="#main-content" className="skip-link">
        Skip to main content
      </a>
      <SafeHeader maxWidth={maxWidth} />
      <main
        id="main-content"
        tabIndex={-1}
        className={`mx-auto flex w-full flex-1 flex-col px-5 pb-12 pt-6 outline-none motion-reduce:animate-none screen-enter ${containerWidthClass}`}
      >
        {children}
      </main>
    </div>
  )
}
