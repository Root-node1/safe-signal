export type SupportResource = { name: string; detail: string; tel: string }

// Edit this list as partners are confirmed. Verify every number before launch.
export const SUPPORT_RESOURCES: SupportResource[] = [
  { name: 'Police and emergency', detail: 'If you are in immediate danger', tel: '999' },
  { name: 'Emergency (mobile)', detail: 'Works from any mobile network', tel: '112' },
  { name: 'National GBV helpline', detail: 'Support after violence or harassment', tel: '1195' },
]
