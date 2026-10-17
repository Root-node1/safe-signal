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
