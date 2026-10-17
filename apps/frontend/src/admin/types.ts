import type { IncidentType, NextStep } from '../types'

export const STATUSES = [
  'Received',
  'Reviewing',
  'Assigned',
  'Contacted',
  'Referred',
  'Action taken',
  'Closed',
] as const

export type Status = (typeof STATUSES)[number]
export type Urgency = 'high' | 'medium' | 'low'

export type Report = {
  id: string
  code: string
  incident: IncidentType
  urgency: Urgency
  route: string
  area: string
  vehicle: string
  sacco: string
  support: NextStep
  consentToShare: boolean
  status: Status
  createdAt: number
  acknowledgedAt: number | null
}

export const INCIDENT_LABEL: Record<IncidentType, string> = {
  harassment: 'Harassment',
  threats: 'Threats',
  touching: 'Unwanted touching',
  followed: 'Being followed',
  'dangerous-driving': 'Dangerous driving',
  unsure: 'Other / unsure',
}

export const SUPPORT_LABEL: Record<NextStep, string> = {
  private: 'Keep private',
  'trusted-contact': 'Alert trusted contact',
  'check-in': 'Check-in requested',
  support: 'Support options only',
}
