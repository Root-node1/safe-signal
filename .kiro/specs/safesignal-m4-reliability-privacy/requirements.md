# Requirements — SafeSignal M.4 Reliability, Privacy & Controlled Validation

## Overview

M.3 (Unified UI/UX Redesign) is complete and pushed. M.4 hardens the system so that SafeSignal can
collect **real** incident reports under a controlled pilot: reliable submission, one protected offline
draft on Android, a designed data-lifetime story, honest privacy disclosures, a hardened device, and a
minimal but secure deployment baseline.

M.4 is **incremental**. The reporting journey, the HTTP contract, the idempotency mechanism and the
PostgreSQL schema for `reports` are preserved. M.4 adds durability *around* the existing mechanisms and
never replaces them.

Every requirement below is written so that it can be verified by an automated test, a documented manual
procedure, or a named external dependency. Requirements that depend on a legal, hosting or product
decision that has **not** been made are marked **[BLOCKED — …]** and carry no invented policy.

**Source documents:** `docs/research/M4_ARCHITECTURE_AUDIT.md`, `docs/research/M4_GAP_ANALYSIS.md`,
`docs/research/M4_PRIVACY_SECURITY_REVIEW.md`, `docs/research/M4_SCOPE_PROPOSAL.md`.

**Traceability:** every requirement ends with a `→ Task` line naming the implementing task in
`tasks.md`, or a `→ Blocked by` line naming the external dependency. The full matrix is in
`tasks.md` § "Traceability matrix".

---

## Scope Boundaries

**In scope**

- Submission reliability and idempotency-key recovery
- Exactly one protected pending report on Flutter Android
- Backend report retention and deletion design and tooling
- Privacy disclosures and a user-facing privacy notice
- Android privacy hardening (secure window, backup exclusion)
- Security baseline for a controlled pilot (TLS, proxy, CORS, headers, env validation)
- Automated and manual verification, including CI coverage for PostgreSQL and Flutter
- Pilot-readiness documentation

**Out of scope — explicitly excluded from M.4** (see § "Explicit Exclusions" for the testable form of
each): public incident maps, AI incident classification, community verification, reputation scoring,
automatic emergency dispatch, automatic offline submission, background location tracking, a public admin
dashboard, a full moderator workflow, partner integrations, reporter accounts.

---

## 1. Functional Requirements

### FR-1  Flutter pending-report capture

**FR-1.1** The Flutter app shall provide exactly one pending-report slot. Saving shall never create a
second pending report; if a pending report already exists, the user shall be offered to replace it or
keep it, never silently overwrite it.

**FR-1.2** Saving a pending report shall require an explicit user action on a distinct, labelled
control. The app shall not save a pending report implicitly on navigation, on backgrounding, on screen
rotation, or on a failed submission.

**FR-1.3** The saved record shall contain, atomically and together: the exact report payload that would
be sent to the server, the idempotency key issued for that payload, the creation timestamp, and the
expiry timestamp.

**FR-1.4** Saving shall be available only when the draft is complete enough to submit (incident type
and support choice chosen), matching the condition under which `SubmissionController.submit()` would
proceed today.

**FR-1.5** Saving shall not modify the in-memory draft or the in-flight submission state. Saving shall
not replace a controller idempotency key that was issued for the payload being saved. A key for the
payload being saved — the controller's current key when that key applies to it, otherwise a newly
generated one — may be installed together with its payload signature, but only after the pending
record has been successfully written.

Rationale: a saved report and a same-session submission of identical content must share one
idempotency key. If the saved record carried one key and the same-session submission another, an
ambiguous outcome (the request may or may not have reached the server) followed by a restart and a
restore would send the retry under a second key, and the server would treat it as a second logical
report — two stored reports for one report, with no change by the user (RR-3.1). The key is
therefore installed only after the record is safely stored, so a failed write leaves the controller
exactly as it was. The controller's key always belongs to the content it is working on: a key that
was issued for different content is not reused for the saved payload, because a changed report is a
new logical submission under the existing key policy. A request already in flight is unaffected, as
it captures its own key and payload before it is sent.

→ Task T-10, T-11, T-15

