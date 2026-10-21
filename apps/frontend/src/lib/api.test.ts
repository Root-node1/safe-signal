import { describe, expect, it } from 'vitest'

import type { Details, NextChoice } from '../types'
import { buildPayload, newSubmissionKey } from './api'

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
