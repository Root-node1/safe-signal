# M.4 Architecture Audit

**Status:** research only — no code, schema or dependency changes.
**Scope:** the reporting path end to end (React web, Flutter Android, FastAPI, PostgreSQL) as it exists in `main` at commit `f291e6f`.
**Method:** direct reading of the source tree listed below. Claims marked *verified* were read directly from the referenced file; claims marked *unverified* are flagged in [M.4_GAP_ANALYSIS.md](M4_GAP_ANALYSIS.md).

---

## 1. System map

| Component | Path | Role |
|---|---|---|
| React web client | `apps/frontend` | Public reporting journey, admin mock screen, assistant modal |
| Flutter Android client | `apps/mobile` | Native reporting journey, Quick Exit, in-memory reporting state |
| FastAPI service | `apps/backend` | `POST /api/reports`, admin routes, assistant proxy, readiness |
| Storage | PostgreSQL 16+/local PG 18 | `reports` + `idempotency_keys` tables |
| Dev fallback storage | `apps/backend/store.py` | Process-memory lists; development only |

The two clients are independent. The web client and the Flutter client both call the same HTTP contract (`apps/backend/reports.py:35-58`) and both send an `Idempotency-Key` header. Neither client depends on the other's code.

---

## 2. React reporting flow

**Screens and state.** `apps/frontend/src/App.tsx` holds a discriminated-union screen state (`apps/frontend/src/App.tsx:13-18`) covering landing → incident type → details → next step → confirmation. The comment at `apps/frontend/src/App.tsx:12` states the rule plainly: *"State only. Nothing is persisted in the browser."* There is no draft persistence of any kind; reloading the page discards everything the user typed.

**Payload construction.** `buildPayload` (`apps/frontend/src/lib/api.ts:19-36`) assembles the camelCase body. The phone number and GPS coordinates are deliberately excluded (`apps/frontend/src/lib/api.ts:18`). `consentToShare` is hard-coded to `false` with the comment *"no consent screen yet"* (`apps/frontend/src/lib/api.ts:34`).

**Submission key generation.** `newSubmissionKey` (`apps/frontend/src/lib/api.ts:39-43`) produces a UUID v4 via `crypto.randomUUID`, with a `crypto.getRandomValues` fallback. It is random, not derived from report content.

**Key reuse across retries.** The client keeps the in-flight key in a ref: `const submission = useRef<{ sig: string; key: string } | null>(null)` (`apps/frontend/src/App.tsx:37`). On submit (`apps/frontend/src/App.tsx:99-111`) the payload is serialised to a signature; if the signature is unchanged the existing key is reused, if it changed a fresh key is minted:

```ts
const sig = JSON.stringify(payload)
if (submission.current?.sig !== sig) {
  submission.current = { sig, key: newSubmissionKey() }
}
```

This is what makes a retry after a timeout safe: the same payload reuses the same key, and the backend returns the original report instead of creating a second one. The ref is cleared only after success (`apps/frontend/src/App.tsx:109`) or on restart (`apps/frontend/src/App.tsx:122`), so a failed attempt keeps its key for the next tap.

**Transport and failure handling.** `createReport` (`apps/frontend/src/lib/api.ts:45-81`) posts with an 8-second `AbortController` timeout and converts an abort into an error named `TimeoutError`. `NextStepScreen.handleSubmit` (`apps/frontend/src/screens/NextStepScreen.tsx:60-78`) maps failures to a `network` or `timeout` banner and re-enables the button; a `submitting` guard blocks double taps (`apps/frontend/src/screens/NextStepScreen.tsx:61`, `:188`). The banner tells the user that tapping again is safe (`apps/frontend/src/screens/NextStepScreen.tsx:173`).

**Quick Exit and browser storage.** Quick Exit renames the document title and replaces the location with a neutral page (`apps/frontend/src/lib/quickExit.ts:4-7`); it is bound to the Escape key and a header button (`apps/frontend/src/components/SafeHeader.tsx:26-30`, `:56`). The only browser persistence in the app is the theme preference, stored under the key `safesignal-theme` (`apps/frontend/src/lib/theme.ts:3`). No incident data is written to `localStorage`, `sessionStorage`, cookies or IndexedDB.

