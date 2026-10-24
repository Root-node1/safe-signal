# M.4 Gap Analysis

**Status:** research only — no code, schema or dependency changes.
**Basis:** [M.4_ARCHITECTURE_AUDIT.md](M4_ARCHITECTURE_AUDIT.md). Every classification below cites the file that supports it.
**Purpose:** establish which M.4 capabilities already exist, which are half-built, which do not exist, and which cannot be judged from the repository.

---

## 1. Method and legend

| Status | Meaning |
|---|---|
| **IMPLEMENTED** | Present in code and covered by automated tests or directly verifiable behaviour. |
| **PARTIAL** | Present but incomplete: a material case, environment or condition is unhandled. |
| **MISSING** | No implementation found in the repository. |
| **UNVERIFIED** | Code exists but the claim cannot be confirmed from the repository alone (needs a device, a server, a provider or a founder decision). |

Priority areas, in the order requested: **reliability**, **privacy**, **retention**, **offline recovery**, **deployment readiness**. Gap IDs are stable references for the M.4 scope proposal.

---

## 2. Capability classification

### 2.1 Reliability

| Capability | Status | Evidence |
|---|---|---|
| Idempotent submission — duplicate prevention | IMPLEMENTED | `apps/backend/store.py:79-91`; `apps/backend/store_pg.py:48-75`; tests `apps/backend/tests/test_idempotency.py:29-49` |
| Conflicting-key detection (409) | IMPLEMENTED | `apps/backend/store.py:80-84`; `apps/backend/reports.py:55-58`; test `apps/backend/tests/test_idempotency.py:36-41` |
| Concurrent same-key safety | IMPLEMENTED | `apps/backend/store.py:79` (lock), `apps/backend/store_pg.py:60-72` (`ON CONFLICT DO NOTHING`); tests `apps/backend/tests/test_idempotency.py:44-49`, `apps/backend/tests/test_store_postgres.py:58-61` |
| Replay costs no rate-limit allowance | IMPLEMENTED | `apps/backend/store.py:71-72`; `apps/backend/store_pg.py:73-74`; test `apps/backend/tests/test_store_postgres.py:64-76` |
| Client-side key reuse on unchanged retry (web) | IMPLEMENTED | `apps/frontend/src/App.tsx:104-107` |
| Client-side key reuse on unchanged retry (mobile) | IMPLEMENTED | `apps/mobile/lib/api/submission_controller.dart:84-89` |
| Durable client-side deduplication across process restart | MISSING | Keys live in a `useRef` (`apps/frontend/src/App.tsx:37`) and in a `ChangeNotifier` field (`apps/mobile/lib/api/submission_controller.dart:65-66`); neither is persisted |
| Reference-code collision handling | IMPLEMENTED | `apps/backend/store_pg.py:78-88`; test `apps/backend/tests/test_store_postgres.py:78-82` |
| Graceful database-outage handling (generic 503) | IMPLEMENTED | `apps/backend/main.py:20-22`; `apps/backend/db.py:58-71`; test `apps/backend/tests/test_store_postgres.py:101-107` |
| Rate limiting on report creation | IMPLEMENTED | `apps/backend/ratelimit.py:48-60`, `:78-79`; tests `apps/backend/tests/test_ratelimit.py:39-73` |
| Rate limiting that survives restart / multi-worker | MISSING | Limiter state is per process (`apps/backend/ratelimit.py:4`, `:74-75`); documented at `docs/SECURITY.md:25` |
| Rate limiting on non-report routes | MISSING | Only report and admin paths are limited; documented at `docs/SECURITY.md:26` |
| Automatic retry after network failure | MISSING | Both clients surface the failure and wait for a tap (`apps/frontend/src/screens/NextStepScreen.tsx:60-78`; `apps/mobile/lib/api/submission_controller.dart:96-114`); stated in `apps/mobile/lib/api/submission_controller.dart:53` |
| Recovery of an unknown-outcome submission | PARTIAL | A retry with the same key resolves it, but only while the key survives in client memory; after a reload or process kill the outcome cannot be reconciled |
| Admin list pagination | MISSING | `GET /api/reports` returns every row (`apps/backend/reports.py:61-63`); documented at `docs/CHECKLIST.md:34` |
| Reference-code lookup for the reporter | MISSING | The confirmation screen states the code *"cannot be looked up yet"* (`apps/frontend/src/screens/ConfirmationScreen.tsx:91`); no such route exists |
| Legacy `/analyze` stub removed | RESOLVED | `apps/backend/main.py:87-92` (deprecated, returns 410 Gone); `docs/CHECKLIST.md:35` |

