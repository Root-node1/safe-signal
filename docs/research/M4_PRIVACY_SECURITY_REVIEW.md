# M.4 Privacy and Security Review

**Status:** research only — no code, schema or dependency changes.
**Basis:** [M.4_ARCHITECTURE_AUDIT.md](M4_ARCHITECTURE_AUDIT.md) and [M.4_GAP_ANALYSIS.md](M4_GAP_ANALYSIS.md).
**Scope:** what the current code protects, what it exposes, and what it cannot promise. This is not a security audit and not a claim of compliance.

> SafeSignal collects reports about harassment, threats and assault, with a vehicle, a route, a time and a place. That combination is inherently identifying even when the reporter contributes no personal data. Every control below should be read against that fact.

---

## 1. Existing protections

These are implemented today and verified in the source.

**Data minimisation at the source**
- Phone numbers and GPS coordinates are never transmitted by either client (`apps/frontend/src/lib/api.ts:18`; `apps/mobile/lib/api/report_api.dart:62-74`).
- The backend stores no contact number at all: `contact_provided` is accepted on input but is absent from `ReportOut` and from the database schema (`apps/backend/schemas.py:31`, `:35-48`; `apps/backend/store.py:46-61`).
- The assistant is instructed to tell users not to share names, numbers, plates or exact locations (`apps/backend/assistant.py` `SYSTEM_PROMPT`).

**No client-side persistence of incident data**
- The Flutter draft is in-memory only and explicitly never written to disk or logs (`apps/mobile/lib/models/report_draft.dart:1-3`); `apps/mobile/pubspec.yaml:30-36` contains no storage package.
- The React app persists nothing: *"State only. Nothing is persisted in the browser"* (`apps/frontend/src/App.tsx:12`). The only browser value stored is the theme preference, under the key `safesignal-theme` (`apps/frontend/src/lib/theme.ts:3`).
- The user's language choice is deliberately not saved (`apps/mobile/lib/app.dart:25-27`).

**Server-side containment**
- Admin access fails closed: an unset, empty or whitespace `SAFESIGNAL_ADMIN_KEY` authorises nobody, and every failure returns an identical 401 so the response cannot reveal whether a key is configured (`apps/backend/reports.py:14-29`; test `apps/backend/tests/test_reports.py:66-82`).
- The secret is compared in constant time (`apps/backend/reports.py:27`).
- Failed admin attempts are limited per client address and the allowance is returned on success (`apps/backend/ratelimit.py:62-67`, `:82-83`; test `apps/backend/tests/test_ratelimit.py:82-97`).
- Report creation is rate limited per address, and the limiter is charged only for genuinely new reports (`apps/backend/ratelimit.py:48-60`).
- Forwarding headers are ignored for client identity so they cannot be spoofed to escape a limit (`apps/backend/ratelimit.py:32-33`; test `apps/backend/tests/test_ratelimit.py:75`).

**Input and storage integrity**
- Every free-text field has a length bound and every enum is a closed literal set (`apps/backend/schemas.py:22-33`), mirrored by `CHECK` constraints in PostgreSQL (`apps/backend/migrations/001_init.sql:5-16`) and guarded against drift by a test (`apps/backend/tests/test_db_config.py:47-63`).
- All SQL is parameterised (`apps/backend/store_pg.py:52-65`).
- The 409 conflict message never echoes the conflicting payload (test `apps/backend/tests/test_idempotency.py:41`).

**Data-handling hygiene**
- Logs carry error class names and codes only — no report content, keys, addresses or connection strings (`apps/backend/db.py:95`; `apps/backend/store_pg.py:1`; `docs/SECURITY.md:12`).
- A database failure returns a generic 503 and leaks neither the DSN nor the host (test `apps/backend/tests/test_store_postgres.py:101-107`).
- The OpenRouter key stays server-side; assistant input is length-bounded and pattern-redacted (emails, Kenyan phone numbers, plates, coordinates, long digit runs); provider errors are returned as a generic code and nothing is stored (`apps/backend/assistant.py`; `docs/SECURITY.md:11`).
- Secrets are kept in git-ignored `.env` files with placeholder templates (`apps/backend/.env.example`; `docs/SECURITY.md:13`).
- The database is expected to use a least-privilege role and encrypted off-server backups, with PostgreSQL not exposed on the network (`apps/backend/DATABASE.md:29-38`, `:49-50`).

