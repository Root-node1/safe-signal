# SafeSignal M.4 — Scope and exclusion checklist (T-04)

**Task:** T-04 — *Audit the exclusions*.
**Requirements traced:** XR-1 … XR-16 (`requirements.md` § 7), plus SR-1.2, SR-2.2, SR-10.1, SR-10.2, PR-1.1, PR-1.2, PR-3.1, PR-3.2, PR-3.3, PR-4.1, PR-5.1, PR-5.2, PR-6.1, PR-6.2, PR-10.1, PR-10.2, PR-11.2, RR-5.2. PR-4.2 (no contact is collected) is not in the task's list but is checked here as well, because it is the same contact-collection family as PR-1.2 and PR-4.1.
**Documents checked against the code:** `docs/PRIVACY.md` (T-01), `docs/RETENTION.md` (T-02), `docs/SECURITY.md`, `docs/API.md`, `docs/CHECKLIST.md`.
**Date of the audit:** 21 October 2026.
**Repository state at the time of the audit:** `HEAD` = `f291e6f` (M.3), with the T-01/T-02/T-03 documents uncommitted.

---

## 1. What this task is

M.4 is a reliability and privacy milestone with a deliberately narrow scope. `requirements.md` § 7
lists sixteen things the milestone must **not** do, because the pilot is a supervised, short,
Kenyan commuter-safety pilot and not a social network, a dispatch service or a location tracker.

A written list of exclusions is only worth something if somebody checks it. This document is that
check:

1. every exclusion has a **recorded search**, a **result** and a **file-and-line citation**;
2. the privacy notice and the retention record are checked **against the code**, claim by claim;
3. every place where the documentation, the code and the user-facing text **disagree** is listed as
   an exception with an explanation and a task to resolve it;
4. the machine-checkable half of the audit is **scripted** (§ 7), so a later change re-opens it.

### 1.1 Result vocabulary

| Result | Meaning |
|---|---|
| **HOLDS** | The search was run and the excluded behaviour is absent. |
| **HOLDS — NOTE** | The excluded behaviour is absent, but the same search surfaced an adjacent inaccuracy. The note is recorded in § 6. |
| **EXCEPTION** | The excluded behaviour is present, or a document contradicts the code. Every exception is in § 6 with a resolution task. |
| **OPEN — DECISION** | The check cannot be completed until a founder or legal decision is made. No decision is made here. |

### 1.2 What this task did not do

- It did not change any application code, any dependency, any infrastructure, and it did not
  activate, schedule or enable any retention or deletion behaviour.
- It did not change `docs/PRIVACY.md` or `docs/RETENTION.md`. Those are approved T-01 and T-02
  deliverables, and the drift found in them is recorded here as exceptions instead.
- It did not decide, re-decide or narrow any open founder or legal decision (D-A … D-J, D-E).
- It did not begin T-05, and it did not touch the CI workflow files.

---

## 2. The sixteen exclusions

### XR-1 — No public report listing or lookup

**Requirement:** the server exposes no endpoint that lists reports or looks up a report by code to
a non-admin client.

**Search performed:** enumerated every registered route on the FastAPI app, including the included
routers, and asserted the admin gate on each one; then called `GET /api/reports` without an admin
key; then searched the route table for a code-shaped path parameter.

**Result: HOLDS.** The public surface is `POST /api/reports` only. `GET /api/reports` and
`PATCH /api/reports/{report_id}/status` are both gated by `require_admin`, which fails closed when
`SAFESIGNAL_ADMIN_KEY` is unset, empty or whitespace, and compares the key in constant time.
No route resolves a reference code; a code is written to the reporter and is never an input.

**Evidence**

| Fact | Evidence |
|---|---|
| Router prefix `/api/reports` | `apps/backend/reports.py:11` |
| Fail-closed admin gate, constant-time compare | `apps/backend/reports.py:14`, `apps/backend/reports.py:27` |
| `POST /api/reports` — public, no auth dependency | `apps/backend/reports.py:35`, `apps/backend/reports.py:39` |
| `GET /api/reports` — admin-gated | `apps/backend/reports.py:61` |
| `PATCH /api/reports/{report_id}/status` — admin-gated | `apps/backend/reports.py:66` |
| Unauthenticated listing returns 401 | `apps/backend/reports.py:28` |
| No code lookup route | `apps/backend/reports.py:11` (route table has no `{code}` parameter) |
| Reference code is generated, never accepted | `apps/backend/store.py:30`, `apps/backend/store.py:32` |
| Documented behaviour matches | `docs/API.md:11`, `docs/API.md:12`, `docs/API.md:13` |

### XR-2 — The `/analyze` stub is not wired into any client

**Requirement:** the prototype stub endpoint is not called by the web app, the Android app or the
backend itself.

**Search performed:** searched both client source trees for the string `/analyze`; confirmed the only
*code* occurrence in the repository is the route definition itself (the API reference and the
development checklist also name it, as a stub to remove).

**Result: HOLDS.** `POST /analyze` returns a fixed, hard-coded response. It is documented as a
legacy stub in the API reference, and it is listed as an open cleanup item in the development
checklist. It is not a client of the reports store, so it cannot expose report content.

**Evidence**