### FR-2  Flutter pending-report restore

**FR-2.1** On application start, the app shall look for a pending record. If a non-expired pending
record exists, the app shall offer the user the choice to restore it or to discard it, and shall not
send it automatically.

**FR-2.2** Restoring shall populate the in-memory draft with the saved incident type, timing, support
choice, route, area, vehicle and SACCO values.

**FR-2.3** Restoring shall install the saved idempotency key and the saved payload signature into the
submission controller, so that submitting the restored report unchanged reuses that exact key.

**FR-2.4** The restore prompt shall be dismissible. Dismissing it shall not delete the pending record
unless the user chooses to discard.

**FR-2.5** The restore prompt shall state when the pending report was saved and that it has not been
sent.

→ Task T-15, T-16

### FR-3  Flutter pending-report discard

**FR-3.1** The app shall provide a manual discard action for a pending report, available from the
restore prompt and from the reporting screens.

**FR-3.2** Discarding shall delete the stored record and key, clear the in-memory draft, and return the
user to the start of the reporting flow.

**FR-3.3** If deletion fails, the app shall say so plainly and shall not present the pending report as
deleted.

→ Task T-17, T-19

### FR-4  Flutter pending-report expiry

**FR-4.1** The pending report shall have a configurable expiry period, expressed in hours, supplied by
a build-time constant with a default of 24 hours.

**FR-4.2** On application start, a pending record whose expiry timestamp is in the past shall be
deleted and shall not be offered for restore.

**FR-4.3** The user shall be told that an expired pending report was deleted, and shall not be shown
the expired content.

**FR-4.4** The expiry period shall not be configurable by the user in-app; it is an application policy
value, not a reporter preference.

→ Task T-10, T-14

### FR-5  Flutter submission of a restored pending report

**FR-5.1** Submitting a restored pending report shall reuse the stored idempotency key when the report
content is unchanged.

**FR-5.2** If the user changes the report content after restoring, the app shall mint a new idempotency
key — because the stored key is bound to the stored payload on the server — and shall display an
explicit notice that the saved report was changed and will be sent as a new report. The key shall never
change silently.

**FR-5.3** A restored pending report shall be submitted only by an explicit user action. There shall be
no background, scheduled, or connectivity-triggered submission.

**FR-5.4** After a confirmed successful submission, the stored pending record and its key shall be
deleted.

**FR-5.5** If the deletion in FR-5.4 fails, the app shall keep the record, report the failure to the
user, and not claim that the device was cleared.

**FR-5.6** If the server's acknowledgement is uncertain (timeout, connection dropped), the pending
record and its key shall be retained, and the app shall tell the user that the outcome is unknown and
that retrying is safe because the same key is reused.

→ Task T-18, T-19

### FR-6  React reporting flow — no persistent browser storage

**FR-6.1** The React app shall continue to hold report drafts, detail fields and submission keys in
memory only. No incident content shall be written to `localStorage`, `sessionStorage`, cookies,
IndexedDB or the Cache API. The only permitted browser storage remains the theme preference under the
key `safesignal-theme`.

**FR-6.2** The existing React idempotency behaviour shall be preserved exactly: one key per logical
submission, reused while the payload is unchanged, re-minted when the payload changes, cleared on
success and on restart.

**FR-6.3** The React app shall communicate, in the submission-failure UI, that a page reload may lose
the submission key and that a retry after a reload can create a second report.

**FR-6.4** The submission-key reuse policy shall be implemented as a single, independently testable
pure module used by `App.tsx`, with no change to its observable behaviour.

→ Task T-08, T-09, T-30

### FR-7  Backend retention tooling

**FR-7.1** The backend shall provide a command-line retention tool that deletes reports older than the
configured retention window.

**FR-7.2** The tool shall support a dry-run mode that reports what would be deleted without deleting
anything.

**FR-7.3** The tool shall delete the idempotency keys that reference deleted reports, and shall report
how many keys were removed with them.

**FR-7.4** The tool shall emit a structured summary of each run — window, counts, start and end time —
to standard output and to a run-summary file, and shall not write report content to either.

**FR-7.5** The tool shall not delete reports that are outside the configured window, and shall not
modify report content or status.

