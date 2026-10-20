interface Props {
  onClick: () => void
}

export function AssistantLauncher({ onClick }: Props) {
  return (
    <button
      id="assistant-launcher-btn"
      type="button"
      onClick={onClick}
      aria-label="Open SafeSignal Guidance Assistant"
      className="fixed bottom-6 right-6 z-30 flex items-center gap-2 rounded-full border-2 border-[var(--color-teal)]/40 bg-[var(--color-surface)] px-4 py-2.5 shadow-lg text-[var(--color-ocean)] transition-all hover:border-[var(--color-teal)] hover:shadow-xl focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)] focus-visible:ring-offset-2 motion-reduce:transition-none"
    >
      <span
        aria-hidden="true"
        className="flex h-6 w-6 items-center justify-center rounded-full bg-[var(--color-teal)] text-[11px] font-black text-white"
      >
        AI
      </span>
      <span className="text-[14px] font-bold tracking-tight">Ask Assistant</span>
    </button>
  )
}
