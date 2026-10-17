import { useState } from 'react'
import { PROTOTYPE } from '../lib/prototype'
import { MOCK_REPORTS } from '../admin/mockReports'
import { buildSignals, medianAckMinutes, openCount, timeAgo } from '../admin/stats'
import {
  INCIDENT_LABEL,
  STATUSES,
  SUPPORT_LABEL,
  type Report,
  type Status,
  type Urgency,
} from '../admin/types'

const URGENCY_RANK: Record<Urgency, number> = { high: 0, medium: 1, low: 2 }

const urgencyClass: Record<Urgency, string> = {
  high: 'bg-[#1B1F23] text-white',
  medium: 'bg-[#0F5C5C] text-white',
  low: 'border border-[#4A5259] text-[#1B1F23]',
}

export default function AdminScreen() {
  const [reports, setReports] = useState<Report[]>(MOCK_REPORTS)
  const [selectedId, setSelectedId] = useState<string>(MOCK_REPORTS[0].id)
  const [now] = useState(() => Date.now())

  // No auth exists yet, so the dashboard must not ship in a real build.
  if (!PROTOTYPE) {
    return (
      <main className="mx-auto max-w-[640px] p-6 font-sans text-[#1B1F23]">
        <h1 className="text-[28px] font-bold leading-[34px]">Not available</h1>
        <p className="mt-2 text-[18px] text-[#4A5259]">
          The response dashboard needs sign-in, which is not built yet.
        </p>
      </main>
    )
  }

  const sorted = [...reports].sort(
    (a, b) =>
      URGENCY_RANK[a.urgency] - URGENCY_RANK[b.urgency] || b.createdAt - a.createdAt,
  )
  const selected = reports.find((r) => r.id === selectedId) ?? sorted[0]
  const median = medianAckMinutes(reports)
  const signals = buildSignals(reports)

  const setStatus = (id: string, status: Status) =>
    setReports((rs) =>
      rs.map((r) =>
        r.id === id
          ? {
              ...r,
              status,
              acknowledgedAt:
                r.acknowledgedAt ?? (status !== 'Received' ? Date.now() : null),
            }
          : r,
      ),
    )

  return (
    <div className="min-h-screen bg-[#F7F5F2] font-sans text-[#1B1F23]">
      <header className="border-b-2 border-[#4A5259]/30">
        <div className="mx-auto flex w-full max-w-[1100px] items-center justify-between px-5 py-3">
          <span className="text-[15px] font-semibold leading-5">
            SafeSignal Response
            <span className="ml-2 rounded-full border border-[#4A5259] px-2 py-0.5 text-[12px] font-medium text-[#4A5259]">
              Prototype
            </span>
          </span>
          <span className="text-[14px] text-[#4A5259]">Mock data, resets on refresh</span>
        </div>
      </header>

      <main className="mx-auto w-full max-w-[1100px] px-5 pb-10 pt-6">
        <h1 className="text-[28px] font-bold leading-[34px]">Cases</h1>

        <section className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-3">
          <Metric label="Open cases" value={String(openCount(reports))} />
          <Metric label="Total reports" value={String(reports.length)} />
          <Metric
            label="Median time to acknowledge"
            value={median === null ? 'None yet' : `${median} min`}
          />
        </section>

        <section className="mt-6">
          <h2 className="text-[20px] font-semibold leading-7">Route signals</h2>
          <p className="text-[15px] leading-[22px] text-[#4A5259]">
            Anonymized. Route and type only. Confirmed at 2 or more reports.
          </p>
          <ul className="mt-3 grid grid-cols-1 gap-3 md:grid-cols-2">
            {signals.map((s) => (
              <li
                key={s.key}
                className="flex items-center justify-between gap-3 rounded-xl border-2 border-[#4A5259] px-4 py-3"
              >
                <div>
                  <p className="text-[17px] font-semibold leading-6">{s.route}</p>
                  <p className="text-[15px] leading-[22px] text-[#4A5259]">{s.label}</p>
                </div>
                <div className="text-right">
                  <p className="text-[20px] font-bold leading-7">{s.count}</p>
                  <p className="text-[13px] leading-[18px] text-[#4A5259]">
                    {s.confirmed ? 'Confirmed' : 'Unverified'}
                  </p>
                </div>
              </li>
            ))}
          </ul>
        </section>

        <div className="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-[1fr_380px]">
          <section>
            <h2 className="text-[20px] font-semibold leading-7">Reports</h2>
            <ul className="mt-3 flex flex-col gap-3">
              {sorted.map((r) => {
                const active = r.id === selected.id
                return (
                  <li key={r.id}>
                    <button
                      type="button"
                      aria-pressed={active}
                      onClick={() => setSelectedId(r.id)}
                      className={`flex min-h-[64px] w-full items-center justify-between gap-3 rounded-xl border-2 px-4 py-3 text-left focus:outline-none focus-visible:ring-4 focus-visible:ring-[#0F5C5C] ${
                        active ? 'border-[#0F5C5C] bg-white' : 'border-[#4A5259]/40 bg-[#F7F5F2]'
                      }`}
                    >
                      <div>
                        <p className="text-[17px] font-semibold leading-6">
                          {INCIDENT_LABEL[r.incident]} · {r.route}
                        </p>
                        <p className="text-[15px] leading-[22px] text-[#4A5259]">
                          {r.code} · {timeAgo(now, r.createdAt)} · {r.status}
                        </p>
                      </div>
                      <span
                        className={`rounded-full px-3 py-1 text-[13px] font-semibold capitalize ${urgencyClass[r.urgency]}`}
                      >
                        {r.urgency}
                      </span>
                    </button>
                  </li>
                )
              })}
            </ul>
          </section>

          <aside className="h-fit rounded-2xl border-2 border-[#0F5C5C] bg-white p-5">
            <h2 className="text-[20px] font-semibold leading-7">{selected.code}</h2>
            <dl className="mt-3 grid grid-cols-[120px_1fr] gap-x-3 gap-y-2 text-[15px] leading-[22px]">
              <dt className="text-[#4A5259]">Type</dt>
              <dd>{INCIDENT_LABEL[selected.incident]}</dd>
              <dt className="text-[#4A5259]">Route</dt>
              <dd>{selected.route}</dd>
              <dt className="text-[#4A5259]">Area</dt>
              <dd>{selected.area || 'Not given'}</dd>
              <dt className="text-[#4A5259]">Vehicle</dt>
              <dd>{selected.vehicle || 'Not given'}</dd>
              <dt className="text-[#4A5259]">SACCO</dt>
              <dd>{selected.sacco || 'Not given'}</dd>
              <dt className="text-[#4A5259]">She chose</dt>
              <dd>{SUPPORT_LABEL[selected.support]}</dd>
              <dt className="text-[#4A5259]">Share consent</dt>
              <dd>{selected.consentToShare ? 'Yes' : 'No, keep internal'}</dd>
              <dt className="text-[#4A5259]">Reported</dt>
              <dd>{timeAgo(now, selected.createdAt)}</dd>
            </dl>

            <label className="mt-5 block text-[15px] font-medium leading-[22px]">
              Case status
              <select
                value={selected.status}
                onChange={(e) => setStatus(selected.id, e.target.value as Status)}
                className="mt-1 min-h-[52px] w-full rounded-xl border-2 border-[#4A5259] bg-[#F7F5F2] px-3 text-[17px] focus:outline-none focus-visible:ring-4 focus-visible:ring-[#0F5C5C]"
              >
                {STATUSES.map((s) => (
                  <option key={s} value={s}>
                    {s}
                  </option>
                ))}
              </select>
            </label>

            <p className="mt-4 text-[13px] leading-[18px] text-[#4A5259]">
              Vehicle and SACCO are internal only. They never appear in route signals.
            </p>
          </aside>
        </div>
      </main>
    </div>
  )
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border-2 border-[#4A5259]/40 bg-white px-4 py-3">
      <p className="text-[14px] leading-5 text-[#4A5259]">{label}</p>
      <p className="mt-1 text-[28px] font-bold leading-[34px]">{value}</p>
    </div>
  )
}