**Honest user-facing copy**
- The product states plainly that it did not dispatch anyone, that the report was not reviewed or forwarded, and that it is not an emergency service (`apps/frontend/src/screens/ConfirmationScreen.tsx:104-114`; `apps/mobile/lib/screens/confirmation_screen.dart:93-97`).
- The assistant is labelled as AI-generated and not professional advice (`apps/backend/assistant.py` `ChatOut.disclaimer`).

**What none of this provides:** anonymity, confidentiality, or a guarantee that a report cannot be traced to the person who made it. `docs/SECURITY.md:17` states this must not be suggested in the interface.

---

## 2. Potential identification through report metadata

A single stored report row contains: incident type, timing (`now`/`after`), route, area, vehicle plate, SACCO/operator, support choice, consent flag, status, a millisecond-precision `created_at`, an `acknowledged_at`, a UUID `id` and a human-readable `code` (`apps/backend/schemas.py:35-48`; `apps/backend/migrations/001_init.sql:2-20`).

**Time is the strongest identifier.** `created_at` is millisecond precision (`apps/backend/store.py:42-43`; `apps/backend/store_pg.py:13`). Combined with a route and an area, the timestamp answers "which vehicle left at 18:42 on this corridor", which for a single-vehicle route can identify the specific matatu, the specific stage and the specific minute a person was on it.

**Route plus vehicle plus SACCO is a fingerprint.** Plate + operator + corridor is enough to distinguish one vehicle among many on the same route; adding the stage (`area`) narrows it to one stop. In a commuter context this is a small population, and other witnesses of the same vehicle may recall who was aboard.

**Free text is entered by the user, unredacted.** `route`, `area`, `vehicle` and `sacco` are plain user-typed strings stored verbatim, with no masking, hashing or scanning (`apps/backend/migrations/001_init.sql:8-11`). A user who types a nickname, a school, a workplace or a description of a person has self-identified; nothing in the system warns them or detects it.

**The reference code is a readable handle.** `SS-XXXX-XXXX` is eight characters from a 30-symbol alphabet (`apps/backend/store.py:11-13`, `:30-32`), roughly 6.6 × 10¹¹ possibilities. Today there is no endpoint that resolves a code to a report (`apps/frontend/src/screens/ConfirmationScreen.tsx:91` states the code *"cannot be looked up yet"*), so a leaked code alone does not grant access. **Any future code-lookup endpoint must treat the code as a bearer token**, because it would be short enough for users to write down and share. The code is also written to the clipboard by both clients (`apps/frontend/src/screens/ConfirmationScreen.tsx:18-29`; `apps/mobile/lib/screens/confirmation_screen.dart:79-86`), where operating-system clipboard history may retain it.

**Idempotency keys are not bound to a client.** A key plus the original payload returns the complete original report, including all the fields above (`apps/backend/store_pg.py:32-45`; `apps/backend/store.py:80-84`). The key space (16+ random characters) makes guessing impractical, but the key is stored in the database in cleartext next to the report (`apps/backend/migrations/001_init.sql:24`) and is never rotated, bound or expired.

**The admin list returns everything.** `GET /api/reports` returns every report, full fidelity, to any holder of the shared key (`apps/backend/reports.py:61-63`), with no filtering, no per-responder scoping and no pagination. There is no record of who fetched what.

**One more indirect channel.** The assistant forwards the user's message and up to six turns of conversation history to a third-party provider after pattern redaction (`apps/backend/assistant.py` `chat`, `redact`). The patterns catch emails, Kenyan phone numbers, plates, coordinates and long digit runs; they do not catch narrative detail such as "I take the 23 bus from Ruiru and I am the only woman in a blue coat on the 6:30pm one". The redaction is a mitigation, not a guarantee, and the disclosure is cross-border.

---

## 3. Sensitive local storage considerations

**Today there is no sensitive local storage.** Neither client writes incident text to disk, and this is a deliberate property, not an oversight:

