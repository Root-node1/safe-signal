import { forwardRef, type HTMLAttributes, type ReactNode } from 'react'

export interface CardProps extends HTMLAttributes<HTMLDivElement> {
  children: ReactNode
  as?: 'div' | 'section' | 'article'
  interactive?: boolean
  elevated?: boolean
}

export const Card = forwardRef<HTMLDivElement, CardProps>(function Card(
  {
    children,
    as: Component = 'div',
    interactive = false,
    elevated = false,
    className = '',
    ...props
  },
  ref,
) {
  const baseStyles =
    'rounded-2xl border-2 border-[var(--color-border-subtle)] bg-[var(--color-surface)] p-5 text-[var(--color-text-primary)]'

  const elevationStyles = elevated
    ? 'shadow-md border-[var(--color-border)]'
    : 'shadow-sm'

  const interactiveStyles = interactive
    ? 'transition-all hover:border-[var(--color-teal)] hover:shadow-md cursor-pointer motion-reduce:transition-none focus-within:ring-2 focus-within:ring-[var(--color-focus)]'
    : ''

  return (
    <Component
      ref={ref}
      className={`${baseStyles} ${elevationStyles} ${interactiveStyles} ${className}`}
      {...props}
    >
      {children}
    </Component>
  )
})

