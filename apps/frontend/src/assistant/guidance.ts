export interface PredefinedGuidance {
  id: string
  query: string
  shortLabel: string
  answer: string
  category: 'reporting' | 'corridors' | 'support' | 'emergency'
}

export const PREDEFINED_GUIDANCE: PredefinedGuidance[] = [
  {
    id: 'how-to-report',
    shortLabel: 'How reporting works',
    query: 'How do I submit an incident report?',
    category: 'reporting',
    answer:
      'Tap "Report an incident" on the home screen. You can select an incident category, optionally provide details (corridor, vehicle plate, SACCO, or landmark), and submit to the configured SafeSignal backend store. In the current release, you can also view national helpline numbers. No account is required.',
  },
  {
    id: 'what-is-corroboration',
    shortLabel: 'Corroboration (Planned)',
    query: 'What does corroboration mean in SafeSignal?',
    category: 'corridors',
    answer:
      'SafeSignal does not confirm an incident based on a single commuter report alone. Corroboration is a planned feature designed to connect multiple reports sharing the same corridor, operator, and timeframe to highlight general safety patterns. It is not yet live.',
  },
  {
    id: 'emergency-services',
    shortLabel: 'Emergency boundaries',
    query: 'Does SafeSignal call the police or an ambulance?',
    category: 'emergency',
    answer:
      'No. SafeSignal is a safety intelligence tool in development, not an emergency response service. SafeSignal cannot alert police, medical teams, or emergency responders. In immediate physical danger, dial 999 or 112 directly from your phone.',
  },
  {
    id: 'data-privacy',
    shortLabel: 'Data & backend storage',
    query: 'How is my report data handled?',
    category: 'reporting',
    answer:
      'No account is required to submit a report. The current backend stores submitted route, vehicle, and area text in memory. GPS coordinates and phone numbers are not collected by the backend. Do not include personal names or sensitive private information in report descriptions.',
  },
]
