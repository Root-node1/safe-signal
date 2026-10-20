import { forwardRef, type ButtonHTMLAttributes, type ReactNode } from 'react'

export type ButtonVariant = 'primary' | 'secondary' | 'urgency' | 'ghost'
export type ButtonSize = 'sm' | 'md' | 'lg'

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant
  size?: ButtonSize
  children: ReactNode
  fullWidth?: boolean
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  {
    variant = 'primary',
    size = 'md',
    fullWidth = false,
    className = '',
    disabled = false,
    children,
    ...props
  },
  ref,
) {
  const baseStyles =
    'inline-flex items-center justify-center font-semibold rounded-2xl transition-colors select-none ' +
    'focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)] focus-visible:ring-offset-2 ' +
    'motion-reduce:transition-none disabled:opacity-50 disabled:cursor-not-allowed disabled:pointer-events-none'

  const sizeStyles: Record<ButtonSize, string> = {
    sm: 'min-h-[44px] px-4 py-2 text-[15px] leading-5',
    md: 'min-h-[52px] px-5 py-3 text-[17px] leading-6',
    lg: 'min-h-[60px] px-6 py-4 text-[20px] leading-7',
  }

  const variantStyles: Record<ButtonVariant, string> = {
    primary:
      'bg-[var(--color-teal)] text-white hover:bg-[var(--color-teal-hover)] active:brightness-95 shadow-sm',
    secondary:
      'border-2 border-[var(--color-teal)] bg-transparent text-[var(--color-teal)] hover:bg-[var(--color-teal-subtle)] active:bg-[var(--color-teal-subtle)]',
    urgency:
      'bg-[var(--color-coral)] text-white hover:bg-[var(--color-coral-hover)] active:brightness-95 shadow-sm',
    ghost:
      'bg-transparent text-[var(--color-teal)] hover:bg-[var(--color-teal-subtle)] underline underline-offset-4',
  }

  const widthStyle = fullWidth ? 'w-full' : ''

  return (
    <button
      ref={ref}
      disabled={disabled}
      className={`${baseStyles} ${sizeStyles[size]} ${variantStyles[variant]} ${widthStyle} ${className}`}
      {...props}
    >
      {children}
    </button>
  )
})

