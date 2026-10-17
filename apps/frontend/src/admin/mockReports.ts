import type { Report } from './types'

// Prototype data only. Replaced by the backend later.
const NOW = Date.now()
const ago = (minutes: number): number => NOW - minutes * 60_000

export const MOCK_REPORTS: Report[] = [
  { id: 'r1', code: 'SS-7K3M-9PQ2', incident: 'threats', urgency: 'high', route: 'Ruiru to Nairobi', area: 'Githurai', vehicle: 'KDA 123A', sacco: 'Metro Line', support: 'check-in', consentToShare: true, status: 'Received', createdAt: ago(6), acknowledgedAt: null },
  { id: 'r2', code: 'SS-4TWE-HX8R', incident: 'harassment', urgency: 'medium', route: 'Ruiru to Nairobi', area: 'Kahawa', vehicle: 'KCB 840T', sacco: 'Metro Line', support: 'private', consentToShare: false, status: 'Reviewing', createdAt: ago(55), acknowledgedAt: ago(48) },
  { id: 'r3', code: 'SS-9NBC-2D5F', incident: 'harassment', urgency: 'medium', route: 'Ruiru to Nairobi', area: 'Roysambu', vehicle: '', sacco: 'Metro Line', support: 'trusted-contact', consentToShare: true, status: 'Contacted', createdAt: ago(190), acknowledgedAt: ago(172) },
  { id: 'r4', code: 'SS-2JXA-6MK4', incident: 'followed', urgency: 'high', route: 'Githurai to Nairobi', area: 'Thika Road', vehicle: '', sacco: '', support: 'check-in', consentToShare: true, status: 'Assigned', createdAt: ago(310), acknowledgedAt: ago(301) },
  { id: 'r5', code: 'SS-8PRD-3VQ7', incident: 'dangerous-driving', urgency: 'low', route: 'Kiambu to Nairobi', area: 'Kiambu Road', vehicle: 'KDD 552K', sacco: 'Kiambu Shuttle', support: 'support', consentToShare: false, status: 'Closed', createdAt: ago(1500), acknowledgedAt: ago(1470) },
  { id: 'r6', code: 'SS-5HGN-7TB9', incident: 'touching', urgency: 'high', route: 'Kiambu to Nairobi', area: 'Kiambu Road', vehicle: '', sacco: 'Kiambu Shuttle', support: 'check-in', consentToShare: true, status: 'Referred', createdAt: ago(2300), acknowledgedAt: ago(2285) },
  { id: 'r7', code: 'SS-6CMF-4YL2', incident: 'dangerous-driving', urgency: 'medium', route: 'Kiambu to Nairobi', area: 'Ruaka', vehicle: 'KDD 552K', sacco: 'Kiambu Shuttle', support: 'private', consentToShare: false, status: 'Action taken', createdAt: ago(2900), acknowledgedAt: ago(2880) },
]
