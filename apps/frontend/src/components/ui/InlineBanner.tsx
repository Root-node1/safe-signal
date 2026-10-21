import { type ReactNode } from 'react'

export interface InlineBannerProps {
  variant: 'error' | 'warning' | 'info'
  title?: string
  children: ReactNode
  role?: 'alert' | 'status'
}

/**
 * InlineBanner — WCAG 4.1.3 (status messages).
 *
 * A small, non-blocking status banner. `role` defaults to `"alert"` for
 * `error` and `warning` variants (assertive) and `"status"` for `info`
 * (polite). Colour mapping:
 *   error   → coral border, coral-subtle background, coral text
 *   warning → amber-subtle background, amber-dark text, no border
 *   info    → teal-subtle background, teal text, no border
 */
export function InlineBanner({
  variant,
  title,
  children,
  role,
}: InlineBannerProps) {
  const styles: Record<InlineBannerProps['variant'], string> = {
    error:
      'border-2 border-[var(--color-coral)] bg-[var(--color-coral-subtle)] text-[var(--color-coral)]',
    warning:
      'border border-transparent bg-[var(--color-amber-subtle)] text-[var(--color-amber-dark)]',
    info:
      'border border-transparent bg-[var(--color-teal-subtle)] text-[var(--color-teal)]',
  }

  const defaultRole: 'alert' | 'status' =
    variant === 'info' ? 'status' : 'alert'

  const alertRole = role ?? defaultRole

  return (
    <div
      role={alertRole}
      className={`flex items-start gap-2.5 rounded-xl px-4 py-3 text-[var(--text-xs)] sm:text-[13px] leading-5 ${styles[variant]}`}
    >
      {title ? (
        <span>
          <span className="font-bold">{title}</span>
          {children}
        </span>
      ) : (
        children
      )}
    </div>
  )
}