| Fact | Evidence |
|---|---|
| Stub route and its fixed response | `apps/backend/main.py:38`, `apps/backend/main.py:41` |
| Documented as a legacy stub | `docs/API.md:15` |
| Tracked for removal | `docs/CHECKLIST.md:35` |
| No client call | no match in `apps/frontend/src` or `apps/mobile/lib` |

### XR-3 — No push notifications

**Requirement:** nothing sends a push notification.

**Search performed:** compared the resolved dependency sets of both clients against the approved
lists, and searched for notification transports.

**Result: HOLDS.** The web app depends on React, React DOM and Tailwind only; the Android app on
Flutter, `flutter_localizations`, `http` and `intl`. Neither contains a messaging or notification
package, and the backend contains no notification code.

**Evidence**

| Fact | Evidence |
|---|---|
| Web runtime dependencies | `apps/frontend/package.json:12` |
| Android dependencies | `apps/mobile/pubspec.yaml:30` |
| No messaging package in the backend | `apps/backend/requirements.txt:1` |
| No notification permission requested | `apps/mobile/android/app/src/main/AndroidManifest.xml:2` |

### XR-4 — No background location

**Requirement:** the app does not collect location in the background.

**Search performed:** read the Android manifest and listed every declared permission; searched both
clients for location APIs.

**Result: HOLDS.** The release manifest declares exactly one permission, `android.permission.INTERNET`
(`apps/mobile/android/app/src/main/AndroidManifest.xml:2`), and declares no `<service>`. The debug
manifest adds no permission either, only cleartext traffic for local development
(`apps/mobile/android/app/src/debug/AndroidManifest.xml:9`).

**Evidence**

| Fact | Evidence |
|---|---|
| Single permission in the release manifest | `apps/mobile/android/app/src/main/AndroidManifest.xml:2` |
| No service component | `apps/mobile/android/app/src/main/AndroidManifest.xml:8` |
| Debug manifest adds cleartext only | `apps/mobile/android/app/src/debug/AndroidManifest.xml:9` |
| Profile manifest adds no permission | `apps/mobile/android/app/src/profile/AndroidManifest.xml:6` |

### XR-5 — No on-device vision, MediaPipe or image analysis

**Requirement:** the app does not process camera images or video.

**Search performed:** searched both dependency sets for any vision or MediaPipe package.

**Result: HOLDS.** No such package exists in either client. The only image-like asset in the
repository is the web app's favicon.

**Evidence**

| Fact | Evidence |
|---|---|
| Web dependencies | `apps/frontend/package.json:12` |
| Android dependencies | `apps/mobile/pubspec.yaml:30` |
| No camera permission | `apps/mobile/android/app/src/main/AndroidManifest.xml:2` |

### XR-6 — No Firebase, Crashlytics or third-party crash reporting

**Requirement:** no crash-reporting or analytics service is wired in.

**Search performed:** searched both dependency sets and the Android tree for Firebase, Crashlytics
and configuration files.

**Result: HOLDS.** No Firebase package, no `google-services.json`, and no crash-reporting service.

**Evidence**

| Fact | Evidence |
|---|---|
| Web dependencies | `apps/frontend/package.json:12` |
| Android dependencies | `apps/mobile/pubspec.yaml:30` |
| No Firebase configuration file | `apps/mobile/android/app/src/main/AndroidManifest.xml:1` (no plugin, no service) |

### XR-7 — No account creation, sign-in or user identity

**Requirement:** the pilot adds no account system, sign-in, or per-user identity.

**Search performed:** enumerated the route table for account-shaped paths; searched both clients for
credential handling; searched the server schema for credential fields.

**Result: HOLDS.** The route table has no login, registration or account path. No client handles a
password, a session or an identity. The server's request model has no user field: a report is
created without an account.

**Evidence**

| Fact | Evidence |
|---|---|
| Public report creation needs no credential | `apps/backend/reports.py:35`, `apps/backend/reports.py:39` |
| Server request model has no user field | `apps/backend/schemas.py:22` |
| Documented as "no account is required" | `apps/frontend/src/screens/LandingScreen.tsx:260`, `apps/mobile/lib/l10n/app_en.arb:11` |

### XR-8 — No admin user interface is added or enabled

**Requirement:** M.4 does not add or enable an admin interface.

**Search performed:** read the admin screen and the admin data module; searched for any network
call in the admin code; confirmed the build-time gate.

**Result: HOLDS — NOTE.** No admin interface was added by M.4, and none is enabled in a production
build: the prototype screen is gated on `VITE_PROTOTYPE` and renders mock data only, with no network
call. The screen predates M.4 (it is M.3 prototype work) and the "not available" branch is what a
production build shows.

**Evidence**

| Fact | Evidence |
|---|---|
| Admin screen renders mock data | `apps/frontend/src/screens/AdminScreen.tsx:3`, `apps/frontend/src/screens/AdminScreen.tsx:23` |
| No network call in the admin screen | `apps/frontend/src/screens/AdminScreen.tsx:22` (no `fetch`) |
| Production build hides it | `apps/frontend/src/screens/AdminScreen.tsx:28`, `apps/frontend/src/lib/prototype.ts:6` |
| Mock data is synthetic | `apps/frontend/src/admin/mockReports.ts:3` |
| Tracked as "real admin UI" still to do | `docs/CHECKLIST.md:23` |

