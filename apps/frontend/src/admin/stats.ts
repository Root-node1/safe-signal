import { INCIDENT_LABEL, type Report } from './types'

export function openCount(reports: Report[]): number {
  return reports.filter((r) => r.status !== 'Closed').length
}

// Median minutes from report to first acknowledgement. Null if none yet.
export function medianAckMinutes(reports: Report[]): number | null {
  const mins = reports
    .filter((r) => r.acknowledgedAt !== null)
    .map((r) => ((r.acknowledgedAt as number) - r.createdAt) / 60_000)
    .sort((a, b) => a - b)
  if (mins.length === 0) return null
  const mid = Math.floor(mins.length / 2)
  const value = mins.length % 2 ? mins[mid] : (mins[mid - 1] + mins[mid]) / 2
  return Math.round(value)
}

export type Signal = {
  key: string
  route: string
  label: string
  count: number
  confirmed: boolean
}

// Anonymized: route + incident type + count only. Never plates or SACCOs.
export function buildSignals(reports: Report[]): Signal[] {
  const map = new Map<string, Signal>()
  for (const r of reports) {
    const key = `${r.route}|${r.incident}`
    const existing = map.get(key)
    if (existing) {
      existing.count += 1
      existing.confirmed = existing.count >= 2
    } else {
      map.set(key, {
        key,
        route: r.route,
        label: INCIDENT_LABEL[r.incident],
        count: 1,
        confirmed: false,
      })
    }
  }
  return [...map.values()].sort((a, b) => b.count - a.count)
}

export function timeAgo(now: number, ts: number): string {
  const m = Math.max(0, Math.round((now - ts) / 60_000))
  if (m < 60) return `${m} min ago`
  if (m < 1440) return `${Math.round(m / 60)} h ago`
  return `${Math.round(m / 1440)} d ago`
}