**Admin screen.** `/#admin` renders only from mock data (`apps/frontend/src/screens/AdminScreen.tsx:23-24`, `apps/frontend/src/admin/mockReports.ts`) and is gated behind the cosmetic `PROTOTYPE` build flag (`apps/frontend/src/screens/AdminScreen.tsx:27-37`). The flag is explicitly documented as *not* an authorisation mechanism (`apps/frontend/src/lib/prototype.ts:1-6`).

---

## 3. Flutter reporting flow

**Ownership of state.** A single `SubmissionController` is created at app start (`apps/mobile/lib/app.dart:22-23`) and owns both the `ReportDraft` and the one logical submission. `ReportDraft` is a plain in-memory class whose header comment states it is *"Held in memory only; never written to disk or logs"* (`apps/mobile/lib/models/report_draft.dart:1-3`). The language choice is likewise not persisted (`apps/mobile/lib/app.dart:25-27`).

**Screens.** Report → support → review → confirmation:
- `apps/mobile/lib/screens/report_screen.dart` — timing, incident type, optional route/plate/SACCO/area; the fields write straight into the in-memory draft on every change (`apps/mobile/lib/screens/report_screen.dart:47-52`, `:188`).
- `apps/mobile/lib/screens/support_screen.dart` — support choice; two of the four API values are disabled, matching the web.
- `apps/mobile/lib/screens/review_screen.dart` — review + submit; the submit button is disabled while a submission is in flight (`apps/mobile/lib/screens/review_screen.dart:143-146`).
- `apps/mobile/lib/screens/confirmation_screen.dart` — shown only after a confirmed 2xx carrying a reference code (`apps/mobile/lib/screens/confirmation_screen.dart:10`, `:20-21`).

**Key generation and reuse.** `newIdempotencyKey` (`apps/mobile/lib/api/report_api.dart:131-138`) builds a UUID v4 from `Random.secure()`, explicitly *"Never derived from report content"*. The controller mints a key when there is none or when the payload signature changed, and otherwise reuses the held key (`apps/mobile/lib/api/submission_controller.dart:84-89`):

```dart
final signature = jsonEncode(body);
if (_key == null || _signature != signature) {
  _key = newIdempotencyKey();
  _signature = signature;
}
```

The key is dropped on success, on reset, and on a 409 key conflict so the next attempt uses a fresh one (`apps/mobile/lib/api/submission_controller.dart:99`, `:109-110`, `:132-135`). A monotonic ticket counter discards results that arrive after a reset mid-flight (`apps/mobile/lib/api/submission_controller.dart:90`, `:94`).

**Transport and failure handling.** `ReportApi.submit` (`apps/mobile/lib/api/report_api.dart:76-103`) posts to `${baseUrl}/api/reports` with a 10-second timeout, sending the same JSON contract and the `Idempotency-Key` header (`:87-90`). The base URL comes from `--dart-define=API_BASE_URL`; an empty value means the build is not connected to any server and nothing is ever sent (`apps/mobile/lib/api/report_api.dart:12`, `:60`). `_interpret` (`apps/mobile/lib/api/report_api.dart:105-125`) maps 201 → accepted, 409 → key conflict, 422 → validation failure, 429 → rate limited with `Retry-After`, and everything else to an unexpected response. Timeouts and socket failures surface as `SubmitNetworkFailure` (`apps/mobile/lib/api/report_api.dart:94-102`). Nothing is retried automatically; the user taps again and the unchanged draft reuses the key.

**Quick Exit.** `quickExit` (`apps/mobile/lib/widgets/quick_exit_button.dart:11-15`) resets the controller, pops to the first route and calls `SystemNavigator.pop()`. Its own doc comment states the limit: it *"cannot erase Android's recent-apps preview, screenshots, keyboard history, backups or anything else outside the app"* (`apps/mobile/lib/widgets/quick_exit_button.dart:9-10`).

**Android surface.** The release manifest declares only `INTERNET` (`apps/mobile/android/app/src/main/AndroidManifest.xml:2`); cleartext HTTP is enabled in the debug manifest only (`apps/mobile/android/app/src/debug/AndroidManifest.xml:9`). No `FLAG_SECURE` and no `android:allowBackup` override exist anywhere in `apps/mobile` (verified by search over the tree). `apps/mobile/pubspec.yaml` declares only `http` and `intl` as runtime dependencies — there is no local-storage package available today.

---

## 4. FastAPI reporting API