| Surface | What is stored | Evidence |
|---|---|---|
| Flutter draft | In memory only | `apps/mobile/lib/models/report_draft.dart:1-3` |
| Flutter key + submission state | In memory only | `apps/mobile/lib/api/submission_controller.dart:65-66` |
| Flutter language choice | Not stored | `apps/mobile/lib/app.dart:25-27` |
| React report state | In memory only | `apps/frontend/src/App.tsx:12` |
| React localStorage | Theme only (`safesignal-theme`) | `apps/frontend/src/lib/theme.ts:3` |
| Clipboard | Reference code, on user action | `apps/frontend/src/screens/ConfirmationScreen.tsx:18-29` |

**The costs of that property.** It is the reason a lost connection or a killed app loses the draft (`docs/CHECKLIST.md:90-91`), and it is why offline recovery is currently a gap rather than a feature.

**The costs of breaking it.** Any durable local store introduced for offline recovery becomes the highest-risk place in the product, because it holds the very text the user believed was transient. Requirements that follow from this:

1. **Storage location.** Application-private storage only (`getApplicationDocumentsDirectory` on Android, iOS app sandbox), never external storage, never a world-readable path.
2. **Encryption at rest.** The store holds route, area, plate and SACCO text. Platform key storage with an app-scoped key is the minimum; the key must not be derivable from a hard-coded constant in the binary.
3. **No backups.** Android auto-backup would copy the store off the device. `android:allowBackup="false"` or an equivalent exclusion rule is required, and it is not present today (search of `apps/mobile` finds no `allowBackup`).
4. **Explicit lifetime.** A stored draft must have a short expiry and must be purged on success, on reset and on Quick Exit.
5. **Erase on Quick Exit** must delete the store, not just the in-memory objects.
6. **No logging of store contents** by any diagnostics or crash-reporting tool.
7. **Shared-device hygiene.** A non-persistent store is the strongest defence when a phone is passed between users, which is a realistic commuter scenario.
8. **Clear user-facing statement.** If a draft is stored, the interface must say so plainly. Silently persisting incident text contradicts every existing message in the app.

---

## 4. Quick Exit limitations

**What Quick Exit does today.**

| Platform | Mechanism | Effect | Evidence |
|---|---|---|---|
| Web | `document.title = "Notes"` then `window.location.replace(...)` to a neutral page | Leaves the app immediately; the SPA is unloaded | `apps/frontend/src/lib/quickExit.ts:4-7` |
| Web | Escape key and header button | Global binding, also inside the assistant modal | `apps/frontend/src/components/SafeHeader.tsx:26-30`, `:56`; `apps/frontend/src/assistant/AssistantModal.tsx:68-73` |
| Android | `controller.reset()`, pop to first route, `SystemNavigator.pop()` | Clears the in-memory draft and state, then asks Android to close the app | `apps/mobile/lib/widgets/quick_exit_button.dart:11-15` |

**What it cannot do.** The Android implementation states its own limits in a comment: it *"cannot erase Android's recent-apps preview, screenshots, keyboard history, backups or anything else outside the app"* (`apps/mobile/lib/widgets/quick_exit_button.dart:9-10`; repeated at `docs/CHECKLIST.md:77`).

Concretely, after Quick Exit the following may still exist:

1. **The recent-apps thumbnail.** Android captures a snapshot of the task when it is backgrounded. The snapshot shows the screen the user was on — which, in the report flow, is the review screen containing route, area, plate and SACCO text (`apps/mobile/lib/screens/review_screen.dart:53-62`). Nothing in the app sets `FLAG_SECURE` (verified by search of `apps/mobile`), so the thumbnail is captured and stored by the system launcher.
2. **Screenshots and screen recording.** The user or a bystander can capture the screen; nothing blocks it.
3. **Keyboard and autocorrect history.** Text typed into the report fields may be retained by the keyboard app and its learning service.
4. **Clipboard history.** The reference code is copied to the clipboard by an explicit user action (`apps/mobile/lib/screens/confirmation_screen.dart:79-86`); Android clipboard history may retain it.
5. **App backup.** If the app writes anything to disk, Android auto-backup copies it off the device unless excluded.
6. **Notification and task history.** The app's name remains in the recents list; `android:taskAffinity=""` (`apps/mobile/android/app/src/main/AndroidManifest.xml:12`) makes the task harder to find by switching apps, but the entry remains.

On the web, `window.location.replace` clears the current document but leaves browser history entries, the HTTP cache and any service-worker state. The SPA holds nothing in `localStorage` beyond the theme, so the practical web exposure is the browser's own history and back/forward cache.

