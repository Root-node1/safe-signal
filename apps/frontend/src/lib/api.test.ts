import { describe, expect, it, vi } from 'vitest'

import type { Details, NextChoice } from '../types'
import { buildPayload, createReport, newSubmissionKey } from './api'

const DETAILS: Details = {
  route: '  Ruiru to Nairobi  ',
  vehicle: '  kda 123a  ',
  sacco: '  Metro Line  ',
  where: '  Githurai  ',
  location: null,
}

const CHOICE: NextChoice = { step: 'private', contact: null }

describe('buildPayload', () => {
  it('produces the expected body, with the entered text trimmed', () => {
    expect(buildPayload('now', 'threats', DETAILS, CHOICE)).toEqual({
      incident: 'threats',
      timing: 'now',
      route: 'Ruiru to Nairobi',
      area: 'Githurai',
      vehicle: 'kda 123a',
      sacco: 'Metro Line',
      support: 'private',
      contactProvided: false,
      consentToShare: false,
    })
  })

  it('sends no phone number and no coordinates', () => {
    const payload = buildPayload('after', 'unsure', DETAILS, CHOICE)
    expect(Object.keys(payload)).not.toContain('phone')
    expect(Object.keys(payload)).not.toContain('location')
    expect(payload.consentToShare).toBe(false)
  })
})

describe('newSubmissionKey', () => {
  it('returns a 36-character UUID-shaped string', () => {
    const key = newSubmissionKey()
    expect(key).toHaveLength(36)
    expect(key).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
  })

  it('returns a different key every time', () => {
    const keys = new Set(Array.from({ length: 20 }, () => newSubmissionKey()))
    expect(keys.size).toBe(20)
  })
})

describe('createReport', () => {
  const payload = buildPayload('now', 'threats', DETAILS, CHOICE)

  it('aborts the request after 8 seconds and reports a timeout', async () => {
    vi.useFakeTimers()
    try {
      const fetchMock = vi.fn(
        (_url: string, init?: RequestInit) =>
          new Promise<Response>((_resolve, reject) => {
            init?.signal?.addEventListener('abort', () => {
              const error = new Error('The operation was aborted.')
              error.name = 'AbortError'
              reject(error)
            })
          }),
      )
      vi.stubGlobal('fetch', fetchMock)

      const pending = createReport(payload, 'key-1')
      const assertion = expect(pending).rejects.toMatchObject({
        name: 'TimeoutError',
        message: 'Request timed out while waiting for SafeSignal server.',
      })
      await vi.advanceTimersByTimeAsync(8000)
      await assertion
      expect(fetchMock.mock.calls[0][1]?.signal?.aborted).toBe(true)
    } finally {
      vi.useRealTimers()
      vi.unstubAllGlobals()
    }
  })

  it('maps an aborted request to a TimeoutError', async () => {
    const aborted = new Error('The operation was aborted.')
    aborted.name = 'AbortError'
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(aborted))
    try {
      await expect(createReport(payload, 'key-1')).rejects.toMatchObject({
        name: 'TimeoutError',
        message: 'Request timed out while waiting for SafeSignal server.',
      })
    } finally {
      vi.unstubAllGlobals()
    }
  })
})