**NOTE:** the prototype admin screen displays a *share consent* state, including mock rows with
consent given, that no client can produce. It is mock data in a screen that a production build
replaces with "Not available", but the panel would misinform anyone who reads it as a real report
view. Recorded as exception **C-10**.

### XR-9 — No dispatch, no SMS, no automated contact

**Requirement:** the app does not dispatch anyone, send an SMS, or place a call.

**Search performed:** searched both dependency sets and both client trees for messaging, telephony
and dispatch code; read the emergency paths.

**Result: HOLDS.** Nothing in the stack can send a message or place a call. The emergency path is
"show the number, the user dials": the web app renders helpline cards and the Android app shows the
same three numbers, with text that says SafeSignal cannot send help.

**Evidence**

| Fact | Evidence |
|---|---|
| Helpline numbers are data, not a dispatch | `apps/frontend/src/lib/support.ts:4`, `apps/mobile/lib/models/report_draft.dart:39` |
| "SafeSignal does not dispatch emergency units" | `apps/frontend/src/screens/NextStepScreen.tsx:213` |
| "SafeSignal does not contact police or anyone else" | `apps/mobile/lib/l10n/app_en.arb:13` |
| Two of the four support options are unavailable | `apps/frontend/src/screens/NextStepScreen.tsx:37`, `apps/mobile/lib/models/report_draft.dart:29` |
| No telephony or messaging dependency | `apps/mobile/pubspec.yaml:30` |

### XR-10 — No map view and no incident map

**Requirement:** the app does not add a map of incidents or a map view.

**Search performed:** searched both dependency sets and both client trees for map SDKs and map
components.

**Result: HOLDS.** No map package, no map component, and no incident list that could be rendered
on a map.

**Evidence**

| Fact | Evidence |
|---|---|
| Web dependencies | `apps/frontend/package.json:12` |
| Android dependencies | `apps/mobile/pubspec.yaml:30` |
| No map component in the web app | `apps/frontend/src/screens/AdminScreen.tsx:22` (no map import) |

### XR-11 — No Cloud Messaging or push transport

**Requirement:** the backend does not connect to a push transport.

**Search performed:** searched the backend for messaging transports and the Android app for
messaging packages.

**Result: HOLDS.** The backend's only outbound call is the assistant's call to the configured
OpenRouter-compatible endpoint, and it is made from a redacted, in-memory conversation with nothing
persisted.

**Evidence**

| Fact | Evidence |
|---|---|
| Backend dependencies | `apps/backend/requirements.txt:1` |
| The only outbound provider call | `apps/backend/assistant.py:112`, `apps/backend/assistant.py:123` |
| No messaging package on Android | `apps/mobile/pubspec.yaml:30` |

### XR-12 — The backend dependency list is unchanged

**Requirement:** M.4 does not add a backend dependency.

**Search performed:** parsed `requirements.txt` and `requirements-dev.txt` and compared them with
the approved lists.

**Result: HOLDS.** The runtime set is unchanged: `fastapi`, `pydantic`, `starlette`, `uvicorn`,
`psycopg`. The development set is `pytest`, `httpx`, `ruff`. Both files are unchanged relative to
`HEAD` (`git diff HEAD -- apps/backend/requirements.txt` is empty).

**Evidence**

| Fact | Evidence |
|---|---|
| Runtime dependencies | `apps/backend/requirements.txt:1` |
| Development dependencies | `apps/backend/requirements-dev.txt:1` |
| Nothing added by M.4 | `apps/backend/requirements.txt:5` (last line is `psycopg`) |

### XR-13 — No column was added to `reports`

**Requirement:** M.4 adds no column to the `reports` table.

**Search performed:** parsed `migrations/001_init.sql` and compared the column set with the one
documented in the privacy notice.

**Result: HOLDS.** The table has exactly the thirteen documented columns, and the only other table
is `idempotency_keys`, with the four columns the retention record describes.

**Evidence**

| Fact | Evidence |
|---|---|
| Table definition | `apps/backend/migrations/001_init.sql:2` |
| `consent_to_share` | `apps/backend/migrations/001_init.sql:14` |
| `status` and its allowed values | `apps/backend/migrations/001_init.sql:15` |
| `created_at` and its index | `apps/backend/migrations/001_init.sql:17`, `apps/backend/migrations/001_init.sql:21` |
| `idempotency_keys` and the cascade | `apps/backend/migrations/001_init.sql:23`, `apps/backend/migrations/001_init.sql:26` |
| Documented field list | `docs/PRIVACY.md:169` |
| Only one migration file exists | `apps/backend/migrations/001_init.sql:1` |

### XR-14 — No separate table for staff, operators or admin identities

**Requirement:** M.4 adds no table for staff, operators or admin identities.

**Search performed:** listed every table created by the schema.

**Result: HOLDS.** The schema creates exactly two tables: `reports` and `idempotency_keys`. There is
no operator, staff or identity table. The only other table in the system is `schema_migrations`,
created by the migration runner as bookkeeping and containing a version string and a timestamp.

**Evidence**

| Fact | Evidence |
|---|---|
| The two tables | `apps/backend/migrations/001_init.sql:2`, `apps/backend/migrations/001_init.sql:23` |
| `schema_migrations` is a migration ledger | `apps/backend/migrate.py:31` |
| Admin identity is a shared key, not a table | `apps/backend/reports.py:17` |
| No audit table for operators | `apps/backend/migrations/001_init.sql:1` |