**FR-7.6** The tool shall be safe to run concurrently with the API: it shall use a transaction and
shall not hold locks that block report submission for longer than a single statement.

→ Task T-24

### FR-8  Retention configuration — fail closed

**FR-8.1** Report retention shall be configured through an environment variable holding a number of
days. When it is unset, empty, or not a positive integer, the retention tool shall refuse to delete
anything and shall exit with a clear, non-sensitive message.

**FR-8.2** No default retention period shall be compiled into the tool, the API, or any configuration
template. **[BLOCKED — the actual retention period is a founder and legal decision; the tool ships
without a period and stays inert until one is set.]**

**FR-8.3** The retention window shall apply to all reports uniformly, by creation time. Status shall
not alter the window in M.4. **[BLOCKED — a separate window for closed cases may be required by the
retention policy; not decided.]**

→ Task T-02, T-24

### FR-9  Production environment validation

**FR-9.1** When `SAFESIGNAL_ENV=production`, the backend shall refuse to start unless all of the
following are present and valid: `DATABASE_URL`, a non-empty `SAFESIGNAL_ADMIN_KEY` of at least the
configured minimum length, and a non-empty CORS origin allow-list.

**FR-9.2** Validation failures shall be reported as a startup error naming the missing or invalid
variable, and shall never print the value of a secret.

**FR-9.3** The existing rule that production never falls back to in-memory storage shall be preserved.

→ Task T-23

### FR-10  Deployment configuration artifacts

**FR-10.1** The repository shall contain a reverse-proxy configuration template that terminates TLS,
overwrites `X-Forwarded-For` with the real client address, and does not log request bodies, the
`Idempotency-Key` header or the `X-Admin-Key` header.

**FR-10.2** The repository shall contain a service unit template that runs exactly one Uvicorn worker
with proxy-header trust limited to the local proxy.

**FR-10.3** The repository shall contain a backup script template that produces an encrypted
`pg_dump -Fc` archive and removes archives past the configured backup retention.

**FR-10.4** These templates shall be committed as inert examples with all site-specific values marked
as placeholders, and shall not contain credentials.

→ Task T-26

### FR-11  Flutter Quick Exit deletes the pending report

**FR-11.1** Quick Exit shall delete the stored pending report and its idempotency key from the device
before the application closes. The deletion shall be attempted **before** the app exits, so that it is
not raced against process death.

**FR-11.2** If the deletion fails, the app shall say so plainly, shall offer **Try again** and **Exit
anyway**, and shall not block the exit — Quick Exit is a safety affordance and must remain usable.
The app shall not claim that the device was cleared when it was not (RR-4.3).

**FR-11.3** Quick Exit shall preserve its existing immediate-navigation behaviour: the in-memory
draft is cleared, the app returns to its first route, and the application closes. No new screen,
dialog or interstitial shall be introduced ahead of the exit.

**FR-11.4** The app shall not state or imply that Quick Exit erases Android system-level traces —
the recent-apps thumbnail, screenshots, keyboard history, backups — or anything already transmitted to
the server (PR-8.1).

→ Task T-19

---

## 2. Security Requirements

### SR-1  Admin authentication

**SR-1.1** The existing fail-closed admin authentication shall be preserved verbatim: an unset, empty or
whitespace `SAFESIGNAL_ADMIN_KEY` authorises nobody, every failure returns an identical 401, and the
comparison is constant-time.

**SR-1.2** No new admin endpoint shall be introduced in M.4, and no report content shall become
reachable through any route that did not already expose it.

**SR-1.3** The shared-key model shall be documented as a known limitation with a named owner, a
custody rule (single copy, held by one person) and a rotation trigger (personnel change, suspected
leak). **[BLOCKED — an identity-management system is deferred; see Design § 11.2.]**

→ Task T-04, T-05, T-27

### SR-2  No public or pilot-facing admin surface

**SR-2.1** No admin dashboard shall be reachable in a pilot build. The React mock admin screen at
`/#admin` shall remain gated behind `VITE_PROTOTYPE=false` and shall not be deployed in a pilot build.

**SR-2.2** The mock admin screen shall not display real report data under any configuration.

