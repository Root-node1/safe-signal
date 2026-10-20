import { useState, type ChangeEvent } from 'react'
import Shell from '../components/Shell'
import { Button, Card, Input } from '../components/ui'
import { EMPTY_DETAILS, type Details } from '../types'

type Props = {
  onContinue: (details: Details) => void
  onBack: () => void
}

export default function DetailsScreen({ onContinue, onBack }: Props) {
  const [details, setDetails] = useState<Details>(EMPTY_DETAILS)

  const setField =
    (key: 'route' | 'vehicle' | 'sacco' | 'where') =>
    (e: ChangeEvent<HTMLInputElement>) =>
      setDetails((prev) => ({ ...prev, [key]: e.target.value }))

  return (
    <Shell>
      {/* Progress / Step Context */}
      <div className="flex items-center justify-between text-[13px] font-semibold tracking-wide text-[var(--color-teal)]">
        <span>Step 2 of 3</span>
        <span className="font-mono text-[12px] uppercase">Incident Details</span>
      </div>

      {/* Screen Heading & Guidance */}
      <header className="mt-3">
        <h1 className="text-[28px] sm:text-[32px] font-black leading-tight tracking-tight text-[var(--color-ocean-dark)]">
          Any details to add?
        </h1>
        <p className="mt-2 text-[16px] sm:text-[17px] leading-[24px] text-[var(--color-text-muted)]">
          All fields are optional. Fill in whatever you notice, or skip directly to support.
        </p>
      </header>

      {/* Form Fields Section */}
      <form
        onSubmit={(e) => {
          e.preventDefault()
          onContinue(details)
        }}
        className="mt-6 flex flex-col gap-4"
      >
        <Input
          label="Route or corridor"
          hint="e.g. Thika Road, Jogoo Road, Rongai route, Westlands"
          value={details.route}
          onChange={setField('route')}
          placeholder="e.g. Ruiru to CBD"
          autoComplete="off"
        />

        <Input
          label="Number plate or matatu name"
          hint="e.g. KDA 123A or graffiti name written on vehicle"
          value={details.vehicle}
          onChange={setField('vehicle')}
          placeholder="e.g. KDA 123A"
          autoCapitalize="characters"
          autoComplete="off"
        />

        <Input
          label="SACCO or operator"
          hint="SACCO logo or company name on vehicle body"
          value={details.sacco}
          onChange={setField('sacco')}
          placeholder="e.g. Super Metro, Forward Travellers"
          autoComplete="off"
        />

        {/* Stage & Location Details */}
        <Input
          label="Where did it happen?"
          hint="Stage, landmark, or intersection where incident took place"
          value={details.where}
          onChange={setField('where')}
          placeholder="e.g. near Githurai 45 stage"
          autoComplete="off"
        />

        {/* Primary Form Actions */}
        <div className="mt-6 flex flex-col gap-3">
          <Button
            type="submit"
            variant="primary"
            size="lg"
            fullWidth
          >
            Continue
          </Button>

          <Button
            type="button"
            variant="secondary"
            size="lg"
            fullWidth
            onClick={() => onContinue(EMPTY_DETAILS)}
          >
            Skip all details
          </Button>
        </div>
      </form>

      {/* Back Navigation & Status */}
      <div className="mt-6 flex items-center justify-between pt-2">
        <button
          type="button"
          onClick={onBack}
          className="inline-flex min-h-[44px] items-center gap-1.5 px-2 text-[16px] font-bold text-[var(--color-teal)] underline underline-offset-4 hover:text-[var(--color-teal-hover)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[var(--color-focus)] focus-visible:ring-offset-2 rounded-lg"
        >
          <span aria-hidden="true">←</span>
          <span>Back</span>
        </button>

        <span className="text-[13px] font-medium text-[var(--color-text-muted)]">
          Nothing is shared yet
        </span>
      </div>

      {/* Calm & Discreet Safety Reassurance */}
      <Card className="mt-8 border-[var(--color-border-subtle)] bg-[var(--color-surface)] p-4 text-[13px] leading-5 text-[var(--color-text-muted)]">
        <p>
          <strong className="font-semibold text-[var(--color-text-primary)]">Safe & pressure-free:</strong> You do not need complete answers to proceed. You will review how your report is handled on the next screen.
        </p>
      </Card>
    </Shell>
  )
}