### XR-15 — No new admin endpoint exposes report content to a non-admin client

**Requirement:** M.4 does not add an admin endpoint that exposes report content to a non-admin
client.

**Search performed:** enumerated the route table; asserted that every `/api/reports` route other
than `POST` requires the admin gate; checked that the assistant route cannot reach the store.

**Result: HOLDS.** The route table is unchanged from before M.4: one public report creation, one
admin-gated list, one admin-gated status update, one public assistant chat, the readiness probe and
the legacy stub. The assistant module does not import the store at all, so it cannot read reports.

**Evidence**

| Fact | Evidence |
|---|---|
| Route table | `apps/backend/main.py:59`, `apps/backend/main.py:60` |
| Admin gate on the list | `apps/backend/reports.py:61` |
| Admin gate on the status update | `apps/backend/reports.py:66` |
| The assistant never touches the store | `apps/backend/assistant.py:1` (module imports) |
| No new endpoint in the API reference | `docs/API.md:7` |

### XR-16 — The assistant screen is not part of the Android app

**Requirement:** the assistant screen is not added to the mobile app.

**Search performed:** searched the Android source tree for assistant files and for calls to the
assistant endpoint.

**Result: HOLDS.** The Android app has no assistant screen, no assistant service and no call to
`/api/assistant`. The assistant is a web-only feature, and the Android roadmap records the screen
as still to do.

**Evidence**

| Fact | Evidence |
|---|---|
| No assistant file in the Android app | `apps/mobile/lib/api/report_api.dart:1` (the only API module) |
| No assistant call | `apps/mobile/lib/api/report_api.dart:81` (posts only to `/api/reports`) |
| Assistant screen still to do | `docs/CHECKLIST.md:94` |

---

## 3. The other requirements in T-04's scope

| Requirement | Check performed | Result | Evidence |
|---|---|---|---|
| **SR-1.2** No new admin endpoint exposes report content to a non-admin client | Route enumeration, admin-gate assertion, assistant/store separation | HOLDS | `apps/backend/reports.py:61`, `apps/backend/reports.py:66`, `apps/backend/assistant.py:1` |
| **SR-2.2** The prototype admin screen keeps using mock data only | Read the screen and the mock module; searched for network calls | HOLDS | `apps/frontend/src/screens/AdminScreen.tsx:3`, `apps/frontend/src/admin/mockReports.ts:3` |
| **SR-10.1** Idempotency key format | Compared the accepted pattern with the documented one | HOLDS | `apps/backend/reports.py:32`, `apps/backend/migrations/001_init.sql:24`, `docs/API.md:19` |
| **SR-10.2** The same key with a different payload is rejected with 409 | Read the conflict path in both stores and the HTTP mapping | HOLDS | `apps/backend/store.py:82`, `apps/backend/store_pg.py:43`, `apps/backend/reports.py:55`, `docs/API.md:36` |
| **PR-1.1** No account is required to submit a report | Route dependency inspection; client payload builders | HOLDS | `apps/backend/reports.py:35`, `apps/frontend/src/lib/api.ts:19`, `apps/mobile/lib/api/report_api.dart:64` |
| **PR-1.2** The phone number is never accepted or stored | Searched the server schema, the response model and the table for phone, e-mail, name and ID fields | HOLDS | `apps/backend/schemas.py:22`, `apps/backend/schemas.py:35`, `apps/backend/migrations/001_init.sql:2` |
| **PR-3.1** No consent screen is added in either client | Searched the user-facing screens of both clients for a consent control | HOLDS | `apps/frontend/src/lib/api.ts:34`, `apps/mobile/lib/api/report_api.dart:73` |
| **PR-3.2** `consentToShare` is hard-coded false and never a user control | Read both payload builders; searched the user-facing screens | HOLDS — NOTE | `apps/frontend/src/lib/api.ts:34`, `apps/mobile/lib/api/report_api.dart:73` |
| **PR-3.3** The two unavailable support options stay unavailable | Read the option lists in both clients | HOLDS | `apps/frontend/src/screens/NextStepScreen.tsx:37`, `apps/frontend/src/screens/NextStepScreen.tsx:44`, `apps/mobile/lib/models/report_draft.dart:29`, `apps/mobile/lib/models/report_draft.dart:30` |
| **PR-4.1** No GPS coordinates are collected | Searched both clients for location APIs; read the manifests | HOLDS | `apps/frontend/src/lib/api.ts:18`, `apps/mobile/android/app/src/main/AndroidManifest.xml:2` |
| **PR-4.2** No contact is collected | Searched the web client for a non-null contact assignment; read the mobile draft model | HOLDS | `apps/frontend/src/screens/NextStepScreen.tsx:68`, `apps/mobile/lib/models/report_draft.dart:54` |
| **PR-5.1** No public endpoint lists reports | Route enumeration | HOLDS | `apps/backend/reports.py:61` |
| **PR-5.2** No real report data is committed to the repository | Read every sample payload in the repository | HOLDS | `apps/frontend/src/admin/mockReports.ts:7`, `apps/backend/tests/test_reports.py:18` |
| **PR-6.1** No analytics, advertising or tracking library | Compared both dependency sets with the approved lists | HOLDS | `apps/frontend/package.json:12`, `apps/mobile/pubspec.yaml:30` |
| **PR-6.2** No report content in logs | Read every logging and console-output statement in the backend; searched both clients for console output | HOLDS | `apps/backend/assistant.py:154`, `apps/backend/db.py:70`, `apps/backend/migrate.py:84` |
| **PR-10.1** The reference code is copied out of the app | Read the confirmation screen | HOLDS | `apps/mobile/lib/screens/confirmation_screen.dart:84` |
| **PR-10.2** The clipboard is never read or cleared by the app | Searched the Android app for clipboard reads and clears | HOLDS | `apps/mobile/lib/screens/confirmation_screen.dart:84` (write only) |
| **PR-11.2** No metadata field is added to `reports` | Parsed the table definition | HOLDS | `apps/backend/migrations/001_init.sql:2` |
| **RR-5.2** No routine deletion of idempotency keys is added | Searched the backend for delete statements, schedulers and periodic jobs | HOLDS | `apps/backend/migrations/001_init.sql:23` (no expiry column), `apps/backend/DATABASE.md:50` |

