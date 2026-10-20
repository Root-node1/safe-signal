import { useEffect, useRef, useState, type FormEvent } from 'react'
import { GlassSurface } from '../components/ui'
import { PREDEFINED_GUIDANCE, type PredefinedGuidance } from './guidance'
import type { AssistantMessage } from './contract'
import { askAssistant } from '../lib/api'
import { quickExit } from '../lib/quickExit'

interface Props {
  isOpen: boolean
  onClose: () => void
  returnFocusId?: string
}

const INITIAL_WELCOME: AssistantMessage = {
  id: 'welcome',
  role: 'assistant',
  content:
    'Hello. I am the SafeSignal Guidance Assistant. I give general commuter safety guidance and explain how SafeSignal works. I cannot see reports, check whether a route or vehicle is safe, or contact emergency services. Please do not share names, phone numbers or plates.',
  timestamp: 0,
}

export function AssistantModal({ isOpen, onClose, returnFocusId }: Props) {
  const [messages, setMessages] = useState<AssistantMessage[]>([INITIAL_WELCOME])
  const [customInput, setCustomInput] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const requestRef = useRef(0)
  const wasOpenRef = useRef(false)
  const counterRef = useRef(1)
  const dialogRef = useRef<HTMLDivElement>(null)
  const closeButtonRef = useRef<HTMLButtonElement>(null)
  const messagesEndRef = useRef<HTMLDivElement>(null)

  // 1. Initial focus placement & Focus restoration upon close
  useEffect(() => {
    if (isOpen) {
      wasOpenRef.current = true
      // Small timeout ensures the DOM node is rendered and ready for focus
      const timer = setTimeout(() => {
        closeButtonRef.current?.focus()
      }, 50)
      return () => clearTimeout(timer)
    } else if (wasOpenRef.current) {
      // Only restore focus after a real open -> close transition, never on first load.
      wasOpenRef.current = false
      if (returnFocusId) document.getElementById(returnFocusId)?.focus()
    }
  }, [isOpen, returnFocusId])

  // 2. Background scroll lock & restoration
  useEffect(() => {
    if (!isOpen) return
    const originalOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      document.body.style.overflow = originalOverflow
    }
  }, [isOpen])

  // 3. Scroll to bottom of message list on append
  useEffect(() => {
    if (isOpen) {
      const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches
      messagesEndRef.current?.scrollIntoView({ behavior: reduce ? 'auto' : 'smooth' })
    }
  }, [messages, isOpen])

  // 4. Focus containment (Tab Trap) inside modal without intercepting Escape (Escape triggers Quick Exit globally)
  useEffect(() => {
    if (!isOpen) return

    const handleKeyDown = (e: KeyboardEvent) => {
      // DO NOT intercept Escape. Let Escape bubble up to document/window so SafeHeader's quickExit() triggers!
      if (e.key === 'Tab' && dialogRef.current) {
        const focusableElements = dialogRef.current.querySelectorAll<HTMLElement>(
          'button:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])',
        )
        if (focusableElements.length === 0) return

        const firstElement = focusableElements[0]
        const lastElement = focusableElements[focusableElements.length - 1]

        if (e.shiftKey) {
          if (document.activeElement === firstElement) {
            e.preventDefault()
            lastElement.focus()
          }
        } else {
          if (document.activeElement === lastElement) {
            e.preventDefault()
            firstElement.focus()
          }
        }
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [isOpen])

  if (!isOpen) return null

  const handleSelectGuidance = (item: PredefinedGuidance) => {
    const idNum = counterRef.current++
    const userMsg: AssistantMessage = {
      id: `user-${idNum}`,
      role: 'user',
      content: item.query,
      timestamp: idNum,
    }
    const assistantMsg: AssistantMessage = {
      id: `asst-${idNum}`,
      role: 'assistant',
      content: item.answer,
      timestamp: idNum + 1,
      isEmergencyNotice: item.category === 'emergency',
      source: 'predefined',
    }
    setMessages((prev) => [...prev, userMsg, assistantMsg])
  }

  const handleCustomSubmit = async (e: FormEvent) => {
    e.preventDefault()
    const text = customInput.trim()
    if (!text || loading) return

    const idNum = counterRef.current++
    const userMsg: AssistantMessage = {
      id: `user-${idNum}`,
      role: 'user',
      content: text,
      timestamp: idNum,
    }
    const history = messages
      .filter((m) => m.id !== 'welcome' && m.source !== 'fallback')
      .slice(-6)
      .map((m) => ({ role: m.role as 'user' | 'assistant', content: m.content }))
    setMessages((prev) => [...prev, userMsg])
    setCustomInput('')
    setError('')
    setLoading(true)
    const ticket = ++requestRef.current
    try {
      const r = await askAssistant(text, history)
      if (ticket !== requestRef.current) return
      setMessages((prev) => [
        ...prev,
        {
          id: `asst-${idNum}`,
          role: 'assistant',
          content: r.reply,
          timestamp: idNum + 1,
          isEmergencyNotice: r.source === 'emergency',
          source: 'ai',
        },
      ])
    } catch {
      if (ticket !== requestRef.current) return
      setError('The AI assistant is unavailable right now. Showing built-in guidance instead.')
      setMessages((prev) => [
        ...prev,
        {
          id: `asst-${idNum}`,
          role: 'assistant',
          content:
            'I could not reach the AI assistant. Tap one of the guidance topics below for built-in answers. If you are in immediate danger, call 999 or 112.',
          timestamp: idNum + 1,
          source: 'fallback',
        },
      ])
    } finally {
      if (ticket === requestRef.current) setLoading(false)
    }
  }

  const handleReset = () => {
    requestRef.current++
    setMessages([INITIAL_WELCOME])
    setError('')
    setLoading(false)
  }

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="assistant-title"
      className="fixed inset-0 z-40 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-[var(--color-ocean-dark)]/50 backdrop-blur-xs transition-opacity motion-reduce:transition-none"
    >
      <div
        ref={dialogRef}
        className="flex h-[90vh] supports-[height:90dvh]:h-[90dvh] sm:h-[620px] sm:supports-[height:90dvh]:h-[620px] w-full max-w-[500px] flex-col rounded-t-3xl sm:rounded-3xl border border-[var(--color-border-subtle)] bg-[var(--color-canvas)] shadow-2xl overflow-hidden"
      >
        {/* Header with Glass Surface */}
        <GlassSurface borderBottom className="px-5 py-3.5 flex items-center justify-between shrink-0">
          <div className="flex min-w-0 items-center gap-2.5">
            <span
              aria-hidden="true"
              className="flex h-7 w-7 items-center justify-center rounded-xl bg-[var(--color-teal)] text-white text-[13px] font-bold"
            >
              AI
            </span>
            <div>
              <h2 id="assistant-title" className="text-[16px] font-bold leading-5 text-[var(--color-ocean)]">
                SafeSignal Assistant
              </h2>
              <span className="text-[11px] font-medium text-[var(--color-text-muted)]">
                AI answers may be wrong
              </span>
            </div>
          </div>

          <div className="flex shrink-0 items-center gap-1.5">
            <button
              type="button"
              onClick={handleReset}
              className="min-h-[44px] px-2.5 text-[12px] font-semibold text-[var(--color-text-muted)] hover:text-[var(--color-ocean)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-focus)] rounded-lg"
              title="Reset conversation"
            >
              Reset
            </button>
            <button
              type="button"
              onClick={quickExit}
              aria-label="Quick exit to a neutral search page (Shortcut: Escape)"
              className="min-h-[44px] min-w-[44px] rounded-full bg-[var(--color-ocean-dark)] px-3.5 text-[14px] font-semibold text-white focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)]"
            >
              Exit
            </button>
            <button
              ref={closeButtonRef}
              type="button"
              onClick={onClose}
              aria-label="Close assistant"
              className="flex h-11 w-11 items-center justify-center rounded-full bg-[var(--color-surface)] border border-[var(--color-border)] text-[var(--color-ocean)] hover:bg-[var(--color-canvas)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)]"
            >
              ✕
            </button>
          </div>
        </GlassSurface>

        {/* Emergency Notice Banner */}
        <div className="bg-[var(--color-coral-subtle)] px-4 py-2 text-[12px] leading-4 text-[var(--color-coral)] border-b border-[var(--color-coral)]/20 font-medium text-center">
          Not an emergency dispatch service. In immediate danger, call <strong className="font-bold">999</strong> or <strong className="font-bold">112</strong>. Press <kbd className="rounded border border-[var(--color-coral)]/40 px-1 py-0.5 font-mono text-[11px]">Esc</kbd> anytime for Quick Exit.
        </div>

        {/* Conversation Message Stream */}
        <div role="log" aria-live="polite" aria-label="Conversation" className="flex-1 overflow-y-auto p-4 flex flex-col gap-3">
          {messages.map((m) => (
            <div
              key={m.id}
              className={`flex flex-col max-w-[85%] ${
                m.role === 'user' ? 'self-end items-end' : 'self-start items-start'
              }`}
            >
              <div
                className={`rounded-2xl px-4 py-3 text-[14px] leading-5 ${
                  m.role === 'user'
                    ? 'bg-[var(--color-teal)] text-white'
                    : m.isEmergencyNotice
                    ? 'bg-[var(--color-coral-subtle)] border-2 border-[var(--color-coral)] text-[var(--color-ocean-dark)]'
                    : 'bg-[var(--color-surface)] border border-[var(--color-border-subtle)] text-[var(--color-text-primary)] shadow-xs'
                }`}
              >
                {m.content}
              </div>
              <span className="mt-1 px-1 font-mono text-[10px] text-[var(--color-text-muted)]">
                {m.role === 'user' ? 'You' : m.source === 'ai' ? 'AI-generated · not professional advice' : 'Built-in guidance'}
              </span>
            </div>
          ))}
          {loading && (
            <p role="status" className="self-start text-[13px] text-[var(--color-text-muted)]">
              Assistant is thinking…
            </p>
          )}
          {error && (
            <p role="alert" className="self-start text-[13px] font-medium text-[var(--color-coral)]">
              {error}
            </p>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Suggested Quick Questions */}
        <div className="border-t border-[var(--color-border-subtle)] bg-[var(--color-surface)] p-3 shrink-0">
          <p className="text-[11px] font-bold uppercase tracking-wider text-[var(--color-text-muted)] mb-2 px-1">
            Predefined Guidance Topics
          </p>
          <div className="flex max-h-[26vh] flex-wrap gap-1.5 overflow-y-auto">
            {PREDEFINED_GUIDANCE.map((item) => (
              <button
                key={item.id}
                type="button"
                onClick={() => handleSelectGuidance(item)}
                className="min-h-[44px] rounded-full border border-[var(--color-teal)]/30 bg-[var(--color-teal-subtle)] px-3.5 py-2 text-[13px] font-semibold text-[var(--color-teal)] hover:bg-[var(--color-teal)] hover:text-white transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-focus)] motion-reduce:transition-none"
              >
                {item.shortLabel}
              </button>
            ))}
          </div>
        </div>

        {/* Query Input */}
        <form
          onSubmit={handleCustomSubmit}
          className="p-3 border-t border-[var(--color-border-subtle)] bg-[var(--color-surface)] flex gap-2 shrink-0"
        >
          <label htmlFor="assistant-input" className="sr-only">
            Ask a question
          </label>
          <input
            id="assistant-input"
            type="text"
            value={customInput}
            onChange={(e) => setCustomInput(e.target.value)}
            maxLength={500}
            placeholder="Ask about reporting or safety…"
            className="flex-1 rounded-xl border-2 border-[var(--color-border)] px-3 py-2 text-[14px] text-[var(--color-text-primary)] focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-focus)]"
          />
          <button
            type="submit"
            disabled={!customInput.trim() || loading}
            className="min-h-[44px] px-4 rounded-xl bg-[var(--color-teal)] text-white text-[14px] font-bold disabled:opacity-50 transition-colors hover:bg-[var(--color-teal-hover)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-focus)]"
          >
            Send
          </button>
        </form>
      </div>
    </div>
  )
}
