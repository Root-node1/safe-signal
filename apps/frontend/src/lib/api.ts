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

// One key per logical submission. Memory only; never derived from report content.
export function newSubmissionKey(): string {
  if (typeof crypto.randomUUID === 'function') return crypto.randomUUID()
  const b = crypto.getRandomValues(new Uint8Array(16))
  return Array.from(b, (x) => x.toString(16).padStart(2, '0')).join('')
}

export async function createReport(
  payload: ReportPayload,
  idempotencyKey: string,
): Promise<{ code: string }> {
  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), 8000)
  try {
    const res = await fetch(`${API_URL}/api/reports`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Idempotency-Key': idempotencyKey },
      body: JSON.stringify(payload),
      signal: controller.signal,
    })
    if (!res.ok) {
      throw new Error(`HTTP ${res.status}`)
    }
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
  } catch (err: unknown) {
    if (err instanceof Error && err.name === 'AbortError') {
      const timeoutError = new Error('Request timed out while waiting for SafeSignal server.')
      timeoutError.name = 'TimeoutError'
      throw timeoutError
    }
    throw err
  } finally {
    clearTimeout(timer)
  }
}

export type AssistantReply = { reply: string; source: 'ai' | 'emergency' }

export async function askAssistant(
  message: string,
  history: { role: 'user' | 'assistant'; content: string }[],
): Promise<AssistantReply> {
  const res = await fetch(`${API_URL}/api/assistant/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message, history }),
    signal: AbortSignal.timeout(25000),
  })
  if (!res.ok) throw new Error(String(res.status))
  return res.json()
}