**The honest statement.** Quick Exit makes the app *look* gone. It does not make the data *gone* from the device, and it must not be described to users as if it does. The interface already avoids claiming erasure on the web (the confirmation screen describes what did and did not happen, `apps/frontend/src/screens/ConfirmationScreen.tsx:104-114`); that discipline must extend to any new copy.

---

## 5. Administrative access risks

**How access works today.** A single shared secret in `SAFESIGNAL_ADMIN_KEY`, presented in the `X-Admin-Key` header, grants access to both admin routes: list every report (`apps/backend/reports.py:61-63`) and change any report's status (`apps/backend/reports.py:66-75`). It is fail-closed and rate limited, and it is a single point of compromise with no attribution.

| Risk | Detail | Evidence |
|---|---|---|
| **No per-user identity** | Every admin action is anonymous. There is no way to tell who viewed or altered a report, and no way to revoke one person's access without rotating the key for everyone. | `apps/backend/reports.py:14-29` |
| **No audit logging** | There is no audit table and no audit write path. A list call or a status change leaves no trace beyond the current row state. | `apps/backend/migrations/001_init.sql:2-29` |
| **Unbounded read access** | One key reads every report in full, including the metadata described in §2. There is no scoping by region, case or role, and no pagination. | `apps/backend/reports.py:61-63` |
| **Secret in transit and at rest** | The key travels in a request header; without TLS it is readable by anything on the path. It sits in a server environment variable with no rotation schedule documented. | `docs/SECURITY.md:24`, `:27` |
| **Lockout is per address, not per key** | The failed-attempt limiter keys on the client address, so a distributed guess from many addresses is not slowed. | `apps/backend/ratelimit.py:32-33`, `:82-83` |
| **Status changes are unaudited and unreversible in the UI** | `PATCH /api/reports/{id}/status` sets `acknowledged_at` on the first non-`Received` status and never records who did it (`apps/backend/store_pg.py:102-107`). The mock dashboard shows an acknowledgement metric derived from mock data only (`apps/frontend/src/screens/AdminScreen.tsx:23-24`). |
| **The web admin route is gated by a cosmetic flag** | `/#admin` is reachable by URL and the guard is `PROTOTYPE`, a build-time constant in the public bundle — documented as explicitly not an authorisation mechanism. | `apps/frontend/src/App.tsx:52-53`; `apps/frontend/src/lib/prototype.ts:1-6` |
| **No vulnerability contact** | There is no published address for reporting a flaw, and the fallback is the repository owner's private channel. | `docs/SECURITY.md:33` |

**Practical consequence.** Today the correct operator posture is: exactly one person holds the key, the key lives in one environment variable on one server, and nobody has a second copy. That is a workable interim state for a supervised pilot, but it cannot scale to a team, cannot be audited, and cannot survive a key leak without a full rotation.

---

## 6. Retention and deletion gaps

**The policy does not exist.** `apps/backend/DATABASE.md:62-64` is explicit: *"No automatic deletion of reports or idempotency keys yet; policy pending approval."* `docs/CHECKLIST.md:47` repeats it, and `docs/SECURITY.md:17` adds that no retention or deletion policy is implemented.

**What is missing, concretely:**

1. **No retention period for reports.** Nothing expires a report. A report about an assault from years ago stays queryable forever.
2. **No retention period for idempotency keys.** `idempotency_keys` rows carry a `created_at` (`apps/backend/migrations/001_init.sql:27`) that nothing reads. They accumulate at the rate of submissions plus every retry.
3. **No scheduled job of any kind.** There is no cron, no queue, no worker, no TTL mechanism in the backend. Deletion depends entirely on a human remembering to run SQL.
4. **Deletion is manual and per-report.** `DELETE FROM reports WHERE code = 'SS-XXXX-XXXX'` (`apps/backend/DATABASE.md:65`) — no bulk or age-based path, and no record that a deletion happened.
5. **Deletion cascades silently to the idempotency key.** `ON DELETE CASCADE` (`apps/backend/migrations/001_init.sql:26`) means a deleted report's key disappears with it, so a late retry with that key creates a *new* report rather than resolving to the original. If a reporter retries after their report was deleted, the deletion is undone in effect.
6. **Backups are ungoverned.** `pg_dump` copies are recommended but the retention of the dumps themselves is not specified (`apps/backend/DATABASE.md:49-50`). A 30-day retention policy on the live database is meaningless if backups are kept indefinitely and unencrypted.
7. **No data-subject path.** There is no endpoint to look up a report by reference code, so a reporter who wants their report deleted, corrected or withdrawn has no channel, and the operator has no verified way to find the report without the exact code.
8. **Consent is stored but never captured.** `consent_to_share` is a database column (`apps/backend/migrations/001_init.sql:14`) that is always `false` because both clients hard-code it (`apps/frontend/src/lib/api.ts:34`; `apps/mobile/lib/api/report_api.dart:73`). Any future retention rule that depends on consent would be operating on a meaningless field.

