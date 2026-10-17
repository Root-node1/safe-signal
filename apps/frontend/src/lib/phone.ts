// Accepts 07xx / 01xx / +2547xx / 2541xx, spaces and dashes allowed.
export function isValidKenyanPhone(input: string): boolean {
  const cleaned = input.replace(/[\s-]/g, '')
  return /^(?:\+?254|0)[17]\d{8}$/.test(cleaned)
}
