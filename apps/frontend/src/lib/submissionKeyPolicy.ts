// The React idempotency rule, extracted into a pure module so it can be tested
// without a DOM (design.md § 5.5, FR-6.4). Behaviour is unchanged: one key per
// logical submission, reused while the payload is unchanged, re-minted when the
// payload changes, cleared on success and on restart.

export type SubmissionKeyPolicy = { key: string; signature: string } | null

export function resolveSubmissionKey(
  current: SubmissionKeyPolicy,
  signature: string,
  newKey: () => string,
): SubmissionKeyPolicy {
  if (current && current.signature === signature) return current
  return { key: newKey(), signature }
}
