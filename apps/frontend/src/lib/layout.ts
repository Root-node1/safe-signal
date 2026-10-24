export type ShellMaxWidth = 'default' | 'wide'

// Shared responsive container ladder so every Shell variant and the SafeHeader
// track the same content edges (FR-11.4). `default` is tuned for focused
// reporting forms; `wide` lets landing/admin content breathe on larger viewports.
export function shellMaxWidthClass(maxWidth: ShellMaxWidth): string {
  return maxWidth === 'wide'
    ? 'max-w-[390px] md:max-w-[720px] lg:max-w-[960px] xl:max-w-[1040px]'
    : 'max-w-[390px] md:max-w-[560px] lg:max-w-[640px]'
}
