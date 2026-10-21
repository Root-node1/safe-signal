import { describe, expect, it, vi } from 'vitest'

import { resolveSubmissionKey, type SubmissionKeyPolicy } from './submissionKeyPolicy'

describe('resolveSubmissionKey', () => {
  it('mints a key on the first call', () => {
    const newKey = vi.fn(() => 'key-1')
    const policy = resolveSubmissionKey(null, 'sig-1', newKey)
    expect(policy).toEqual({ key: 'key-1', signature: 'sig-1' })
    expect(newKey).toHaveBeenCalledTimes(1)
  })

  it('reuses the existing key while the signature is unchanged', () => {
    const current: SubmissionKeyPolicy = { key: 'key-1', signature: 'sig-1' }
    const newKey = vi.fn(() => 'key-2')
    const policy = resolveSubmissionKey(current, 'sig-1', newKey)
    expect(policy).toBe(current)
    expect(policy?.key).toBe('key-1')
    expect(newKey).not.toHaveBeenCalled()
  })

  it('mints a new key when the signature changes', () => {
    const current: SubmissionKeyPolicy = { key: 'key-1', signature: 'sig-1' }
    const newKey = vi.fn(() => 'key-2')
    const policy = resolveSubmissionKey(current, 'sig-2', newKey)
    expect(policy).toEqual({ key: 'key-2', signature: 'sig-2' })
    expect(policy?.key).not.toBe('key-1')
    expect(newKey).toHaveBeenCalledTimes(1)
  })

  it('mints a new key when there is no current policy, even for a known signature', () => {
    const newKey = vi.fn(() => 'key-3')
    const policy = resolveSubmissionKey(null, 'sig-1', newKey)
    expect(policy).toEqual({ key: 'key-3', signature: 'sig-1' })
    expect(newKey).toHaveBeenCalledTimes(1)
  })
})
