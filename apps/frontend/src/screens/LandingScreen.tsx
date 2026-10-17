import Shell from '../components/Shell'
import type { Timing } from '../types'

type Props = { onStart: (timing: Timing) => void }

export default function LandingScreen({ onStart }: Props) {
  return (
    <Shell>
      <h1 className="text-[28px] font-bold leading-[34px]">
        Feeling unsafe on your ride?
      </h1>
      <p className="mt-3 text-[18px] leading-[26px] text-[#4A5259]">
        Get discreet support. You decide what happens next.
      </p>

      <div className="flex-1" />

      <section className="mt-10">
        <button
          type="button"
          onClick={() => onStart('now')}
          className="min-h-[72px] w-full rounded-2xl bg-[#0F5C5C] px-6 text-[22px] font-semibold leading-7 text-white focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#1B1F23] focus-visible:ring-offset-2 active:brightness-90"
        >
          I feel unsafe now
        </button>

        <p className="mt-3 text-center text-[15px] leading-[22px] text-[#4A5259]">
          No account needed. Nothing is shared without your OK.
        </p>

        <button
          type="button"
          onClick={() => onStart('after')}
          className="mt-6 min-h-[52px] w-full rounded-2xl border-2 border-[#0F5C5C] bg-transparent px-6 text-[17px] font-medium leading-6 text-[#0F5C5C] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#1B1F23] focus-visible:ring-offset-2 active:bg-[#0F5C5C]/10"
        >
          I need support after an incident
        </button>
      </section>

      <p className="mt-6 text-center text-[15px] leading-[22px] text-[#4A5259]">
        Nothing is saved on this phone.
      </p>

      <p className="mt-6 text-center text-[14px] leading-5 text-[#4A5259]">
        SafeSignal doesn't replace police or emergency services. In immediate
        danger, call 999 or 112.
      </p>
    </Shell>
  )
}