**What a policy has to answer before any real report is collected:** how long a report is kept, who may see it, what happens when the case is closed, how a reporter requests deletion, how long backups are kept, and what is deleted together with the report.

---

## 7. Five highest-priority risks

Ranked by the harm that follows if the product collects real reports now, without further work.

### R-01 — Sensitive incident data is kept forever, with no way to erase it
**Severity: High · Area: Retention / Privacy**
Reports about assault, harassment and threats accumulate indefinitely in a live table with no expiry, and the only deletion route is an operator remembering a code. There is no schedule, no audit and no reporter-initiated deletion. This is the single most likely way the product causes harm to the people who use it: a record of a violent incident that the reporter believed would eventually disappear outliving the need for it, and remaining readable to anyone who ever obtains the admin key.
**Evidence:** `apps/backend/DATABASE.md:62-64`; `apps/backend/migrations/001_init.sql:2-29`; `docs/SECURITY.md:17`
**Mitigation:** Decide and implement a retention policy (period per report status, key expiry, bulk deletion job, deletion-audit trail, backup retention) before the first real report. Start with the shortest defensible period and make it visible in the privacy notice.

### R-02 — All administrative power rests on one shared, unauditable secret
**Severity: High · Area: Administrative access**
A single `X-Admin-Key` value grants unrestricted read of every report and write of every status, with no user identity, no role, no per-action attribution and no log of who did what. A leaked key is indistinguishable from legitimate use. The failure mode is not just confidentiality — it is an organisation that cannot answer "who read my report?" to the person who filed it.
**Evidence:** `apps/backend/reports.py:14-29`, `:61-75`; `apps/backend/migrations/001_init.sql:2-29`; `docs/SECURITY.md:23`
**Mitigation:** Introduce per-user admin authentication with role separation and an immutable audit log of list and status actions before a pilot. Interim control for a single-operator pilot: document the key custody, keep exactly one copy, rotate on any personnel change.

### R-03 — Reports and the admin key would travel over the network in cleartext
**Severity: High · Area: Deployment**
There is no reverse proxy and no TLS deployed. CORS is now configurable (`SAFESIGNAL_CORS_ORIGINS`) and security headers (HSTS, X-Content-Type-Options, X-Frame-Options, CSP, Referrer-Policy) are added by middleware, but the deployment layer is still unconfigured. The deployment is not configured, so today any real deployment would carry route, area, plate and SACCO text — and the admin key — in the clear, and the browser client is configured against `http://localhost:8000` (`apps/frontend/src/lib/api.ts:3-4`).
**Evidence:** `apps/backend/main.py:39-63`; `apps/backend/ratelimit.py:5-8`; `docs/CHECKLIST.md:112-117`; `docs/SECURITY.md:24`
**Mitigation:** Deploy behind TLS with a reverse proxy that overwrites `X-Forwarded-For` and a Uvicorn configured to trust only that proxy, then a production CORS allowlist and a security-header set. Treat this as a hard gate on collecting real reports.

### R-04 — A single report row can be re-identified from its own metadata
**Severity: High · Area: Metadata**
Millisecond-precision `created_at`, route, area, vehicle plate and SACCO operator together describe one vehicle, one stage and one minute. On a commuter route the population that matches is tiny, and witnesses or operators can often recall who was on that matatu. Nothing in the schema pseudonymises, aggregates or rounds these fields, and the free-text fields let a user self-identify without any warning.
**Evidence:** `apps/backend/schemas.py:35-48`; `apps/backend/store.py:42-43`; `apps/backend/migrations/001_init.sql:2-20`; `apps/backend/reports.py:61-63`
**Mitigation:** Decide what the response team actually needs (an operator needs the route and the time; they rarely need millisecond precision). Round or bucket `created_at` for analysis use, treat plate+SACCO as internal-only with restricted access, and add user-facing guidance not to type identifying detail into the free-text fields. If a reference-code lookup is ever added, treat the code as a bearer token.

