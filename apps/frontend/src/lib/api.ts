import type { Details, IncidentType, NextChoice, NextStep, Timing } from '../types'

export const API_URL: string =
  import.meta.env.VITE_API_URL ?? 'http://localhost:8000'

export type ReportPayload = {
  incident: IncidentType
  timing: Timing
  route: string
  area: string
  vehicle: string
  sacco: string
  support: NextStep
  contactProvided: boolean
  consentToShare: boolean
}

// The phone number and GPS coordinates are deliberately NOT sent.
export function buildPayload(
  timing: Timing,
  incident: IncidentType,
  details: Details,
  choice: NextChoice,
): ReportPayload {
  return {
    incident,
    timing,
    route: details.route.trim(),
    area: details.where.trim(),
    vehicle: details.vehicle.trim(),
    sacco: details.sacco.trim(),
    support: choice.step,
    contactProvided: choice.contact !== null,
    consentToShare: false, // no consent screen yet
  }
}

export async function createReport(
  payload: ReportPayload,
): Promise<{ code: string }> {
  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), 8000)
  try {
    const res = await fetch(`${API_URL}/api/reports`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: controller.signal,
    })
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data: unknown = await res.json()
    if (
      typeof data === 'object' &&
      data !== null &&
      'code' in data &&
      typeof data.code === 'string'
    ) {
      return { code: data.code }
    }
    throw new Error('Unexpected response')
  } finally {
    clearTimeout(timer)
  }
}