**NOTE on PR-3.2.** The *clients* satisfy PR-3.2: both hard-code the flag to `false`. The *server*
does not force it to `false` — it stores whatever a client sends
(`apps/backend/store_pg.py:52`) and returns it (`apps/backend/schemas.py:45`), which
`docs/API.md:32` describes accurately as "stored; default false". The privacy notice's wording
("always `false`") is therefore stronger than the implementation. Recorded as exception **C-3**; the
field itself is governed by open decision **D-D** and is not changed here.

---

## 4. The privacy notice and the retention record, checked against the code

Each claim below was read in the document and then checked in the implementation.

### 4.1 `docs/PRIVACY.md` (T-01)

| # | Claim in the notice | Checked against | Result |
|---|---|---|---|
| 1 | The web app writes only `safesignal-theme` to browser storage | `apps/frontend/src/lib/theme.ts:3`, `apps/frontend/src/lib/theme.ts:28` — the only storage calls in the whole web app | **HOLDS** |
| 2 | The Android app writes nothing about the report to the device | No storage package in `apps/mobile/pubspec.yaml:30`; no file write in the app; the draft is in memory only (`apps/mobile/lib/api/submission_controller.dart:115`) | **HOLDS** |
| 3 | Android's automatic backup is not switched off for this app | `apps/mobile/android/app/src/main/AndroidManifest.xml:4` — no `android:allowBackup` attribute, so the platform default stands | **HOLDS** (the notice is correct, and T-22 will change this) |
| 4 | The clipboard is written, never read or cleared | `apps/mobile/lib/screens/confirmation_screen.dart:84` writes; no read or clear anywhere | **HOLDS** |
| 5 | No GPS coordinates are read | No location API in either client; no location permission | **HOLDS** |
| 6 | The phone number is never sent to the server | `apps/frontend/src/lib/api.ts:18` (explicit comment) and `apps/mobile/lib/api/report_api.dart:63`; neither payload has a phone field | **HOLDS** |
| 7 | The server stores the fields listed in § 6 | `apps/backend/migrations/001_init.sql:2` — exactly the thirteen documented columns, no more, no fewer | **HOLDS** |
| 8 | The timestamp is millisecond precision | `apps/backend/store.py:42`, `apps/backend/store_pg.py:13` | **HOLDS** |
| 9 | The assistant sends the message and up to six earlier turns, redacted, and stores nothing | `apps/backend/assistant.py:23`, `apps/backend/assistant.py:76`, `apps/backend/assistant.py:148`, `apps/backend/assistant.py:54` | **HOLDS** |
| 10 | The assistant does not promise anonymity or confidentiality | The server prompt forbids it (`apps/backend/assistant.py:36`) — but the same prompt describes the product as "anonymous-by-design" (`apps/backend/assistant.py:32`) | **EXCEPTION — C-2** |
| 11 | A deleted report is removed from the live database but may remain in an older backup | `apps/backend/migrations/001_init.sql:26` (cascade) and `apps/backend/DATABASE.md:36` (backups) | **HOLDS** |
| 12 | The retention period is a marked placeholder | `docs/PRIVACY.md:267` | **HOLDS** |
| 13 | Deleting by reference code also removes the idempotency key | `apps/backend/migrations/001_init.sql:26` (`ON DELETE CASCADE`) | **HOLDS** |
| 14 | The admin can list reports and update a status; no public lookup | `apps/backend/reports.py:61`, `apps/backend/reports.py:66` | **HOLDS** |
| 15 | No report content, key, phone number or address is written to a log | `apps/backend/assistant.py:154`, `apps/backend/db.py:70` — the only two log calls, both a code or a class name; the only other output is the migration CLI's own error message (`apps/backend/migrate.py:84`) | **HOLDS** |

### 4.2 `docs/RETENTION.md` (T-02)

