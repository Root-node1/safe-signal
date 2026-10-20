import { forwardRef, type HTMLAttributes } from 'react'

export type StatusType = 'unverified' | 'under-review' | 'corroborated' | 'urgency' | 'neutral'

export interface StatusBadgeProps extends HTMLAttributes<HTMLSpanElement> {
  status: StatusType
  label?: string
}

const STATUS_CONFIG: Record<
  StatusType,
  { defaultLabel: string; bgClass: string; textClass: string; borderClass: string; icon: string }
> = {
  unverified: {
    defaultLabel: 'Unverified',
    bgClass: 'bg-[var(--color-surface)]',
    textClass: 'text-[var(--color-text-muted)]',
    borderClass: 'border-[var(--color-border)]',
    icon: '○',
  },
  'under-review': {
    defaultLabel: 'Under Review',
    bgClass: 'bg-[var(--color-amber-subtle)]',
    textClass: 'text-[var(--color-amber-dark)]',
    borderClass: 'border-[var(--color-amber)]',
    icon: '◐',
  },
  corroborated: {
    defaultLabel: 'Corroborated',
    bgClass: 'bg-[var(--color-teal-subtle)]',
    textClass: 'text-[var(--color-teal)]',
    borderClass: 'border-[var(--color-teal)]',
    icon: '●',
  },
  urgency: {
    defaultLabel: 'High Urgency',
    bgClass: 'bg-[var(--color-coral-subtle)]',
    textClass: 'text-[var(--color-coral)]',
    borderClass: 'border-[var(--color-coral)]',
    icon: '▲',
  },
  neutral: {
    defaultLabel: 'Info',
    bgClass: 'bg-[var(--color-surface)]',
    textClass: 'text-[var(--color-text-muted)]',
    borderClass: 'border-[var(--color-border-subtle)]',
    icon: 'ℹ',
  },
}

export const StatusBadge = forwardRef<HTMLSpanElement, StatusBadgeProps>(
  function StatusBadge({ status, label, className = '', ...props }, ref) {
    const config = STATUS_CONFIG[status]
    const text = label || config.defaultLabel

    return (
      <span
        ref={ref}
        role="status"
        className={`inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-[13px] font-semibold leading-4 select-none ${config.bgClass} ${config.textClass} ${config.borderClass} ${className}`}
        {...props}
      >
        <span aria-hidden="true" className="font-mono text-[12px] font-bold">
          {config.icon}
        </span>
        <span>{text}</span>
      </span>
    )
  },
)