### 2.2 Privacy and security

| Capability | Status | Evidence |
|---|---|---|
| Admin authorisation with fail-closed shared secret | IMPLEMENTED | `apps/backend/reports.py:14-29`; tests `apps/backend/tests/test_reports.py:66-96` |
| Constant-time secret comparison | IMPLEMENTED | `apps/backend/reports.py:27` (`secrets.compare_digest`) |
| Per-address admin lockout | IMPLEMENTED | `apps/backend/ratelimit.py:62-67`, `:82-83`; test `apps/backend/tests/test_ratelimit.py:82-97` |
| Input validation with bounded free-text fields | IMPLEMENTED | `apps/backend/schemas.py:22-33`; mirrored by SQL `CHECK` constraints `apps/backend/migrations/001_init.sql:5-16` |
| Parameterised SQL | IMPLEMENTED | `apps/backend/store_pg.py:52-65`, `:102-107` |
| No report content, keys or addresses in logs | IMPLEMENTED | `apps/backend/db.py:95`; `apps/backend/store_pg.py:1`; `docs/SECURITY.md:12` |
| Phone number and GPS never transmitted | IMPLEMENTED | `apps/frontend/src/lib/api.ts:18`; `apps/mobile/lib/api/report_api.dart:62-74` |
| Backend never stores a contact number | IMPLEMENTED | `contact_provided` is accepted but not persisted (`apps/backend/schemas.py:31`, `:35-48`; `apps/backend/store.py:46-61`) |
| Incident drafts not persisted on the client | IMPLEMENTED | `apps/mobile/lib/models/report_draft.dart:1-3`; `apps/frontend/src/App.tsx:12`; `apps/mobile/pubspec.yaml:30-36` has no storage package |
| Browser storage limited to theme preference | IMPLEMENTED | `apps/frontend/src/lib/theme.ts:3`; the only `localStorage` use in the app |
| Assistant redaction and server-side key | IMPLEMENTED | `apps/backend/assistant.py` (`_PATTERNS`, `redact`); `docs/SECURITY.md:11` |
| Per-user admin identity and roles | MISSING | One shared secret only (`apps/backend/reports.py:17`); documented at `docs/SECURITY.md:23` |
| Audit logging of admin actions | MISSING | No audit table (`apps/backend/migrations/001_init.sql:2-29`) and no audit call sites; documented at `docs/SECURITY.md:23` |
| Consent capture screen | MISSING | `consentToShare` is hard-coded `false` on the web (`apps/frontend/src/lib/api.ts:34`) and `false` on mobile (`apps/mobile/lib/api/report_api.dart:73`); the field is stored but unused (`docs/SECURITY.md:17`) |
| Screenshot / recents-preview suppression | MISSING | No `FLAG_SECURE` and no `android:allowBackup` override anywhere in `apps/mobile` (verified by search) |
| TLS termination and reverse proxy | MISSING | No proxy configuration in the repository; `docs/SECURITY.md:24`, `docs/CHECKLIST.md:115` |
| Production CORS origin | RESOLVED | Configured from `SAFESIGNAL_CORS_ORIGINS` with dev default (`apps/backend/main.py:27-36`); production origin set in deployment env |
| Security response headers (CSP, HSTS, X-Frame-Options…) | RESOLVED | Middleware adds `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `X-XSS-Protection` on all responses; `Strict-Transport-Security` and `Content-Security-Policy` only when `SAFESIGNAL_ENV=production` (`apps/backend/main.py:47-63`) |
| Dependency and secret scanning in CI | MISSING | CI runs lint, build, ruff and pytest only (`.github/workflows/ci.yml:16-49`); `docs/SECURITY.md:27` |
| Published vulnerability contact | MISSING | `docs/SECURITY.md:33` states none is established |
| CAPTCHA or abuse controls beyond rate limiting | MISSING | `docs/SECURITY.md:26` |
| Legal review under Kenya's Data Protection Act | MISSING | `docs/SECURITY.md:29`, `docs/CHECKLIST.md:54` |
| Independent security review | MISSING | `docs/SECURITY.md:30` |
| Claim of anonymity/confidentiality in user-facing copy | MISSING | `docs/SECURITY.md:17` requires that the product not suggest anonymity; no privacy notice exists (`docs/CHECKLIST.md:123`) |

### 2.3 Retention and deletion

| Capability | Status | Evidence |
|---|---|---|
| Defined retention policy | MISSING | `apps/backend/DATABASE.md:62-64` — *"policy pending approval"*; `docs/CHECKLIST.md:47` |
| Automated deletion of expired reports | MISSING | No scheduled job exists anywhere in the repository |
| Idempotency-key expiry | MISSING | `idempotency_keys` has `created_at` (`apps/backend/migrations/001_init.sql:27`) but no cleanup path |
| Manual single-report deletion | IMPLEMENTED | `apps/backend/DATABASE.md:65` — `DELETE FROM reports WHERE code = '...'` |
| Deletion cascades to the idempotency key | IMPLEMENTED (side effect) | `ON DELETE CASCADE` (`apps/backend/migrations/001_init.sql:26`); consequence: a retry with that key afterwards creates a new report |
| Backup and restore procedure | PARTIAL | Documented (`apps/backend/DATABASE.md:40-51`) but never executed or tested on a server (`docs/CHECKLIST.md:46`) |
| Least-privilege database roles on a server | PARTIAL | Documented (`apps/backend/DATABASE.md:29-38`), not applied (`docs/CHECKLIST.md:45`) |
| Privacy notice for users | MISSING | `docs/CHECKLIST.md:123` |
| Data-subject access/correction path | MISSING | No endpoint, no process; the reporter holds only a reference code that cannot be looked up |

### 2.4 Offline recovery

| Capability | Status | Evidence |
|---|---|---|
| Offline detection and honest failure messaging (web) | IMPLEMENTED | `apps/frontend/src/screens/NextStepScreen.tsx:160-178` |
| Offline detection and honest failure messaging (mobile) | IMPLEMENTED | `apps/mobile/lib/api/report_api.dart:94-102`; `apps/mobile/lib/screens/review_screen.dart:167-176` |
| Draft retained after a failed submission | IMPLEMENTED | `apps/mobile/lib/api/submission_controller.dart:106-107` (state change only, draft untouched); `apps/mobile/test/integration/backend_timeout_retry_test.dart:93` |
| Retry after timeout proven end to end | IMPLEMENTED | `apps/mobile/test/integration/backend_timeout_retry_test.dart:86-113` (real process, frozen server, one stored report) |
| Durable local queue of pending reports | MISSING | No queue, no outbox, no persistence layer on either client |
| Automatic submission when connectivity returns | MISSING | Not implemented; `apps/mobile/lib/api/submission_controller.dart:53` states *"Nothing is retried automatically"* |
| Draft surviving app restart or process kill | MISSING | `apps/mobile/lib/app.dart:22-23` and `apps/mobile/lib/models/report_draft.dart:54-71` hold state in memory only |
| Draft surviving a page reload (web) | MISSING | `apps/frontend/src/App.tsx:12` — nothing persisted in the browser |
| Offline-first product decision recorded | PARTIAL | `docs/ROADMAP.md:7` lists offline work under M.3 as done, but the roadmap item refers to the offline reporting UI, not durable offline submission |

### 2.5 Deployment readiness

| Capability | Status | Evidence |
|---|---|---|
| PostgreSQL mode selectable and enforced in production | IMPLEMENTED | `apps/backend/db.py:26-29`; test `apps/backend/tests/test_db_config.py:17-25` |
| Explicit, locked, transactional migrations | IMPLEMENTED | `apps/backend/migrate.py:22-63` |
| Readiness endpoint | IMPLEMENTED | `apps/backend/main.py:66-75` (`health/live` and `health/ready`); `apps/backend/db.py:99-101` (`ping`) |
| Connection pooling | IMPLEMENTED | Pool config in `apps/backend/db.py:31-56`; pool opened `apps/backend/db.py:69-73` (size 1-20, default 5; SSL+max_lifetime in production) |
| CI runs on every push | IMPLEMENTED | `.github/workflows/ci.yml` |
| PostgreSQL service container in CI | MISSING | `.github/workflows/ci.yml` has no database service; the PostgreSQL suite self-skips (`apps/backend/tests/test_store_postgres.py:13-17`); `docs/CHECKLIST.md:43` |
| Flutter analyze/test in CI | MISSING | `.github/workflows/ci.yml:16-49`; `docs/CHECKLIST.md:107` |
| Frontend automated tests | MISSING | No test runner in `apps/frontend/package.json:6-11`; `docs/CHECKLIST.md:21` |
| End-to-end test of the report journey | MISSING | `docs/CHECKLIST.md:102` |
| Load testing | MISSING | `docs/CHECKLIST.md:103` |
| Server provisioning, systemd, monitoring, log hygiene | MISSING | `docs/CHECKLIST.md:112-117` |
| Reverse proxy, TLS, trusted forwarded headers | MISSING | `apps/backend/ratelimit.py:5-8`; `docs/CHECKLIST.md:115` |
| Production environment variables set | MISSING | `docs/CHECKLIST.md:116` |
| Release APK signing | MISSING | `docs/CHECKLIST.md:94-95`; `docs/ROADMAP.md:11` |
| Web build served with `VITE_PROTOTYPE=false` | PARTIAL | CI builds with that flag (`.github/workflows/ci.yml:31-33`), but no deployment exists |
| Administrator onboarding and runbook | MISSING | No runbook in the repository; `docs/CHECKLIST.md:118-124` |

### 2.6 Functional scope

| Capability | Status | Evidence |
|---|---|---|
| Web reporting journey (5 screens) | IMPLEMENTED | `apps/frontend/src/App.tsx:59-127`; no automated test (`docs/CHECKLIST.md:14`) |
| Flutter reporting journey (4 screens + welcome) | IMPLEMENTED | `apps/mobile/lib/screens/`; widget-tested (`docs/CHECKLIST.md:68`) |
| Kiswahili localisation, offline | IMPLEMENTED | `apps/mobile/lib/l10n/`; `docs/CHECKLIST.md:78` |
| Independent review of the Kiswahili copy | MISSING | `docs/CHECKLIST.md:79` — the text is AI-written, not reviewed by a fluent speaker |
| Trusted-contact alerting | MISSING | `apps/frontend/src/screens/NextStepScreen.tsx:33-45`; `apps/mobile/lib/models/report_draft.dart:29-30` |
| Partner check-in service | MISSING | Same sources |
| AI assistant on mobile | MISSING | `docs/CHECKLIST.md:93-94` |
| Admin response dashboard backed by real data | MISSING | `apps/frontend/src/screens/AdminScreen.tsx:23-24` uses mock data only |

---

## 3. Priority-ranked gaps

Ordered by risk if the product collects real reports, then by effort.

### P0 — must close before any real report is collected

| ID | Gap | Area | Evidence |
|---|---|---|---|
| G-01 | **No retention policy and no automated deletion.** Reports accumulate indefinitely, with no expiry of reports or idempotency keys. | Retention | `apps/backend/DATABASE.md:62-64` |
| G-02 | **No admin identity and no audit trail.** One shared secret grants full read of every report and the power to change any status; nothing records who did what. | Privacy | `apps/backend/reports.py:14-29` |
| G-03 | **No production deployment.** No TLS, no reverse proxy, no hardened server. CORS is configurable (`SAFESIGNAL_CORS_ORIGINS`) and security headers middleware is in place, but no reverse proxy or TLS is deployed. Reports would travel in cleartext over public networks. | Deployment | `apps/backend/main.py:39-63`; `docs/CHECKLIST.md:112-117`; `apps/backend/deploy/nginx.conf.example` |
| G-04 | **Rate limiting is per-process and ephemeral.** A restart clears all counters; behind a proxy all clients can share one bucket, which either throttles everyone or nobody. | Reliability / Deployment | `apps/backend/ratelimit.py:1-9`, `:42-67` |
| G-05 | **Client submission keys are volatile.** A reload (web) or process kill (mobile) loses the key, so an unknown-outcome submission cannot be reconciled and a duplicate can be created. | Reliability | `apps/frontend/src/App.tsx:37`; `apps/mobile/lib/api/submission_controller.dart:65-66` |
| G-06 | **PostgreSQL path is not exercised in CI.** The suite self-skips without a `TEST_DATABASE_URL`, so the production storage path can regress unnoticed. | Reliability | `apps/backend/tests/test_store_postgres.py:13-17`; `.github/workflows/ci.yml` |
| G-07 | **No legal basis or privacy notice.** Collection of sensitive incident data from real users has no published notice and no Data Protection Act review. | Privacy | `docs/SECURITY.md:29`; `docs/CHECKLIST.md:54`, `:124` |

### P1 — close before a supervised pilot

| ID | Gap | Area | Evidence |
|---|---|---|---|
| G-08 | **No durable offline recovery.** A user who loses connectivity mid-report, or whose app is killed, loses the draft entirely. | Offline | `apps/mobile/lib/app.dart:22-23`; `apps/frontend/src/App.tsx:12` |
| G-09 | **Screenshot and recents-preview exposure on Android.** No `FLAG_SECURE`; the recent-apps thumbnail can show the incident text the user just typed. | Privacy | `apps/mobile/lib/widgets/quick_exit_button.dart:9-10`; search of `apps/mobile` finds no `FLAG_SECURE` |
| G-10 | **No backup/restore verification and no least-privilege roles on a server.** The documented procedure has never been run. | Retention / Deployment | `apps/backend/DATABASE.md:29-38`, `:49-50`; `docs/CHECKLIST.md:45-46` |
| G-11 | **No admin UI behind real authentication.** The only dashboard is mock data behind a cosmetic flag. | Privacy | `apps/frontend/src/screens/AdminScreen.tsx:23-37`; `apps/frontend/src/lib/prototype.ts:1-6` |
| G-12 | **No frontend automated tests and no end-to-end journey test.** The web path is the least-verified surface in the product. | Reliability | `apps/frontend/package.json:6-11`; `docs/CHECKLIST.md:21`, `:102` |
| G-13 | **No Flutter CI job.** `flutter analyze` and `flutter test` never run automatically. | Reliability | `.github/workflows/ci.yml`; `docs/CHECKLIST.md:107` |
| G-14 | **Consent is stored but never captured.** `consentToShare` is hard-coded `false` on both clients, so the field in the database has no meaning. | Privacy | `apps/frontend/src/lib/api.ts:34`; `apps/mobile/lib/api/report_api.dart:73` |
| G-15 | **No key expiry or binding.** Idempotency keys accumulate forever, and any holder of a key can replay and read the original report. | Privacy / Retention | `apps/backend/migrations/001_init.sql:23-28`; `apps/backend/store_pg.py:32-37` |
| G-16 | **No admin list pagination.** Every report is returned in one response; the pattern does not scale and is a memory risk on the admin path. | Reliability | `apps/backend/reports.py:61-63` |

### P2 — schedule after the pilot

| ID | Gap | Area | Evidence |
|---|---|---|---|
| G-17 | CAPTCHA or abuse controls beyond IP rate limiting | Privacy | `docs/SECURITY.md:26` |
| G-18 | Rate limiting on non-report routes (assistant, health) | Reliability | `docs/SECURITY.md:26` |
| G-19 | Reference-code lookup so a reporter can check their report | Functional | `apps/frontend/src/screens/ConfirmationScreen.tsx:91` |
| G-20 | Remove the legacy `/analyze` stub | Resolved | `apps/backend/main.py:87-92` (returns 410 Gone) |
| G-21 | Load testing of report and assistant endpoints | Deployment | `docs/CHECKLIST.md:103` |
| G-22 | Release APK signing, versioning, signed release build | Deployment | `docs/CHECKLIST.md:94-95` |
| G-23 | Flutter assistant screen | Functional | `docs/CHECKLIST.md:93-94` |
| G-24 | Trusted-contact alerting and partner check-in | Functional | `apps/frontend/src/screens/NextStepScreen.tsx:33-45` |
| G-25 | Independent review of the Kiswahili copy | Privacy (trust) | `docs/CHECKLIST.md:79` |
| G-26 | Data-subject access and correction path | Privacy | no endpoint exists |
| G-27 | Distributed limiter when moving beyond a single worker | Deployment | `apps/backend/DATABASE.md:52-54` |
| G-28 | Remember the user's language choice | Functional | `docs/CHECKLIST.md:81` |

---

## 4. Dependency notes

- **G-06 before G-03.** A deployment is meaningless without the storage path under continuous test.
- **G-01 and G-10 before G-03.** Retention policy drives what must be backed up, how often, and for how long; the backup design follows the retention decision.
- **G-02 before G-11.** There is no point building an admin dashboard before there is a user identity to log in with and an audit trail to write to.
- **G-05 and G-08 are the same mechanism.** Persisting the draft and the key together is one change, not two, and it is the natural home for the offline-queue option evaluated in the scope proposal.
- **G-03 and G-04 interact.** The proxy decision (which client identity the limiter sees) must be settled before the limiter can be made correct for more than one worker.
- **G-07 is not purely a document task.** A privacy notice must describe what the product actually does; if retention changes (G-01) the notice changes with it.

---

## 5. UNVERIFIED register

These items could not be settled from the repository. They are neither claims of success nor claims of failure.

| ID | Item | Why it cannot be verified from the repository |
|---|---|---|
| U-01 | PostgreSQL behaviour on the target server version | Only a local PG 18 cluster was used; `docs/CHECKLIST.md:44` records that PG 16 or the chosen version is unverified |
| U-02 | PostgreSQL integration tests passing in CI | The suite requires `TEST_DATABASE_URL` with a `_test` database and no CI service provides one (`apps/backend/tests/test_store_postgres.py:13-17`) |
| U-03 | Backend suite pass/fail counts today | `docs/CHECKLIST.md:31` records 56/64 from a previous run; this audit did not execute the suite |
| U-04 | Flutter test pass/fail counts today | `docs/CHECKLIST.md:100` records 47 + 1 from a previous run; this audit did not execute `flutter test` |
| U-05 | Real-device behaviour of timeout/retry on the phone | The freeze procedure ran on a desktop, not the phone (`docs/CHECKLIST.md:90`) |
| U-06 | Whether the phone writes report text to storage or logcat | Only server logs were inspected (`docs/CHECKLIST.md:91`) |
| U-07 | Backup and restore on a real server | Documented but never executed (`docs/CHECKLIST.md:46`) |
| U-08 | Least-privilege roles on a real server | Documented but never created (`docs/CHECKLIST.md:45`) |
| U-09 | OpenRouter model id and one live request | `docs/CHECKLIST.md:61-62`; no live call has been made |
| U-10 | Whether any real incident data has ever been stored | Not determinable from the repository; `docs/SECURITY.md:17` warns that reports are sensitive regardless |
| U-11 | Whether a proxy in front of the backend overwrites `X-Forwarded-For` | No deployment exists yet (`apps/backend/ratelimit.py:5-8`) |
| U-12 | Legal position under Kenya's Data Protection Act | Requires a qualified reviewer (`docs/SECURITY.md:29`) |
| U-13 | Kiswahili copy quality | Requires a fluent speaker (`docs/CHECKLIST.md:79`) |
| U-14 | Browser and screen-reader behaviour of the web app | No automated or manual browser pass is recorded (`docs/CHECKLIST.md:19-20`) |
| U-15 | Whether a report submitted through the reference code can be traced back to a person | No device, account or phone number is stored today, but free-text fields could contain identifying details a user typed — this is a design judgement, not a code fact |
