import type { ReactNode } from 'react'
import SafeHeader from './SafeHeader'

type ShellProps = {
  children: ReactNode
  maxWidth?: 'default' | 'wide'
}

// Shared page frame: accessible skip link + header + responsive layout column.
// Default maxWidth is optimized for focused reporting forms (up to 640px).
// 'wide' allows rich content (landing, map, dashboard) to breathe comfortably on tablets & desktop (up to 1024px).
export default function Shell({ children, maxWidth = 'default' }: ShellProps) {
  const containerWidthClass =
    maxWidth === 'wide'
      ? 'max-w-[390px] md:max-w-[720px] lg:max-w-[960px] xl:max-w-[1040px]'
      : 'max-w-[390px] md:max-w-[560px] lg:max-w-[640px]'

  return (
    <div className="flex min-h-screen flex-col bg-[var(--color-canvas)] font-sans text-[var(--color-text-primary)]">
      <a href="#main-content" className="skip-link">
        Skip to main content
      </a>
      <SafeHeader />
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
