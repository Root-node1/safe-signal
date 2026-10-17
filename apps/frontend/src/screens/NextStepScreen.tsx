import { useState, type ChangeEvent } from 'react'
import Shell from '../components/Shell'
import { PROTOTYPE } from '../lib/prototype'
import { isValidKenyanPhone } from '../lib/phone'
import { SUPPORT_RESOURCES } from '../lib/support'
import type { NextChoice, NextStep } from '../types'

type StepOption = { id: NextStep; title: string; hint: string }

const STEPS: StepOption[] = [
  { id: 'private', title: 'Keep this private', hint: 'Only record what happened. Nobody is contacted.' },
  { id: 'trusted-contact', title: 'Alert someone I trust', hint: 'Send a short message to one person you choose.' },
  { id: 'check-in', title: 'Ask for a check-in', hint: 'A support partner follows up to see you are okay.' },
  { id: 'support', title: 'See support options', hint: 'Numbers and services you can reach.' },
]

type Props = {
  onSubmit: (choice: NextChoice) => void
  onBack: () => void
}

const inputClass =
  'mt-1 min-h-[52px] w-full rounded-xl border-2 border-[#4A5259] bg-[#F7F5F2] px-4 text-[17px] leading-6 text-[#1B1F23] placeholder:text-[#4A5259]/70 focus:outline-none focus-visible:ring-4 focus-visible:ring-[#0F5C5C]'

export default function NextStepScreen({ onSubmit, onBack }: Props) {
  const [step, setStep] = useState<NextStep | null>(null)
  const [name, setName] = useState('')
  const [phone, setPhone] = useState('')
  const [touched, setTouched] = useState(false)

  const needsContact = step === 'trusted-contact' || step === 'check-in'
  const phoneOk = isValidKenyanPhone(phone)
  const canSubmit = step !== null && (!needsContact || phoneOk)

  const submit = () => {
    if (!step) return
    if (needsContact && !phoneOk) {
      setTouched(true)
      return
    }
    onSubmit({
      step,
      contact: needsContact ? { name: name.trim(), phone: phone.trim() } : null,
    })
  }

  return (
    <Shell>
      <h1 className="text-[28px] font-bold leading-[34px]">
        What would help most?
      </h1>
      <p className="mt-2 text-[18px] leading-[26px] text-[#4A5259]">
        You choose. Nothing happens without your OK.
      </p>

      <div
        role="radiogroup"
        aria-label="Next step"
        className="mt-6 flex flex-col gap-3"
      >
        {STEPS.map((s) => {
          const selected = step === s.id
          return (
            <button
              key={s.id}
              type="button"
              role="radio"
              aria-checked={selected}
              onClick={() => {
                setStep(s.id)
                setTouched(false)
              }}
              className={`flex min-h-[64px] w-full flex-col items-start justify-center rounded-xl border-2 px-4 py-3 text-left transition-colors focus:outline-none focus-visible:ring-4 focus-visible:ring-[#0F5C5C] ${
                selected
                  ? 'border-[#0F5C5C] bg-[#0F5C5C] text-white'
                  : 'border-[#4A5259] bg-[#F7F5F2] text-[#1B1F23]'
              }`}
            >
              <span className="text-[20px] font-semibold leading-[26px]">
                {s.title}
              </span>
              <span
                className={`mt-1 text-[15px] leading-[22px] ${
                  selected ? 'text-white' : 'text-[#4A5259]'
                }`}
              >
                {s.hint}
              </span>
            </button>
          )
        })}
      </div>

      {needsContact && (
        <section className="mt-5 flex flex-col gap-4 rounded-xl border-2 border-[#0F5C5C] p-4">
          <label className="block text-[15px] font-medium leading-[22px]">
            {step === 'trusted-contact' ? 'Their name (optional)' : 'What should we call you? (optional)'}
            <input
              type="text"
              inputMode="text"
              autoComplete="off"
              value={name}
              onChange={(e: ChangeEvent<HTMLInputElement>) => setName(e.target.value)}
              className={inputClass}
            />
          </label>

          <label className="block text-[15px] font-medium leading-[22px]">
            {step === 'trusted-contact' ? 'Their phone number' : 'Your phone number'}
            <input
              type="tel"
              inputMode="tel"
              autoComplete="off"
              placeholder="0712 345 678"
              value={phone}
              onChange={(e: ChangeEvent<HTMLInputElement>) => setPhone(e.target.value)}
              onBlur={() => setTouched(true)}
              aria-invalid={touched && !phoneOk}
              className={inputClass}
            />
          </label>

          {touched && !phoneOk && (
            <p role="status" className="text-[15px] leading-[22px]">
              Enter a Kenyan number like 0712 345 678.
            </p>
          )}

          <p className="text-[14px] leading-5 text-[#4A5259]">
            {step === 'trusted-contact'
              ? 'We only message this person because you chose to.'
              : 'We only use this number to check in with you.'}
            {PROTOTYPE && ' Prototype mode: no message is actually sent.'}
          </p>
        </section>
      )}

      {step === 'support' && (
        <ul className="mt-5 flex flex-col gap-3">
          {SUPPORT_RESOURCES.map((r) => (
            <li
              key={r.tel}
              className="flex items-center justify-between gap-3 rounded-xl border-2 border-[#4A5259] px-4 py-3"
            >
              <div>
                <p className="text-[17px] font-semibold leading-6">{r.name}</p>
                <p className="text-[15px] leading-[22px] text-[#4A5259]">{r.detail}</p>
              </div>
              <a
                href={`tel:${r.tel}`}
                className="inline-flex min-h-[44px] min-w-[44px] items-center justify-center rounded-full bg-[#0F5C5C] px-5 text-[17px] font-semibold text-white focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#1B1F23] focus-visible:ring-offset-2"
              >
                {r.tel}
              </a>
            </li>
          ))}
        </ul>
      )}

      <div className="flex-1" />

      <button
        type="button"
        onClick={submit}
        disabled={!canSubmit}
        className="mt-8 min-h-[60px] w-full rounded-2xl bg-[#0F5C5C] px-6 text-[22px] font-semibold leading-7 text-white focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#1B1F23] focus-visible:ring-offset-2 active:brightness-90 disabled:opacity-50"
      >
        Submit
      </button>

      <button
        type="button"
        onClick={onBack}
        className="mt-4 min-h-[44px] self-start px-1 text-[17px] font-medium leading-6 text-[#0F5C5C] underline underline-offset-4 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#0F5C5C]"
      >
        Back
      </button>

      <p className="mt-6 text-[14px] leading-5 text-[#4A5259]">
        SafeSignal doesn't replace police or emergency services. In immediate
        danger, call 999 or 112.
      </p>
    </Shell>
  )
}