| # | Claim in the record | Checked against | Result |
|---|---|---|---|
| 1 | No automatic deletion of reports or idempotency keys exists | `apps/backend/DATABASE.md:50`; no delete statement, scheduler or expiry column in the backend | **HOLDS** |
| 2 | The key of a report is removed when the report is deleted | `apps/backend/migrations/001_init.sql:26` | **HOLDS** |
| 3 | A replayed submission does not consume rate-limit allowance | `apps/backend/store.py:85`, `apps/backend/store_pg.py:50` | **HOLDS** |
| 4 | The same key with a different payload is rejected | `apps/backend/store.py:82`, `apps/backend/store_pg.py:43` | **HOLDS** |
| 5 | The same key with a different payload is rejected with 409 | `apps/backend/reports.py:55` | **HOLDS** |
| 6 | Both clients hard-code consent to false | `apps/frontend/src/lib/api.ts:34`, `apps/mobile/lib/api/report_api.dart:73` | **HOLDS** |
| 7 | The `status` values include `Closed` | `apps/backend/migrations/001_init.sql:16` | **HOLDS** |
| 8 | The server never falls back to in-memory storage in production | `apps/backend/db.py:26` | **HOLDS** |
| 9 | The citations in § 5.1 and § 8 point at the lines they claim | The record cites `apps/backend/DATABASE.md:51`, `docs/PRIVACY.md:291-293` and `docs/PRIVACY.md:296-297`; the text it means is at `apps/backend/DATABASE.md:52`, `docs/PRIVACY.md:296` and `docs/PRIVACY.md:299` | **EXCEPTION — C-7** (three of the citations are one to five lines off; the claims themselves are correct) |

### 4.3 `docs/SECURITY.md` and `docs/API.md`

| Document | Claim | Checked against | Result |
|---|---|---|---|
| `docs/SECURITY.md:7` | The admin key is compared in constant time and fails closed | `apps/backend/reports.py:27` | **HOLDS** |
| `docs/SECURITY.md:20` | In-memory mode loses everything on restart | `apps/backend/store.py:15` | **HOLDS** |
| `docs/SECURITY.md:17` | "No retention or deletion policy is implemented" | A decision record now exists (`docs/RETENTION.md`) and M.4 builds the tool (T-24), still fail-closed | **EXCEPTION — C-4** (imprecise, not wrong about behaviour) |
| `docs/API.md:15` | `/analyze` is a legacy stub | `apps/backend/main.py:38` | **HOLDS** |
| `docs/API.md:26` | `timing` affects urgency and is not stored | No `timing` column in `apps/backend/migrations/001_init.sql:2` | **HOLDS** |
| `docs/API.md:32` | `consentToShare` is stored, default false | `apps/backend/store_pg.py:52` | **HOLDS** |
| `docs/API.md:59` | One shared static admin key, no users and no audit logs | `apps/backend/reports.py:17` | **HOLDS** |

---

## 5. Open decisions (recorded, not made)

Nothing in this task narrowed, closed or reworded any of these. They are listed so the audit is
read against the decisions that are still open.

The list below is the M.4 specification's own decision table (`design.md` § 11.1, mirrored in
`tasks.md` § "External dependencies and blocked work"). It is **not** the earlier research
numbering (`D-01` … `D-12` in `docs/research/M4_SCOPE_PROPOSAL.md` § 7), which used a different
scheme.

| Decision | Subject | Owner | Needed by | State |
|---|---|---|---|---|
| **D-A** | Report retention period, and whether closed cases are deleted sooner | Founder + legal | Before T-24 may delete anything, and before T-33 | **Open** — recorded undecided in `docs/RETENTION.md` |
| **D-B** | Backup retention period | Founder + legal | Before T-26's backup script is finalised | **Open** — recorded undecided in `docs/RETENTION.md` |
| **D-C** | Whether a reporter-initiated deletion path is needed | Founder + legal | Before T-01 is finalised | **Open** |
| **D-D** | Consent semantics: capture `consentToShare` for real, or remove it from the UI and schema | Founder + legal | Before T-01 is finalised | **Open** — see exception **C-3** |
| **D-E** | Hosting provider | Founder | Before T-26 is applied to a server | **Partially decided** (21 October 2026): a Contabo Cloud VPS 4 for the application and Neon PostgreSQL for the data (existing project `agent-gate`, Frankfurt), recorded in `docs/deploy/HOSTING_COMPARISON.md` § 10. The reasons, the VPS region, the server version, the recovery story, the firewall audit, the intended use of the Neon project and the deployment readiness remain open |
| **D-F** | Whether the AI assistant is in pilot scope | Founder | Before T-01 is finalised | **Open** — see exception **C-2** |
| **D-G** | Accept the screenshot-blocking trade-off of FLAG_SECURE | Founder | Before T-21 | **Open** |
| **D-H** | Whether a new pub dependency (`flutter_secure_storage`) is acceptable | Founder | Before T-12 | **Open** |
| **D-I** | Whether a new npm dev dependency set (test harness) is acceptable | Founder | Before T-07 | **Approved for T-07** — the dev-only set Vitest, jsdom, `@testing-library/react` and `@testing-library/jest-dom` |
| **D-J** | Admin key custody owner and rotation trigger | Founder | Before T-27 | **Open** |
| **D-K** | Pilot scope, participants, start date, and the supervising operator | Founder | Before T-32 | **Open** |
| **D-L** | The response team's actual metadata needs (timestamp precision) | Founder (needs D-K) | Before T-27 | **Open** |

Two items in this audit are affected by open decisions rather than by code:

- **The PostgreSQL version** cannot be verified (Hetzner, DigitalOcean and Railway versions are all
  unverified) until T-05 and T-31 have run. Not an M.4 exclusion, but it constrains the hosting
  decision, which is why it appears in `docs/deploy/HOSTING_COMPARISON.md` § 2.1.