**App wiring.** `apps/backend/main.py` builds a FastAPI app whose lifespan calls `db.init()` and `db.close()` (`apps/backend/main.py:12-16`). `db.init()` raises when `SAFESIGNAL_ENV=production` and `DATABASE_URL` is missing, so production can never start on memory storage (`apps/backend/db.py:64-66`).

**Routes.**

| Method | Path | Auth | Source |
|---|---|---|---|
| POST | `/api/reports` | public | `apps/backend/reports.py:35-58` |
| GET | `/api/reports` | admin key | `apps/backend/reports.py:61-63` |
| PATCH | `/api/reports/{id}/status` | admin key | `apps/backend/reports.py:66-75` |
| POST | `/api/assistant/chat` | public | `apps/backend/assistant.py` |
| GET | `/health/live` | public | `apps/backend/main.py:66-68` |
| GET | `/health/ready` | public | `apps/backend/main.py:71-75` |
| POST | `/analyze` | public, deprecated stub (410) | `apps/backend/main.py:87-92` |

`POST /api/reports` accepts an optional `Idempotency-Key` header, validates it against `^[A-Za-z0-9_-]{16,64}$` (`apps/backend/reports.py:32`, `:43-44`) and returns 201 with the created report. A key reused with a different payload returns 409 with a fixed message that does not echo the payload (`apps/backend/reports.py:55-58`; asserted by `apps/backend/tests/test_idempotency.py:36-41`).

**Admin authorisation.** `require_admin` (`apps/backend/reports.py:14-29`) compares `X-Admin-Key` to `SAFESIGNAL_ADMIN_KEY` with `secrets.compare_digest`, fails closed when the expected key is unset/empty/whitespace, returns the same 401 for every failure, and applies a per-address failure lockout that is released on success (`apps/backend/reports.py:17-29`). It is one shared secret: there is no user identity, role or audit trail.

**Rate limiting.** An in-memory sliding-window limiter (`apps/backend/ratelimit.py:42-67`) charges 10 new reports per hour per client address by default (`apps/backend/ratelimit.py:78-79`) and 5 failed admin attempts per 15 minutes (`apps/backend/ratelimit.py:82-83`). Client identity is `request.client.host`; forwarding headers are deliberately ignored so they cannot be spoofed (`apps/backend/ratelimit.py:32-33`, asserted by `apps/backend/tests/test_ratelimit.py:75`). The limiter is per process, so it resets on restart and is shared by all clients behind a proxy that does not overwrite `X-Forwarded-For` (`apps/backend/ratelimit.py:1-9`).

**Data contract.** `ReportIn` (`apps/backend/schemas.py:22-33`) bounds every free-text field (`route`/`area` ≤ 120, `vehicle` ≤ 20, `sacco` ≤ 80) and restricts incident/timing/support to closed literal sets. `contact_provided` is accepted on input but is not part of `ReportOut` and is not stored (`apps/backend/schemas.py:31`, `:35-48`; `apps/backend/store.py:46-61`). The phone number itself is never transmitted by either client.

**Error handling.** A database failure is mapped to a generic 503 `{"detail": "Service temporarily unavailable"}` by an application exception handler (`apps/backend/main.py:22-24`) and by `db.DatabaseUnavailable` (`apps/backend/db.py:84-97`). Only the exception class name is logged (`apps/backend/db.py:95`). The pool is opened non-blocking so an unreachable database produces 503s rather than a startup crash (`apps/backend/db.py:72`). Pool configuration (timeout, sslmode, max_lifetime) for Neon is in `_pool_config` (`apps/backend/db.py:31-56`).

**CORS.** Configured from `SAFESIGNAL_CORS_ORIGINS` (comma-separated); defaults to
`http://localhost:5173` for development. Methods GET/POST/PATCH, headers
`Content-Type`, `X-Admin-Key`, `Idempotency-Key` (`apps/backend/main.py:39-44`).

---

## 5. PostgreSQL persistence

**Schema.** `apps/backend/migrations/001_init.sql` creates `reports` (`:2-20`) with `CHECK` constraints that mirror the Python literals exactly — a drift guard is asserted by `apps/backend/tests/test_db_config.py:47-63` — plus an index on `created_at DESC` (`:21`), and `idempotency_keys` (`:23-28`) keyed by the idempotency key with the same regex constraint as the API and a `report_id` foreign key with `ON DELETE CASCADE` (`:26`).