→ Task T-04, T-27

### SR-3  Encryption at rest for the pending report

**SR-3.1** The pending report payload and its idempotency key shall be stored only in app-private,
encrypted storage, backed by the Android platform keystore.

**SR-3.2** The storage shall be located in the application-private data directory. The report shall
never be written to shared storage, external storage, a world-readable path, or a file readable by
another application.

**SR-3.3** No encryption key material shall be hard-coded in source, committed to the repository, or
derived from a constant in the binary.

**SR-3.4** The storage mechanism shall be replaceable behind a small interface, so that the storage
backend can be swapped without changing the controller or the screens.

→ Task T-10, T-11, T-12

### SR-4  Storage integrity

**SR-4.1** A pending record shall carry a checksum over its payload and key. A record whose checksum
does not verify shall be treated as corrupt and shall never be submitted.

**SR-4.2** A corrupt record shall be deleted and the deletion shall be reported to the user; the app
shall not crash and shall not fall back to an unprotected copy of the data.

**SR-4.3** A record that cannot be parsed shall be handled exactly as SR-4.2.

→ Task T-10, T-13

### SR-5  No sensitive data in logs

**SR-5.1** No report content — incident type, route, area, vehicle plate, SACCO name, free text — shall
appear in any application log, error message, crash report or proxy access log.

**SR-5.2** Idempotency keys and the admin key shall not appear in logs.

**SR-5.3** The retention tool shall not print report content (§ FR-7.4).

→ Task T-23, T-24, T-26

### SR-6  Transport security

**SR-6.1** A pilot deployment shall serve the API and the web app only over TLS. Plain HTTP shall be
redirected or refused.

**SR-6.2** The Android release build shall not permit cleartext traffic. The existing debug-only
cleartext allowance shall remain debug-only.

→ Task T-26, T-31

### SR-7  Trusted proxy configuration

**SR-7.1** The proxy shall overwrite `X-Forwarded-For` with the real client address rather than
appending to it.

**SR-7.2** Uvicorn shall trust forwarded headers only from the local proxy address, so that
`request.client.host` is the true client for rate-limiting purposes.

**SR-7.3** A deployment in which the proxy does not overwrite the header shall be documented as
unsupported, because every client would share one rate-limit bucket.

→ Task T-26, T-27

### SR-8  Restricted CORS

**SR-8.1** The CORS origin allow-list shall be configurable and shall default to a development value in
non-production only.

**SR-8.2** A production deployment with no configured allow-list shall refuse to start (§ FR-9.1).

**SR-8.3** The allowed methods and headers shall remain exactly those needed: `GET`, `POST`, `PATCH`;
`Content-Type`, `X-Admin-Key`, `Idempotency-Key`.

→ Task T-23

### SR-9  Security response headers

**SR-9.1** The deployment shall send `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`,
`X-Frame-Options: DENY`, and `Referrer-Policy: no-referrer` on all responses.

**SR-9.2** The web app shall be served with a Content-Security-Policy that restricts `default-src`,
`connect-src` to the configured API origin, `object-src` to `'none'`, and `base-uri` to `'self'`.

→ Task T-26

### SR-10  Idempotency contract integrity

**SR-10.1** The `Idempotency-Key` header format, the 16–64 character constraint, the SHA-256 payload
fingerprint, the 409 conflict response, the replay-returns-original behaviour, and the
replay-costs-no-allowance property shall all remain unchanged.

**SR-10.2** No new report-submission endpoint shall be introduced in M.4.

**SR-10.3** The transactional duplicate prevention in PostgreSQL mode shall remain intact: concurrent
same-key requests must still produce exactly one stored report.

→ Task T-04, T-05

### SR-11  Rate limiting behind a proxy

**SR-11.1** The rate limiter's per-process nature shall be documented in the deployment runbook, together
with the single-worker constraint and the consequence of adding a second worker without a shared
limiter.

**SR-11.2** A deployment shall run exactly one Uvicorn worker.

→ Task T-26, T-27

### SR-12  Secrets handling

**SR-12.1** No secret, key, password or connection string shall be committed to the repository, and no
template shall contain a value that could be mistaken for one.

