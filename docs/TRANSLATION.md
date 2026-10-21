# Languages and future translation

## Interface languages (implemented, M.2C)
The Flutter app ships English (`en`) and Kiswahili (`sw`) as bundled ARB files (`apps/mobile/lib/l10n/app_en.arb`, `app_sw.arb`), compiled by `flutter gen-l10n` into typed Dart. Everything works offline. The app follows the phone's language (Kiswahili if the phone uses it, otherwise English) and the home screen has a language switch. The choice is held in memory only, not saved. API values (incident types, timing, support options) and the helpline numbers are code, not translations, so the payload is identical in every language. The web app is English only.

To add a language: add `app_xx.arb` with the same keys, run `flutter gen-l10n`, and run `flutter test` (a test fails if any key or placeholder differs from English or if the emergency numbers are altered).

### Review status
The Kiswahili text was written by an AI assistant. The developer tested it on a physical phone (10 of 10 checks, below), which shows it is understandable and fits, but **an independent review by a fluent Kiswahili speaker has not happened and remains outstanding**. A native Kiswahili speaker, ideally one familiar with Kenyan matatu terms and safety or GBV support language, should review all of `app_sw.arb` before real users rely on it. Highest priority:
- Safety and emergency wording: `notEmergencyBody`, `dangerNote`, `confirmNotice`, the three `helpline*` entries (numbers must stay 999, 112 and 1195).
- Incident descriptions: `incidentDrivingDesc` ("overlapping" has no settled Kiswahili term; "kuovateki kwa hatari" is a guess), `incidentThreatsDesc`, `incidentTouchingLabel`/`Desc` (consent wording), `incidentHarassmentLabel`.
- Terms: "SACCO au mwendeshaji", "Namba ya usajili" for number plate, "stendi", "seva", "ripoti" vs "taarifa", "GBV" (kept as an acronym next to "ukatili wa kijinsia").
- Reassurance and limits: `errTimeout` (duplicate protection), `prototypeBody`, `codeNote`.
- Short labels that may not fit on small screens at large text sizes.

### Device validation (developer-confirmed, manual)
Redmi A5, 10 of 10 checks passed: language switching; translated report screens; categories understandable; safety wording; emergency numbers; long-text fit; large system font sizes; Quick Exit; TalkBack; draft kept when switching; successful synthetic submission to the local API. This is the developer's own testing on one phone, not a formal accessibility review or a linguistic review.

## Optional translation of user-written text (design only, not active)
Not implemented: no code (backend or app) calls any translation service, and the app does not send incident text anywhere except the report itself.

Planned shape, to be built only after review and an explicit decision:
- **Where:** a backend endpoint, for example `POST /api/translate`, never a model provider directly from the phone. No provider key ever lives in the Flutter app or web app.
- **Provider-independent:** the backend would hide providers behind one small interface: `translate(text, source, target) -> {translated_text, provider, model}`. Implementations could be OpenRouter (reusing the pattern in `assistant.py`) or a self-hosted open-source translation model. Provider and model come from backend environment variables separate from the assistant's (for example `TRANSLATION_PROVIDER`, `TRANSLATION_MODEL`), with no silent fallback to a different or paid model.
- **Client contract (to build with the feature, not before):** a small translator interface returning the original text, the translated text, both languages, and flags `aiGenerated = true` and `needsHumanReview = true`. No such code exists yet; an earlier unused interface was removed because nothing consumed it.
- **Privacy rules:** opt-in per piece of text, never automatic; the same redaction and length limits as the assistant; no logging of text; no storage; not applied to the structured report fields; the user's original wording is always kept and is what a report contains.
- **Labelling:** any translated text is shown as machine-generated and unreviewed, never as an official or verified translation, and must not be used for safety instructions or emergency wording.
- **Open questions:** rate limiting, cost, whether translation is useful for staff reading reports, and legal review of sending report text to a third-party provider.
