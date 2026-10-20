import { forwardRef, type HTMLAttributes, type ReactNode } from 'react'

export interface GlassSurfaceProps extends HTMLAttributes<HTMLDivElement> {
  children: ReactNode
  as?: 'header' | 'nav' | 'div' | 'section'
  borderBottom?: boolean
}

export const GlassSurface = forwardRef<HTMLDivElement, GlassSurfaceProps>(function GlassSurface(
  {
    children,
    as: Component = 'div',
    borderBottom = false,
    className = '',
    ...props
  },
  ref,
) {
  const borderClass = borderBottom
    ? 'border-b border-[var(--glass-border)] shadow-sm'
    : 'border border-[var(--glass-border)]'

  return (
    <Component
      ref={ref}
      className={`glass-panel transition-colors duration-200 ${borderClass} ${className}`}
      {...props}
    >
      {children}
    </Component>
  )
})