**SR-12.2** The pending-report encryption shall use platform keystore-backed storage, never a
repository-committed secret.

→ Task T-12, T-26

---

### SR-13  Android local hardening

**SR-13.1** The application window shall set `FLAG_SECURE`, so that screenshots, screen recording and
the recent-apps thumbnail cannot capture the reporting, review or confirmation screens.

**SR-13.2** The consequence — that a reporter cannot screenshot the reference code — shall be stated
on the confirmation screen, which shall continue to offer the copy button.

**SR-13.3** Android auto-backup and device-to-device transfer shall be disabled for the application,
so that a saved pending report is never copied off the device.

**SR-13.4** The device verification task shall record evidence for SR-13.1 and SR-13.3 on physical
hardware before either is claimed as working.

**SR-13.5** No storage key, passphrase or seed shall be derived from a constant compiled into the
binary.

→ Task T-12, T-21, T-22, T-31

---

## 3. Privacy Requirements

### PR-1  No account required

**PR-1.1** Reporting shall continue to require no account, no phone number and no identity. No change to
`POST /api/reports` authentication.

**PR-1.2** The backend shall continue not to store a contact number; `contactProvided` remains accepted
and discarded.

→ Task T-01, T-04

### PR-2  No anonymity guarantee

**PR-2.1** No user-facing text shall state or imply that a report is anonymous, untraceable or
confidential.

**PR-2.2** A privacy notice shall state plainly that a report may be identifiable from its content —
time, route, area, vehicle and operator — and that SafeSignal makes no guarantee of anonymity.

→ Task T-01, T-32

### PR-3  No automatic sharing

**PR-3.1** No report shall be shared with a SACCO, police, an NGO, a partner organisation or any other
third party by SafeSignal.

**PR-3.2** The `consentToShare` field shall not be presented to users as an active control while it is
hard-coded to `false` in both clients. Either it is captured for real, or it is removed from the user
interface and the schema. **[BLOCKED — depends on the sharing decision; see Design § 11.2.]**

**PR-3.3** The existing `support` values `trusted-contact` and `check-in` shall remain unavailable and
shall not be enabled in M.4.

→ Task T-01, T-04

### PR-4  Location and tracking

**PR-4.1** Location fields shall remain optional and free-text. No coordinate, GPS, or geolocation
capture shall be added to any client.

**PR-4.2** No background location tracking shall be introduced. The app shall request no location
permission.

**PR-4.3** The Android manifest shall continue to declare no permission other than `INTERNET`.

→ Task T-04, T-22

### PR-5  No public individual reports

**PR-5.1** No individual report shall be published, surfaced publicly, or exposed through a public
listing, map, feed or search.

**PR-5.2** The existing public route signal aggregation shall remain prototype-only and shall not be
connected to real data in M.4.

→ Task T-04

### PR-6  No new sensitive analytics

**PR-6.1** No analytics, telemetry, crash-reporting or usage-tracking SDK shall be added to either
client in M.4.

**PR-6.2** Any diagnostic output shall exclude report content (§ SR-5.1).

→ Task T-04

### PR-7  AI assistant data handling

**PR-7.1** Before the assistant is included in any pilot workflow, its data handling shall be reviewed
and documented: what text is forwarded to the third-party provider, what redaction applies, what is not
redacted, and what the user is told.

**PR-7.2** If the assistant is included in a pilot, the pilot's disclosure materials shall name the
third-party provider and state that free-text messages are sent to it after pattern redaction.

**PR-7.3** The assistant's mobile screen shall not be introduced in M.4.

**[BLOCKED — the assistant's pilot inclusion is a founder decision; the assistant stays web-only and
landing-only in M.4 until decided.]**

→ Task T-01, T-33

### PR-8  Device-local traces disclosure

**PR-8.1** The app shall not claim that Quick Exit erases Android system-level traces (recent-apps
thumbnail, screenshots, keyboard history, backups) or server-side records.

**PR-8.2** A pending report saved on the device shall be described in the UI as stored on the device,
encrypted, and deleted on success, on discard, and on Quick Exit.

→ Task T-01, T-19, T-31, T-32

### PR-9  Retention and deletion disclosure