**Access layer.** `apps/backend/store_pg.py` is the PostgreSQL implementation behind `apps/backend/store.py`; all SQL is parameterised and report content is never logged (`apps/backend/store_pg.py:1`). `store.create` dispatches to it whenever `db.enabled()` (`apps/backend/store.py:75-78`), so the same HTTP contract serves both storage modes.

**Transactions.** `db.connection()` yields a pooled connection inside a transaction that commits on success and rolls back on any exception (`apps/backend/db.py:84-96`). Report insert, key insert and the rate-limit admission all happen in that single transaction (`apps/backend/store_pg.py:52-75`), so a rate-limited request stores nothing.

**Migrations.** `apps/backend/migrate.py` applies `migrations/*.sql` in order, each in its own transaction, recorded in `schema_migrations`, guarded by a PostgreSQL advisory lock (`apps/backend/migrate.py:22-63`). Migrations never run automatically (`apps/backend/db.py:1-5`; `apps/backend/DATABASE.md:5`). There is no automatic rollback — restore from a backup instead (`apps/backend/DATABASE.md:49-50`).

**Roles and operations.** Least-privilege role separation (`safesignal_owner` / `safesignal_app`) and nightly encrypted `pg_dump` guidance, plus backup script templates, are documented (`apps/backend/DATABASE.md:29-38`, `:49-50`) but are not yet applied to a server.

**Retention.** Not implemented. `apps/backend/DATABASE.md:62-64` states plainly: *"No automatic deletion of reports or idempotency keys yet; policy pending approval."* Operators can delete a single report by reference code. Because of the `ON DELETE CASCADE` on `idempotency_keys` (`apps/backend/migrations/001_init.sql:26`), deleting a report also erases its idempotency key, so a later retry with that key would create a new report rather than replay.

---

## 6. Idempotency and retry behaviour

**Fingerprinting.** When a key is present the payload is fingerprinted with SHA-256 over the canonical model JSON (`apps/backend/store.py:74`). The fingerprint is what distinguishes a genuine retry from a key reused with different content.

**In-memory mode.** The lookup, the rate-limit admission and the insert all happen under one `threading.Lock` (`apps/backend/store.py:79-91`). A matching key returns the stored original; a mismatching fingerprint raises `KeyConflict`, surfaced as 409 (`apps/backend/store.py:80-84`). Keys live exactly as long as the in-memory reports and are lost on restart (`apps/backend/reports.py:40-42`).

**PostgreSQL mode.** `_attempt` (`apps/backend/store_pg.py:48-75`):
1. Look the key up and, if found, resolve the stored original (`:50-51`).
2. Insert the report row (`:52-59`).
3. Insert the key with `ON CONFLICT (key) DO NOTHING RETURNING key` (`:60-65`). If the row was not returned, a concurrent request with the same key committed first: the transaction is rolled back and the winner's report is returned (`:66-72`).
4. Charge the rate limit last, inside the same transaction, so a rejection rolls everything back (`:73-74`).

A reference-code collision on the `reports_code_key` constraint is retried with a fresh code, up to five attempts (`apps/backend/store_pg.py:78-88`).

**Properties that hold today.**
- A replay of an unchanged report returns the original reference code and does not create a second row.
- A replay costs no rate-limit allowance — the limiter is only charged for genuinely new reports (`apps/backend/store.py:71-72`; `apps/backend/store_pg.py:73-74`; `apps/backend/tests/test_store_postgres.py:64-76`).
- Concurrent same-key requests cannot create two reports, in either storage mode.
- A key reused with a different payload returns 409 and never mutates the original.

**Limits of the current design.**
- The key is not bound to a client, an address or a session. Anyone presenting the correct key and payload receives the full original report, including route, area, vehicle and SACCO text. Keys are 16+ random characters, so this is a low-probability exposure, but it is by design unauthenticated.
- Both clients hold the key **in memory only**. A page reload (web) or a process kill (mobile) discards it, and the next attempt is treated as a new report. There is no durable deduplication window on the client side.
- In memory mode the server-side key is lost on restart, so a retry after a server restart creates a duplicate. In PostgreSQL mode it survives.
- Keys are never expired. `idempotency_keys` rows accumulate indefinitely alongside reports.

---

## 7. Existing automated tests