### R-05 — Quick Exit clears the app but not the device, so the safety promise exceeds the mechanism
**Severity: High · Area: Quick Exit / Local storage**
The app offers an unmistakable "get me out of here now" affordance, and on Android it leaves the recent-apps thumbnail containing the review screen's route, plate and SACCO text, alongside OS-managed screenshots, clipboard history, keyboard history and backups. No `FLAG_SECURE` is set and no backup exclusion is configured. A user in a monitored or shared environment can reasonably believe the app has erased their report when it has not.
**Evidence:** `apps/mobile/lib/widgets/quick_exit_button.dart:9-15`; `apps/mobile/lib/screens/review_screen.dart:53-62`; search of `apps/mobile` finds no `FLAG_SECURE` and no `allowBackup`; `docs/CHECKLIST.md:77`
**Mitigation:** Set `FLAG_SECURE` on the reporting and review activities (blocks screenshots and the recents thumbnail), disable Android auto-backup for the app, clear the clipboard reference code after a short delay or on exit, and state plainly in the UI and the privacy notice what Quick Exit does and does not erase. Any future local draft store must be deleted by Quick Exit as well.

---

## 8. Additional risks, ranked below the top five

| Risk | Severity | Evidence |
|---|---|---|
| Assistant forwards user text and up to six turns of history to a third-party provider after pattern redaction that cannot catch narrative identifiers | Medium | `apps/backend/assistant.py` (`redact`, `chat`) |
| Idempotency keys are unauthenticated, unbound to a client, stored in cleartext and never expired; a holder of key + payload retrieves the full original report | Medium | `apps/backend/store_pg.py:32-45`; `apps/backend/migrations/001_init.sql:23-28` |
| Rate limiting is per process: a restart clears every counter, and behind a proxy all clients share one bucket | Medium | `apps/backend/ratelimit.py:1-9`, `:74-75` |
| No CAPTCHA or abuse control beyond IP rate limiting; an attacker behind rotating addresses can submit freely | Medium | `docs/SECURITY.md:26` |
| No rate limiting on the assistant or health routes; the assistant limit is also per-process | Medium | `apps/backend/assistant.py` `_throttle` |
| No TLS or reverse proxy deployed; security headers and CORS are configured but the transport is not hardened | Medium | `apps/backend/main.py:47-63` (headers present); `docs/SECURITY.md:27`; `docs/CHECKLIST.md:112-117` |
| `contactProvided` is accepted and discarded, and `consentToShare` is stored but never captured, so the database's privacy fields carry no information | Low | `apps/backend/schemas.py:31`; `apps/frontend/src/lib/api.ts:34` |
| The legacy `/analyze` stub returns a hardcoded classification and is not part of the reviewed contract | Low | `apps/backend/main.py:87-92` |
| No published vulnerability contact, no dependency scanning in CI, no independent security review | Low–Medium | `docs/SECURITY.md:27`, `:30`, `:33` |
| AI-written Kiswahili copy is unreviewed by a fluent speaker, so safety wording may be mistranslated | Medium | `docs/CHECKLIST.md:79` |

---

## 9. Summary judgement

SafeSignal's code is disciplined about what it *collects*: no phone numbers, no GPS, no accounts, no analytics, no client-side persistence, no report content in logs, and a genuinely well-tested idempotency layer that stops duplicate reports without leaking payloads. That is a good foundation.

The weaknesses are not in the collection path; they are in everything *after* collection and everything *around* the app. The product currently has no end-of-life story for the data it stores (R-01), no way to know who looked at a report (R-02), no protected transport (R-03), no protection against inference from the metadata it deliberately collects (R-04), and a safety affordance whose real reach is narrower than users will assume (R-05).

All five can be closed without changing the reporting flow, the data model or the idempotency design. That is what makes them P0 work rather than a redesign.
