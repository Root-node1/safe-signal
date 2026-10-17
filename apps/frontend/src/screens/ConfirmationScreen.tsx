import { useState } from 'react'
import Shell from '../components/Shell'
import { PROTOTYPE } from '../lib/prototype'
import { quickExit } from '../lib/quickExit'
import { SUPPORT_RESOURCES } from '../lib/support'
import type { NextChoice } from '../types'

type Props = {
  choice: NextChoice
  code: string
  saved: boolean
  onRestart: () => void
}

type CopyStatus = 'idle' | 'done' | 'failed'

// Never shows the incident type or a full phone number on screen.
function whatHappens(choice: NextChoice): string {
  const phone = choice.contact?.phone ?? ''
  const tail = phone.replace(/\D/g, '').slice(-3)
  switch (choice.step) {
    case 'private':
      return 'Your report is recorded. Nobody has been contacted.'
    case 'trusted-contact':
      return `A short message goes to ${choice.contact?.name || 'your contact'}.`
    case 'check-in':
      return `A support partner will check in on your number ending ${tail}.`
    case 'support':
      return 'The support numbers are below.'
  }
}

export default function ConfirmationScreen({ choice, code, saved, onRestart }: Props) {
  const [copyStatus, setCopyStatus] = useState<CopyStatus>('idle')

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(code)
      setCopyStatus('done')
    } catch {
      setCopyStatus('failed')
    }
  }

  return (
    <Shell>
      <h1 className="text-[28px] font-bold leading-[34px]">Received</h1>
      <p className="mt-2 text-[18px] leading-[26px] text-[#4A5259]">
        Your reference code is below. Keep it somewhere private.
      </p>

      <section className="mt-6 rounded-2xl border-2 border-[#0F5C5C] p-5">
        <p className="text-[15px] leading-[22px] text-[#4A5259]">Reference</p>
        <p
          aria-label={`Reference code ${code}`}
          className="mt-1 font-mono text-[28px] font-bold leading-[34px] tracking-wider"
        >
          {code}
        </p>
        <button
          type="button"
          onClick={copy}
          className="mt-3 min-h-[44px] px-1 text-[17px] font-medium leading-6 text-[#0F5C5C] underline underline-offset-4 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#0F5C5C]"
        >
          {copyStatus === 'done' ? 'Copied' : 'Copy code'}
        </button>
        {copyStatus === 'failed' && (
          <p role="status" className="text-[15px] leading-[22px] text-[#4A5259]">
            Couldn't copy. You can write the code down instead.
          </p>
        )}
      </section>

      <p className="mt-6 text-[18px] leading-[26px]">{whatHappens(choice)}</p>

      {choice.step === 'support' && (
        <ul className="mt-4 flex flex-col gap-3">
          {SUPPORT_RESOURCES.map((r) => (
            <li
              key={r.tel}
              className="flex items-center justify-between gap-3 rounded-xl border-2 border-[#4A5259] px-4 py-3"
            >
              <span className="text-[17px] font-semibold leading-6">{r.name}</span>
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

      {PROTOTYPE && (
        <p className="mt-4 text-[14px] leading-5 text-[#4A5259]">
          {saved
            ? 'Prototype mode: saved to the test server. Nothing was sent to anyone.'
            : "Prototype mode: the test server wasn't reachable, so nothing was saved and this code can't be looked up."}
        </p>
      )}

      <div className="flex-1" />

      <section className="mt-8 flex flex-col gap-3">
        <button
          type="button"
          onClick={quickExit}
          className="min-h-[60px] w-full rounded-2xl bg-[#0F5C5C] px-6 text-[22px] font-semibold leading-7 text-white focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#1B1F23] focus-visible:ring-offset-2 active:brightness-90"
        >
          Done
        </button>
        <button
          type="button"
          onClick={onRestart}
          className="min-h-[52px] w-full rounded-2xl border-2 border-[#0F5C5C] bg-transparent px-6 text-[17px] font-medium leading-6 text-[#0F5C5C] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#1B1F23] focus-visible:ring-offset-2 active:bg-[#0F5C5C]/10"
        >
          Start a new report
        </button>
      </section>

      <p className="mt-6 text-[14px] leading-5 text-[#4A5259]">
        SafeSignal doesn't replace police or emergency services. In immediate
        danger, call 999 or 112.
      </p>
    </Shell>
  )
}
