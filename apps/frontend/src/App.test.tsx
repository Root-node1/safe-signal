import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import '@testing-library/jest-dom/vitest'

import App from './App'

// The App-level half of the submission-key policy (T-08): the header the app
// actually sends must be reused for an unchanged payload and replaced for a
// changed one.

const fetchMock = vi.fn()

function okResponse(code: string) {
  return { ok: true, status: 201, json: async () => ({ code }) }
}

function idempotencyKey(call: number): string {
  const init = fetchMock.mock.calls[call][1] as RequestInit
  return (init.headers as Record<string, string>)['Idempotency-Key']
}

/** Walk the reporting flow up to the submit button. */
async function fillReport(route: string) {
  fireEvent.click(screen.getByRole('button', { name: /Report an incident/ }))
  const incident = await screen.findByRole('radio', { name: /Someone is threatening me/ })
  fireEvent.click(incident)
  const routeInput = await screen.findByLabelText(/Route or corridor/i)
  fireEvent.change(routeInput, { target: { value: route } })
  fireEvent.click(screen.getByRole('button', { name: 'Continue' }))
  await screen.findByRole('radiogroup', { name: 'How to handle your report' })
  fireEvent.click(
    screen.getByRole('radio', { name: /Submit without contacting anyone/ }),
  )
  await waitFor(() =>
    expect(screen.getByRole('button', { name: 'Submit report' })).toBeEnabled(),
  )
}

describe('App submission key policy', () => {
  beforeEach(() => {
    fetchMock.mockReset()
    vi.stubGlobal('fetch', fetchMock)
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('sends the same Idempotency-Key for two identical submissions', async () => {
    fetchMock.mockRejectedValueOnce(new TypeError('Failed to fetch'))
    fetchMock.mockResolvedValueOnce(okResponse('SS-TEST-1111'))
    render(<App />)

    await fillReport('Ruiru to CBD')
    fireEvent.click(screen.getByRole('button', { name: 'Submit report' }))
    await screen.findByText(/Could not connect to SafeSignal server/)

    // Same payload, retried: the key must be reused, not re-minted.
    fireEvent.click(screen.getByRole('button', { name: 'Submit report' }))
    await screen.findByText('SS-TEST-1111')

    expect(fetchMock).toHaveBeenCalledTimes(2)
    expect(idempotencyKey(0)).toBe(idempotencyKey(1))
  })

  it('sends a new Idempotency-Key when the payload changes', async () => {
    fetchMock.mockRejectedValueOnce(new TypeError('Failed to fetch'))
    fetchMock.mockResolvedValueOnce(okResponse('SS-TEST-2222'))
    render(<App />)

    await fillReport('Ruiru to CBD')
    fireEvent.click(screen.getByRole('button', { name: 'Submit report' }))
    await screen.findByText(/Could not connect to SafeSignal server/)

    // Go back, change the route, and submit again.
    fireEvent.click(screen.getByRole('button', { name: 'Back' }))
    const routeInput = await screen.findByLabelText(/Route or corridor/i)
    fireEvent.change(routeInput, { target: { value: 'Thika Road' } })
    fireEvent.click(screen.getByRole('button', { name: 'Continue' }))
    await screen.findByRole('radiogroup', { name: 'How to handle your report' })
    fireEvent.click(
      screen.getByRole('radio', { name: /Submit without contacting anyone/ }),
    )
    await waitFor(() =>
      expect(screen.getByRole('button', { name: 'Submit report' })).toBeEnabled(),
    )
    fireEvent.click(screen.getByRole('button', { name: 'Submit report' }))
    await screen.findByText('SS-TEST-2222')

    expect(fetchMock).toHaveBeenCalledTimes(2)
    expect(idempotencyKey(0)).not.toBe(idempotencyKey(1))
  })

  it('mints a new key after a successful submission and a restart', async () => {
    fetchMock.mockResolvedValueOnce(okResponse('SS-TEST-3333'))
    fetchMock.mockResolvedValueOnce(okResponse('SS-TEST-4444'))
    render(<App />)

    await fillReport('Ruiru to CBD')
    fireEvent.click(screen.getByRole('button', { name: 'Submit report' }))
    await screen.findByText('SS-TEST-3333')

    // Success clears the key; a restart starts a new logical submission.
    fireEvent.click(screen.getByRole('button', { name: 'Start another report' }))
    await screen.findByRole('button', { name: /Report an incident/ })
    await fillReport('Ruiru to CBD')
    fireEvent.click(screen.getByRole('button', { name: 'Submit report' }))
    await screen.findByText('SS-TEST-4444')

    expect(fetchMock).toHaveBeenCalledTimes(2)
    expect(idempotencyKey(0)).not.toBe(idempotencyKey(1))
  })
})