**PR-9.1** A privacy notice shall state how long reports are kept, how they are deleted, and how
backups are treated.

**PR-9.2** The notice shall state that a report may be deleted after its retention window, and that a
retry submitted after deletion may be stored as a new report.

**PR-9.3** The actual period shall be inserted only after the founder and legal review approve it.
**[BLOCKED — retention period is undecided; the notice shall carry a clearly marked placeholder that
the release checklist refuses to ship with.]**

→ Task T-01, T-02, T-24

### PR-10  Clipboard residual risk

**PR-10.1** The app shall not read the device clipboard in order to verify ownership of clipboard
content, because reading it may expose unrelated user data and may surface an operating-system notice.

**PR-10.2** The app shall not clear clipboard content it cannot prove it owns.

**PR-10.3** The privacy notice shall state that a reference code copied by the user may remain in the
device's clipboard history, and that the copy button is the recommended way to keep it.

→ Task T-01, T-04

### PR-11  Metadata minimisation

**PR-11.1** The precision of the stored creation timestamp shall be documented as an open item for the
response team, together with the re-identification risk of a millisecond timestamp combined with route,
area, vehicle and operator.

**PR-11.2** No metadata field shall be added to `reports` in M.4.

**[BLOCKED — the response team's actual needs, and therefore which precision is necessary, are not
known because no operational responder has been identified.]**

→ Task T-01, T-04, T-27

---

## 4. Reliability Requirements

### RR-1  Existing idempotency behaviour preserved

**RR-1.1** All existing backend idempotency tests shall continue to pass unchanged: first submission
creates one report, same key and payload returns the original, same key and different payload returns
409, concurrent same-key requests create exactly one report, malformed keys are rejected, requests
without a key are not idempotent, and reset clears keys with reports.

**RR-1.2** All existing client retry behaviour shall continue to pass unchanged.

→ Task T-05, T-28, T-30

### RR-2  Durable client key recovery (Flutter)

**RR-2.1** A pending report saved before an application restart shall, after the restart, be submitted
with the same idempotency key that was stored with it.

**RR-2.2** If the server had already accepted that report before the restart, the retry shall return
the original reference code and shall not create a second report.

**RR-2.3** The saved payload sent after a restart shall be byte-identical to the payload that was
saved.

→ Task T-15, T-18, T-29

### RR-3  Duplicate prevention

**RR-3.1** No code path in either client shall produce two stored reports for one logical submission
without the user having changed the report content.

**RR-3.2** The client shall not mint a new idempotency key for a restored pending report whose content
is unchanged.

**RR-3.3** The React client shall keep its existing behaviour: a page reload loses the key, so a
re-submission after a reload is a new report. This limitation shall be documented in the UI (FR-6.3)
rather than fixed, because fixing it would require persistent sensitive browser storage (§ FR-6.1).

→ Task T-08, T-09, T-15, T-18, T-30

### RR-4  Deterministic failure handling

**RR-4.1** An interrupted write shall not leave a partially valid pending record. A write shall either
be fully present and checksum-valid, or absent.

**RR-4.2** A corrupt or unparseable pending record shall be deleted, reported to the user, and shall
never be submitted.

**RR-4.3** A failed deletion shall be reported to the user and shall not be reported as success.

**RR-4.4** An uncertain server acknowledgement shall retain the pending record and its key, and shall
be surfaced as an unknown outcome rather than as a failure or a success.

→ Task T-13, T-18, T-19

### RR-5  No automatic background submission

**RR-5.1** Neither client shall submit a report without an explicit user action.

**RR-5.2** No background service, connectivity listener, alarm, or scheduled task shall be added that
submits a report.

**RR-5.3** The Android app shall request no background execution permission and shall not add a
foreground service for reporting.

→ Task T-04, T-15, T-22

### RR-6  Backend retention and key expiry coupling

**RR-6.1** Idempotency keys shall not be expired before the reports they reference. The retention tool
shall therefore remove a key only together with, or after, its report. The coupling rule is stated
once, in `docs/RETENTION.md` § 3, which is the single source of truth for data-lifetime policy.

