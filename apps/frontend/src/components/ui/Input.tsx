import { forwardRef, useId, type InputHTMLAttributes, type ReactNode } from 'react'

export interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string
  error?: string
  hint?: string
  endAdornment?: ReactNode
}

export const Input = forwardRef<HTMLInputElement, InputProps>(function Input(
  {
    label,
    error,
    hint,
    id: explicitId,
    className = '',
    required = false,
    endAdornment,
    ...props
  },
  ref,
) {
  const generatedId = useId()
  const id = explicitId || generatedId
  const errorId = `${id}-error`
  const hintId = `${id}-hint`

  return (
    <div className="w-full">
      <label
        htmlFor={id}
        className="block text-[15px] font-medium leading-[22px] text-[var(--color-text-primary)]"
      >
        {label}
        {required && <span className="ml-1 text-[var(--color-coral)]" aria-hidden="true">*</span>}
      </label>

      {hint && (
        <p id={hintId} className="mt-0.5 text-[14px] leading-5 text-[var(--color-text-muted)]">
          {hint}
        </p>
      )}

      <div className="relative mt-1">
        <input
          ref={ref}
          id={id}
          required={required}
          aria-invalid={Boolean(error)}
          aria-describedby={
            [error ? errorId : null, hint ? hintId : null].filter(Boolean).join(' ') ||
            undefined
          }
          className={`min-h-[52px] w-full rounded-xl border-2 bg-[var(--color-surface)] px-4 text-[17px] leading-6 text-[var(--color-text-primary)] transition-colors placeholder:text-[var(--color-text-muted)]/70 focus:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)] focus-visible:ring-offset-1 disabled:opacity-50 disabled:bg-[var(--color-canvas)] ${
            error
              ? 'border-[var(--color-coral)]'
              : 'border-[var(--color-border)] hover:border-[var(--color-teal)] focus:border-[var(--color-teal)]'
          } ${endAdornment ? 'pr-12' : ''} ${className}`}
          {...props}
        />
        {endAdornment && (
          <div className="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
            {endAdornment}
          </div>
        )}
      </div>

      {error && (
        <p
          id={errorId}
          role="alert"
          className="mt-1.5 flex items-center gap-1 text-[14px] font-medium leading-5 text-[var(--color-coral)]"
        >
          <span aria-hidden="true" className="font-bold">⚠</span>
          <span>{error}</span>
        </p>
      )}
    </div>
  )
})

