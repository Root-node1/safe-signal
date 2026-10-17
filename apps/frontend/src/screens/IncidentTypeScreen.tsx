import { useEffect, useRef, useState } from 'react'
import Shell from '../components/Shell'
import type { IncidentType } from '../types'

type Option = { id: IncidentType; label: string }

const OPTIONS: Option[] = [
  { id: 'harassment', label: 'Someone is harassing me' },
  { id: 'threats', label: 'Someone is threatening me' },
  { id: 'touching', label: 'Unwanted touching' },
  { id: 'followed', label: "I think I'm being followed" },
  { id: 'dangerous-driving', label: 'The driver is driving dangerously' },
  { id: 'unsure', label: 'Something else / not sure' },
]

type Props = {
  onSelect: (id: IncidentType) => void | Promise<void>
  onBack: () => void
}

export default function IncidentTypeScreen({ onSelect, onBack }: Props) {
  const [pickedId, setPickedId] = useState<IncidentType | null>(null)
  const [error, setError] = useState(false)
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined)

  useEffect(() => () => clearTimeout(timer.current), [])

  const choose = (id: IncidentType) => {
    if (pickedId) return
    setError(false)
    setPickedId(id)
    timer.current = setTimeout(async () => {
      try {
        await onSelect(id)
      } catch {
        setPickedId(null)
        setError(true)
      }
    }, 150)
  }

  return (
    <Shell>
      <h1 className="text-[28px] font-bold leading-[34px]">
        What is happening?
      </h1>
      <p className="mt-2 text-[18px] leading-[26px] text-[#4A5259]">
        Pick the closest one. You decide what happens next.
      </p>

      {error && (
        <div
          role="alert"
          className="mt-4 rounded-xl border-2 border-[#1B1F23] px-4 py-3 text-[15px] leading-[22px]"
        >
          That didn't go through. Please tap again.
        </div>
      )}

      <ul className="mt-6 flex flex-col gap-3">
        {OPTIONS.map((o) => {
          const selected = pickedId === o.id
          return (
            <li key={o.id}>
              <button
                type="button"
                aria-pressed={selected}
                disabled={pickedId !== null && !selected}
                onClick={() => choose(o.id)}
                className={`flex min-h-[64px] w-full items-center justify-between gap-3 rounded-xl border-2 px-4 py-3 text-left text-[22px] font-semibold leading-[28px] transition-colors focus:outline-none focus-visible:ring-4 focus-visible:ring-[#0F5C5C] ${
                  selected
                    ? 'border-[#0F5C5C] bg-[#0F5C5C] text-white'
                    : 'border-[#4A5259] bg-[#F7F5F2] text-[#1B1F23] active:bg-[#0F5C5C] active:text-white disabled:opacity-60'
                }`}
              >
                <span>{o.label}</span>
                {selected && <span aria-hidden="true">✓</span>}
              </button>
            </li>
          )
        })}
      </ul>

      <button
        type="button"
        onClick={onBack}
        disabled={pickedId !== null}
        className="mt-4 min-h-[44px] self-start px-1 text-[17px] font-medium leading-6 text-[#0F5C5C] underline underline-offset-4 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#0F5C5C]"
      >
        Back
      </button>

      <p className="mt-6 text-[14px] leading-5 text-[#4A5259]">
        Nothing is shared yet.
      </p>
    </Shell>
  )
}
