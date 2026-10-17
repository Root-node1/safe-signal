// No 0/O/1/I/L so the code is easy to read out or write down.
const ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'

export function newReferenceCode(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(8))
  const chars = Array.from(bytes, (b) => ALPHABET[b % ALPHABET.length])
  return `SS-${chars.slice(0, 4).join('')}-${chars.slice(4).join('')}`
}