**RR-6.2** The design shall document that deleting a report also removes its idempotency key by
foreign-key cascade, and that a retry arriving after deletion is stored as a new report.

**RR-6.3** The retention tool shall report the number of keys removed by cascade so that the
consequence is visible in operations.

→ Task T-02, T-24

### RR-7  Deployment availability

**RR-7.1** The API shall continue to answer `GET /health/ready` with 200 when the database is reachable
and 503 when it is not, without leaking connection details.

**RR-7.2** A database outage shall continue to return a generic 503 to clients, and shall not
partially store a report.

→ Task T-23, T-26

---

## 5. Accessibility Requirements

### AR-1  Announcing the saved-report state

**AR-1.1** The act of saving a pending report shall be announced to a screen reader through a status
region.

**AR-1.2** The restore prompt shall be announced as a dialog with a descriptive label and an
accessible name.

**AR-1.3** The restore prompt's actions shall be reachable and operable by keyboard and screen reader
alone.

→ Task T-16, T-17, T-28

### AR-2  Touch targets and focus

**AR-2.1** Every new control (save, discard, restore, dismiss) shall meet the existing minimum touch
target of 48 × 48 dp on Flutter.

**AR-2.2** Focus shall move to the restore prompt when it opens, and shall return to the invoking
control when it closes.

→ Task T-16, T-17

### AR-3  Text scaling and localisation

**AR-3.1** Every new screen and control shall render without overflow at 2× text scale, in both English
and Kiswahili.

**AR-3.2** Every new user-facing string shall exist in both `app_en.arb` and `app_sw.arb`, with
placeholder metadata where a placeholder is used.

**AR-3.3** No new user-facing string shall be hard-coded in a widget file.

→ Task T-16, T-17, T-20, T-28

### AR-4  Error announcement

**AR-4.1** Failure to save, failure to restore, failure to delete, a corrupt record, an expired record
and an uncertain acknowledgement shall each be announced through a live region, using the existing
`SafeSignalBanner` error pattern.

**AR-4.2** No error shall be conveyed by colour alone.

→ Task T-16, T-17, T-18, T-19, T-28

### AR-5  Contrast

**AR-5.1** All new controls and banners shall meet WCAG 2.2 AA contrast in light and dark mode.

→ Task T-16, T-17, T-28

### AR-6  Keyboard and screen-reader pass

**AR-6.1** The React reporting flow shall pass a manual keyboard and screen-reader pass, covering the
new failure messaging.

**AR-6.2** The Flutter pending-report flow shall pass a TalkBack pass on a physical device, covering
save, restore, discard and Quick Exit with a saved pending report.

**[BLOCKED — physical-device evidence requires a device and a scheduled test session; the procedure is
defined in tasks.md, the evidence is not yet available.]**

→ Task T-31, T-32

---

## 6. Operational Requirements

### OR-1  Retention job operation

**OR-1.1** The retention job shall be runnable on a schedule and from the command line, and shall exit
non-zero on failure.

**OR-1.2** The runbook shall state the schedule, the required environment, and what a run looks like in
the logs.

**OR-1.3** A failed run shall be visible in monitoring and shall not be silently ignored.

→ Task T-24, T-25, T-27

### OR-2  Backup and restore verification

**OR-2.1** A backup procedure shall produce an encrypted archive off the host.

**OR-2.2** A restore shall be executed at least once before the pilot, into a clean database, and the
restored row count shall be compared with the source.

**OR-2.3** The backup retention period shall be specified separately from the live report retention
period.

**[BLOCKED — backup retention period is part of the undecided retention policy.]**

→ Task T-02, T-26, T-31

### OR-3  Monitoring

**OR-3.1** `/health/ready` shall be monitored for availability and for 503 responses.

**OR-3.2** The retention job's exit status shall be monitored.

**OR-3.3** No monitoring shall capture report content or the admin key.

→ Task T-25, T-26, T-27

### OR-4  Log hygiene

**OR-4.1** Application and proxy logs shall be rotated, and their retention shall be shorter than or
equal to the report retention period.

**OR-4.2** Proxy access logs shall not include request bodies or sensitive headers.

→ Task T-26, T-27

### OR-5  CI gates

