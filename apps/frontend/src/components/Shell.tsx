import type { ReactNode } from 'react'
import SafeHeader from './SafeHeader'

type ShellProps = { children: ReactNode }

// Shared page frame: header + width-responsive content column.
export default function Shell({ children }: ShellProps) {
  return (
    <div className="flex min-h-screen flex-col bg-[#F7F5F2] font-sans text-[#1B1F23]">
      <SafeHeader />
      <main className="mx-auto flex w-full max-w-[390px] flex-1 flex-col px-5 pb-6 pt-6 md:max-w-[560px] lg:max-w-[640px]">
        {children}
      </main>
    </div>
  )
}