**Backend** — `apps/backend/tests/` (46 test functions across six files — 38 that run without a database and 8 PostgreSQL integration tests — plus parametrised cases; `docs/CHECKLIST.md:31` records 56 passing without a database and 64 with a test database).

| File | Covers |
|---|---|
| `test_idempotency.py` | First submission, same-key replay, conflicting payload → 409, **16 concurrent same-key requests create one report** (`:44-49`), malformed key rejection, no-key requests are not idempotent, reset clears keys (`:64-69`) |
| `test_store_postgres.py` | PostgreSQL create/list, replay + conflict, 16-way concurrent same-key (`:58-61`), replay costs no allowance, rejected store writes nothing, code-collision retry, status update and `acknowledged_at`, persistence across pool re-init (`:93-98`), outage → 503 without leaking the DSN (`:101-107`) |
| `test_reports.py` | Create/list, unknown incident type → 422, status update, unknown report → 404, unconfigured/empty/whitespace admin key denies everything, wrong credential denied, **every admin route is protected** (`:88-96`), public submission needs no key |
| `test_ratelimit.py` | 429 + `Retry-After`, window expiry, idempotent replay is free, conflict still 409 when full, concurrent requests cannot bypass the limit, spoofed forwarding headers ignored, admin lockout, success does not consume allowance, unconfigured key failures also limited |
| `test_db_config.py` | Production refuses to start without `DATABASE_URL`, dev falls back to memory, generic 503 mapping, SQL/Python literal drift guard |
| `test_assistant.py` | Provider success and redaction, missing key, sanitised provider errors, timeout/outage, malformed response, emergency short-circuit, validation and throttle |

The PostgreSQL suite is **skipped** unless `TEST_DATABASE_URL` names a database whose name ends in `_test` (`apps/backend/tests/test_store_postgres.py:13-17`). CI does not provide such a database, so these tests do not run on GitHub Actions (`.github/workflows/ci.yml:35-49`; `docs/CHECKLIST.md:43`).

**Flutter** — `apps/mobile/test/`, 10 test files plus a shared helper module, recorded as 47 tests plus 1 opt-in (`docs/CHECKLIST.md:100`): API contract and status mapping with a fake transport (`apps/mobile/test/report_api_test.dart`), widget tests for every screen, navigation, validation, draft retention on back-navigation, confirmation wording, 2× text scale, localisation parity in English and Kiswahili, Quick Exit with a mocked platform channel, and the widget components. The opt-in integration test (`apps/mobile/test/integration/backend_timeout_retry_test.dart`) starts a real uvicorn process, freezes it with `SIGSTOP` so the client genuinely times out, resumes it so the first request is accepted late, then retries the unchanged report and asserts the same key, the original reference code and exactly one stored report (`:86-113`). It requires `SAFESIGNAL_BACKEND_IT=1` and runs in-memory mode.

**React web** — **no automated tests.** `apps/frontend/package.json` has `dev`, `build`, `lint` and `preview` scripts and no test runner or test dependency (`:6-11`). The web submission path is therefore verified only indirectly, through the backend API tests (`docs/CHECKLIST.md:14`, `:21`).

**CI** — `.github/workflows/ci.yml` runs frontend lint + production build (`VITE_PROTOTYPE=false`) and backend `ruff check .` + `pytest -q`. There is no Flutter job, no PostgreSQL service container, and no end-to-end job (`.github/workflows/ci.yml:16-49`; `docs/CHECKLIST.md:105-108`).

---

## 8. Summary of what the audit confirms

- Idempotency is implemented end to end and is well tested: duplicate prevention, conflicting-key handling and concurrency are covered in both storage modes.
- PostgreSQL provides durable report and idempotency-key storage with enforced constraints and transactionally consistent rate limiting.
- The in-memory mode is explicitly a development fallback and is blocked in production by `SAFESIGNAL_ENV=production`.
- Both clients keep drafts and submission keys in memory only; neither persists incident data to disk or browser storage, and the browser's only stored value is the theme preference.
- Quick Exit clears what the app holds in memory on both platforms, but cannot reach OS-managed traces on Android, and neither platform suppresses screenshots or recent-apps previews.
- Admin access is a single shared secret with rate limiting and fail-closed behaviour; per-user identity and audit logging do not exist.
- Retention, automated deletion and deployment hardening are documented as outstanding and are not implemented.