**OR-5.1** CI shall run the PostgreSQL integration suite against a service container on every push, and
the suite shall not self-skip.

**OR-5.2** CI shall run `flutter analyze` and `flutter test`.

**OR-5.3** CI shall run the React test suite once a harness exists.

**OR-5.4** Existing CI jobs (frontend lint and build, backend ruff and pytest) shall continue to pass.

→ Task T-05, T-06, T-07

### OR-6  Pilot-readiness documentation

**OR-6.1** A pilot-readiness document shall list every requirement in this specification with its
verification evidence, and shall state explicitly what has **not** been verified.

**OR-6.2** The document shall not claim physical-device, production, or legal verification that has not
actually been performed.

→ Task T-33

### OR-7  Runbook

**OR-7.1** An operator runbook shall cover: deployment topology, environment variables, the admin key
custody and rotation rule, the retention job schedule, the backup and restore procedure, and the
incident-response path for a suspected key leak or a suspected data exposure.

→ Task T-27

### OR-8  Hosting decision

**OR-8.1** A hosting provider shall be selected by comparing the pilot's requirements — data residency,
managed PostgreSQL availability and version, TLS, backup support, cost ceiling, SSH and firewall
control, and incident-response support — against at least two candidate options.

**OR-8.2** The comparison shall be recorded before any server is provisioned.

**[BLOCKED — the hosting decision is the founder's and cannot be made from the repository.]**

→ Task T-03

---

## 7. Explicit Exclusions

These are testable statements of what M.4 must **not** contain.

**XR-1** No public incident map, feed, listing or search of individual reports shall exist.

**XR-2** No AI classification of incident content shall be added to the reporting path. The existing
`/analyze` stub shall not be wired into any client.

**XR-3** No community verification, corroboration or confirmation mechanism shall be introduced.

**XR-4** No reputation score, user rating, or report weighting shall be introduced.

**XR-5** No automatic emergency dispatch, automatic call placement, or automatic third-party
notification shall be introduced.

**XR-6** No automatic offline submission shall be introduced: no background service, no connectivity
listener, no scheduled job, no queue that transmits on its own.

**XR-7** No background or foreground location tracking shall be introduced, and no location permission
shall be requested.

**XR-8** No public or pilot-facing admin dashboard shall be deployed, and no real report data shall be
rendered by the prototype admin screen.

**XR-9** No moderator workflow, case assignment, or responder tooling shall be built in M.4.

**XR-10** No partner integration (SACCO, police, NGO, transport operator) shall be built or
configured.

**XR-11** No reporter account, sign-in, or identity of any kind shall be required to file a report.

**XR-12** No new production dependency shall be added to the backend. The backend's runtime
dependencies remain exactly `fastapi`, `pydantic`, `starlette`, `uvicorn` and `psycopg`.

**XR-13** The existing `reports` table columns, constraints and indexes shall not be altered, and no
column shall be added to `reports`, in M.4.

**XR-14** The `POST /api/reports` request and response contract shall not change, and the
`Idempotency-Key` contract shall not change.

**XR-15** No new report-submission endpoint shall be introduced.

**XR-16** No mobile assistant screen shall be introduced.

→ Task T-04, T-33

The exclusion list is verified by the scope audit in Task T-04 and re-checked against the final
evidence in Task T-33.

---

## 8. Requirement counts

| Category | Groups | Testable statements |
|---|---|---|
| Functional | FR-1 … FR-11 (11) | 47 |
| Security | SR-1 … SR-13 (13) | 37 |
| Privacy | PR-1 … PR-11 (11) | 27 |
| Reliability | RR-1 … RR-7 (7) | 20 |
| Accessibility | AR-1 … AR-6 (6) | 13 |
| Operational | OR-1 … OR-8 (8) | 20 |
| Exclusions | XR-1 … XR-16 (16) | 16 |
| **Total** | **72 groups** | **180 testable statements** |

Items marked **[BLOCKED — …]** are requirements whose *implementation* is deliberately deferred to an
external decision. They are still requirements: they specify the behaviour the product must have once
the decision is made, and they are traced to a task that records the decision and the placeholder
rather than to an implementation.
