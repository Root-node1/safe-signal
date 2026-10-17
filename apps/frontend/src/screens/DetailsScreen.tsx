import { useState } from 'react'
import Shell from '../components/Shell'
import { EMPTY_DETAILS, type Details } from '../types'

type Props = {
  onContinue: (details: Details) => void
  onBack: () => void
}

type LocationStatus = 'idle' | 'loading' | 'added' | 'denied' | 'unavailable'

const inputClass =
  'mt-1 min-h-[52px] w-full rounded-xl border-2 border-[#4A5259] bg-[#F7F5F2] px-4 text-[17px] leading-6 text-[#1B1F23] placeholder:text-[#4A5259]/70 focus:outline-none focus-visible:ring-4 focus-visible:ring-[#0F5C5C]'

const labelClass = 'block text-[15px] font-medium leading-[22px]'

export default function DetailsScreen({ onContinue, onBack }: Props) {
  const [details, setDetails] = useState<Details>(EMPTY_DETAILS)
  const [status, setStatus] = useState<LocationStatus>('idle')

  const set =
    (key: 'route' | 'vehicle' | 'sacco' | 'where') =>
    (e: React.ChangeEvent<HTMLInputElement>) =>
      setDetails((d) => ({ ...d, [key]: e.target.value }))

  // Runs only when she taps the button. Never blocks the flow.
  const useMyLocation = () => {
    if (!('geolocation' in navigator)) {
      setStatus('unavailable')
      return
    }
    setStatus('loading')
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setDetails((d) => ({
          ...d,
          location: { lat: pos.coords.latitude, lng: pos.coords.longitude },
        }))
        setStatus('added')
      },
      (err) => setStatus(err.code === 1 ? 'denied' : 'unavailable'),
      { enableHighAccuracy: false, timeout: 10000, maximumAge: 60000 },
    )
  }

  const removeLocation = () => {
    setDetails((d) => ({ ...d, location: null }))
    setStatus('idle')
  }

  return (
    <Shell>
      <h1 className="text-[28px] font-bold leading-[34px]">Any details?</h1>
      <p className="mt-2 text-[18px] leading-[26px] text-[#4A5259]">
        All optional. Add what you can, or skip.
      </p>

      <div className="mt-6 flex flex-col gap-4">
        <label className={labelClass}>
          Route or stage
          <input
            type="text"
            inputMode="text"
            autoComplete="off"
            placeholder="e.g. Ruiru to Nairobi"
            value={details.route}
            onChange={set('route')}
            className={inputClass}
          />
        </label>

        <label className={labelClass}>
          Number plate or matatu name
          <input
            type="text"
            inputMode="text"
            autoComplete="off"
            autoCapitalize="characters"
            placeholder="e.g. KDA 123A"
            value={details.vehicle}
            onChange={set('vehicle')}
            className={inputClass}
          />
        </label>

        <label className={labelClass}>
          SACCO
          <input
            type="text"
            inputMode="text"
            autoComplete="off"
            placeholder="e.g. name on the side of the vehicle"
            value={details.sacco}
            onChange={set('sacco')}
            className={inputClass}
          />
        </label>

        <div>
          <label className={labelClass}>
            Where did it happen?
            <input
              type="text"
              inputMode="text"
              autoComplete="off"
              placeholder="e.g. near Githurai stage"
              value={details.where}
              onChange={set('where')}
              className={inputClass}
            />
          </label>

          {status !== 'added' ? (
            <button
              type="button"
              onClick={useMyLocation}
              disabled={status === 'loading'}
              className="mt-3 min-h-[52px] w-full rounded-xl border-2 border-[#0F5C5C] bg-transparent px-4 text-[17px] font-medium leading-6 text-[#0F5C5C] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#1B1F23] focus-visible:ring-offset-2 active:bg-[#0F5C5C]/10 disabled:opacity-60"
            >
              {status === 'loading' ? 'Finding location…' : 'Use my location'}
            </button>
          ) : (
            <div className="mt-3 flex items-center justify-between gap-3 rounded-xl border-2 border-[#0F5C5C] px-4 py-2">
              <span className="text-[15px] leading-[22px]">Location added</span>
              <button
                type="button"
                onClick={removeLocation}
                className="min-h-[44px] px-1 text-[15px] font-medium text-[#0F5C5C] underline underline-offset-4"
              >
                Remove
              </button>
            </div>
          )}

          {(status === 'denied' || status === 'unavailable') && (
            <p role="status" className="mt-2 text-[15px] leading-[22px] text-[#4A5259]">
              {status === 'denied'
                ? "No problem, location stays off. You can type where it happened instead."
                : "Couldn't get your location right now. You can type it instead."}
            </p>
          )}
        </div>
      </div>

      <div className="flex-1" />

      <section className="mt-8 flex flex-col gap-3">
        <button
          type="button"
          onClick={() => onContinue(details)}
          className="min-h-[60px] w-full rounded-2xl bg-[#0F5C5C] px-6 text-[22px] font-semibold leading-7 text-white focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#1B1F23] focus-visible:ring-offset-2 active:brightness-90"
        >
          Continue
        </button>
        <button
          type="button"
          onClick={() => onContinue(EMPTY_DETAILS)}
          className="min-h-[60px] w-full rounded-2xl border-2 border-[#0F5C5C] bg-transparent px-6 text-[22px] font-semibold leading-7 text-[#0F5C5C] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#1B1F23] focus-visible:ring-offset-2 active:bg-[#0F5C5C]/10"
        >
          Skip
        </button>
      </section>

      <button
        type="button"
        onClick={onBack}
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