- **The retention checks** are checks of *absence* — that nothing deletes anything. They stay valid
  whatever D-A and D-B decide, because the implementation is fail-closed until a period is set.

---

## 6. Exceptions

Every exception below was found by the checks in § 2–§ 4. Each has an explanation and a task to
resolve it. None of them was fixed in this task: fixing most of them means changing application
copy, a server prompt, or an approved T-01/T-02 document, and T-04's components are this document
and the script in § 7.

| # | Exception | Where | Why it matters | Task to resolve |
|---|---|---|---|---|
| **C-1** | User-facing copy says reports "are stored temporarily and may be cleared". That is true only of the in-memory development mode. In PostgreSQL mode — the mode the pilot will run in — a report is stored in a database and is not cleared when the server restarts. | `apps/frontend/src/screens/ConfirmationScreen.tsx:43`, `apps/frontend/src/screens/LandingScreen.tsx:262`, `apps/frontend/src/assistant/guidance.ts:40`, `apps/mobile/lib/l10n/app_en.arb:11`, `apps/mobile/lib/l10n/app_en.arb:109`, `apps/mobile/lib/l10n/app_sw.arb:11`, `apps/mobile/lib/l10n/app_sw.arb:78` | A user who is told their report may be cleared will behave differently from a user who believes it is kept — and the retention period is itself undecided (D-A). The notice says the opposite (`docs/PRIVACY.md:169`, `docs/PRIVACY.md:262`). The repository already tracks the web half of this at `docs/CHECKLIST.md:22`. | **Web:** extend **T-09** (React copy task) to the storage statement, or add a task. **Android:** new task — the storage statement appears in both the welcome and confirmation strings, in English and Kiswahili, so **T-20** (new strings) is the natural home but is scoped to the pending-report flow. Founder approval needed for either change of scope. |
| **C-2** | The assistant's server-side system prompt describes SafeSignal as letting users "submit **anonymous-by-design** incident reports", while the same prompt instructs the model never to promise anonymity. The model's replies are shown to the user. | `apps/backend/assistant.py:32` (against `apps/backend/assistant.py:36`) | PR-2.1 forbids user-facing text that states or implies a report is anonymous, and the privacy notice says SafeSignal makes no such guarantee (`docs/PRIVACY.md:319`). No client string does this — the risk is that the model repeats the framing back to a user who asks how SafeSignal works. | **New task (proposed): remove the "anonymous-by-design" framing from the assistant system prompt.** Must be done before T-32 (usability testing) and before any pilot that includes the assistant. Note D-F: if the assistant is not in the pilot, the pilot is unaffected — but the web prototype still shows the answers. |
| **C-3** | The privacy notice says the consent flag "is always `false`" / "Always `false`". The server stores the value it is given and returns it; only the two clients hard-code it to `false`. | `docs/PRIVACY.md:58`, `docs/PRIVACY.md:178` (against `apps/backend/store_pg.py:52`, `apps/backend/schemas.py:45`) | The accurate description is in `docs/API.md:32` ("stored; default false"). As written, the notice describes a guarantee the server does not make. | **T-01 (privacy notice) revision, alongside D-D.** The wording is part of an approved document, so it is not changed here. |
| **C-4** | `docs/SECURITY.md` says "No retention or deletion policy is implemented" and does not mention the retention decision record or the new M.4 documents. | `docs/SECURITY.md:17` | The statement is still true about behaviour (nothing deletes anything), but a reader of SECURITY.md will not find `docs/PRIVACY.md` or `docs/RETENTION.md`. | **T-22** (record the manifest state in SECURITY.md) and **T-33** (the final pass over `docs/SECURITY.md`). |
| **C-5** | The development checklist still lists "Privacy notice for users" as not done. | `docs/CHECKLIST.md:124` | T-01 delivered `docs/PRIVACY.md`; the checklist is stale. | **T-33** (owns `docs/CHECKLIST.md`). |
| **C-6** | The development checklist states test-suite sizes that are now wrong. | `docs/CHECKLIST.md:31` (backend: "56 pass without database" — the suite is now 86 passed, 1 skipped, 1 expected failure with T-04's checks added) and `docs/CHECKLIST.md:70` (Flutter: "2 pass" — the suite is now 159 tests with 1 opt-in skip; `docs/CHECKLIST.md:100` also says 47) | The counts are the evidence column of the checklist, so a wrong count is a wrong claim about what has been verified. | **T-33** (owns `docs/CHECKLIST.md`). |
| **C-7** | Three distinct citations in the retention record (four occurrences) point one to five lines away from the text they claim. The claims themselves are correct. | `docs/RETENTION.md` § 5.1 and § 8 (citing `apps/backend/DATABASE.md:51` and `docs/PRIVACY.md:291-293`, `docs/PRIVACY.md:296-297`; the referenced text is at `apps/backend/DATABASE.md:52`, `docs/PRIVACY.md:296` and `docs/PRIVACY.md:299`) | A citation that points at the wrong line is a broken audit trail in a document whose purpose is to be auditable. | **T-02 (retention record) revision.** The script in § 7 now checks these citations automatically and names exactly the three that are wrong, and it fails until they are corrected. |
| **C-8** | The prototype admin screen shows a *share consent* state, including mock rows with consent given, that no client can produce. | `apps/frontend/src/screens/AdminScreen.tsx:164`, `apps/frontend/src/admin/mockReports.ts:8` | It is mock data behind a production gate, so no data is at risk, but a reader of the prototype screen would infer a consent flow that does not exist. | **No M.4 action.** Noted for the future real admin UI (`docs/CHECKLIST.md:23`). |
| **C-9** | The privacy notice lists "Timing" among what a report contains but not among what the server stores. | `docs/PRIVACY.md:51` (against `docs/PRIVACY.md:169`) | Both statements are correct — timing is sent and is not stored (`docs/API.md:26`) — but a reader can carry "a report contains the timing" into "the server keeps the timing". | **No action required**; noted for T-01 if the notice is revised for C-3. |

---

## 7. The scripted re-check

The machine-checkable half of this audit lives in
**`apps/backend/tests/test_m4_scope_exclusions.py`**, so that a later change re-opens the check. It
runs in the existing backend CI job (`pytest -q`) with no new dependency and no database.

```
cd apps/backend && pytest -q tests/test_m4_scope_exclusions.py
```

What it covers:

| Area | What it asserts |
|---|---|
| Route table (XR-1, XR-7, XR-15) | The admin gate on every non-`POST` `/api/reports` route; an unauthenticated listing returns 401; no code-shaped route |
| Stub (XR-2) | No client calls `/analyze` |
| Dependencies (XR-3, XR-5, XR-6, XR-9, XR-10, XR-11, XR-12) | The web, Android and backend dependency sets equal the approved lists; no map, messaging, vision, crash-reporting or dispatch package |
| Manifest (XR-4, PR-4.1, PR-4.3) | The release manifest declares `INTERNET` and nothing else; no service, no location permission |
| Accounts (XR-7, PR-1.1) | No account-shaped route, no credential handling, no credential field in the schema |
| Admin UI (XR-8, SR-2.2) | The admin screen has no network call and stays behind the prototype gate |
| Schema (XR-13, XR-14, PR-11.2) | The `reports` and `idempotency_keys` column sets equal the documented ones; no staff or identity table |
| Mobile assistant (XR-16) | No assistant file and no assistant call in the Android app |
| Privacy (PR-1.2, PR-3.1, PR-3.2, PR-3.3, PR-4.1, PR-4.2, PR-5.2, PR-6.1, PR-6.2, PR-10.1, PR-10.2) | No phone or credential field reaches the server; consent is hard-coded false and is not a user control; no location capture; no contact is ever populated; no analytics package; no report content in any log line; the clipboard is written and never read |
| Fail-closed retention (RR-5.2, FR-8.1, FR-8.2) | No delete statement, scheduler or expiry logic for idempotency keys; no retention period compiled into code or environment templates |
| Browser storage (FR-6.1) | The only browser storage key is `safesignal-theme` (test files are excluded from the scan: they exercise the key, they are not application behaviour) |
| Notice placeholders (PR-9.3) | `docs/PRIVACY.md` still carries the marked D-A and D-B placeholders |
| This document | Every `path:line` citation in this file resolves to a real line of a real file, and the approved documents' citations are checked (currently failing on purpose — see C-7) |

The last row deserves a note. The citation check for `docs/PRIVACY.md` and `docs/RETENTION.md` is
marked `xfail(strict=True)` with the reason naming exception **C-7**. While the drift exists the
test is an expected failure; the moment somebody corrects the citations it will fail as an
unexpected pass, which forces the marker to be removed. That is deliberate: it keeps the
correction from being forgotten.

---

## 8. T-04 acceptance criteria

| Acceptance criterion (from `tasks.md`) | Result |
|---|---|
| All sixteen exclusions have a recorded check and a result | **Met.** XR-1 … XR-16, each with the search performed, the result and the evidence (§ 2). |
| Each result cites a file and line | **Met.** Every result carries at least one `path:line` citation; the citations are machine-checked (§ 7). |
| Any exception is listed with an explanation and a task to resolve it | **Met.** Nine exceptions, C-1 … C-9, each with an explanation and a named task or an explicit "no M.4 action" (§ 6). |
| **Automated verification:** the checks that can be scripted are scripted in a small script under `apps/backend/tests/` or `scripts/`, so a later change re-opens the check | **Met.** `apps/backend/tests/test_m4_scope_exclusions.py` — 31 checks (30 passing, 1 expected failure until C-7 is fixed), no new dependency, runs in the existing backend CI job. |
| **Manual verification:** review the results against the repository | **Outstanding — for the founder and the M.3 reviewer.** A person must read § 2–§ 6 against the repository and accept the nine exceptions and their resolution tasks. This task cannot mark its own manual verification done. |

---

## 9. What this task deliberately left alone

- The sixteen exclusions are all still in force; nothing in this milestone or in this task turned one
  of them off.
- The four open founder and legal decisions in the privacy and retention area (D-A, D-B, D-C, D-D)
  are untouched, and the two placeholders in the privacy notice are still there.
- The hosting decision (D-E) is still open; the comparison file still has an empty decision record.
- No application code, dependency, environment file, migration or workflow was changed by this task.
  The only files this task created are this document and the test file in § 7; the only file it
  modified is the milestone's `tasks.md`, and only the T-04 status line.
