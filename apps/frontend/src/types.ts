export type IncidentType =
  | 'harassment'
  | 'threats'
  | 'touching'
  | 'followed'
  | 'dangerous-driving'
  | 'unsure'

export type Timing = 'now' | 'after'

export type Coords = { lat: number; lng: number }

// All optional. Held in React state only, never persisted.
export type Details = {
  route: string
  vehicle: string
  sacco: string
  where: string
  location: Coords | null
}

export const EMPTY_DETAILS: Details = {
  route: '',
  vehicle: '',
  sacco: '',
  where: '',
  location: null,
}

export type NextStep = 'private' | 'trusted-contact' | 'check-in' | 'support'

export type Contact = { name: string; phone: string }

// contact is the trusted person (trusted-contact) or her own number (check-in).
export type NextChoice = { step: NextStep; contact: Contact | null }
