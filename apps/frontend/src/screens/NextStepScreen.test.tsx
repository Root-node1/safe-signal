// T-09 (FR-6.3, RR-3.3): the failure banner must disclose that a page reload
// loses the submission key, in both the timeout and the network branch, and it
// must stay inside the live region so a screen reader announces it.
import { fireEvent, render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'

import NextStepScreen from './NextStepScreen'

function timeoutError(): Error {
  const error = new Error('Request timed out while waiting for SafeSignal server.')
  error.name = 'TimeoutError'
  return error
}

async function submitAndReadBanner(onSubmit: () => Promise<void>) {
  render(<NextStepScreen onSubmit={onSubmit} onBack={() => {}} />)
  fireEvent.click(
    screen.getByRole('radio', { name: /Submit without contacting anyone/ }),
  )
  fireEvent.click(screen.getByRole('button', { name: 'Submit report' }))
  return screen.findByRole('alert')
}

describe('NextStepScreen failure banner', () => {
  it('discloses the reload limitation after a timeout', async () => {
    const onSubmit = vi.fn().mockRejectedValue(timeoutError())
    const banner = await submitAndReadBanner(onSubmit)

    expect(banner).toHaveTextContent('Request timed out after 8 seconds.')
    expect(banner).toHaveTextContent(/tapping submit report again is safe/i)
    expect(banner).toHaveTextContent(/reloading the page loses the submission key/i)
    expect(banner).toHaveTextContent(/may be stored twice/i)
  })

  it('discloses the reload limitation after a network failure', async () => {
    const onSubmit = vi.fn().mockRejectedValue(new TypeError('Failed to fetch'))
    const banner = await submitAndReadBanner(onSubmit)

    expect(banner).toHaveTextContent('Could not connect to SafeSignal server.')
    expect(banner).toHaveTextContent(/tapping submit report again is safe/i)
    expect(banner).toHaveTextContent(/reloading the page loses the submission key/i)
    expect(banner).toHaveTextContent(/may be stored twice/i)
  })

  it('keeps the disclosure inside the alert live region', async () => {
    const onSubmit = vi.fn().mockRejectedValue(new TypeError('Failed to fetch'))
    const banner = await submitAndReadBanner(onSubmit)

    // The banner is the live region, and the new sentence lives inside it.
    expect(banner).toHaveAttribute('role', 'alert')
    expect(banner).toHaveTextContent(/may be stored twice/i)
  })

  it('does not promise that a duplicate is impossible', async () => {
    const onSubmit = vi.fn().mockRejectedValue(timeoutError())
    const banner = await submitAndReadBanner(onSubmit)

    // The caveat is conditional, and the banner keeps its original wording.
    expect(banner).toHaveTextContent(/may be stored twice/i)
    expect(banner.textContent).not.toMatch(/will never (be stored twice|create a duplicate)/i)
  })

  it('shows no banner before a submission is attempted', () => {
    render(<NextStepScreen onSubmit={vi.fn()} onBack={() => {}} />)
    expect(screen.queryByRole('alert')).toBeNull()
  })
})
