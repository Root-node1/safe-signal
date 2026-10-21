# Technical Design — SafeSignal M.4 Reliability, Privacy & Controlled Validation

Companion to `requirements.md` and `tasks.md` in this directory. This document describes **how** M.4
will be built; it does not build it. No code in this document has been written.

---

## 1. Design goals and non-goals

### 1.1 Goals

| # | Goal | Why |
|---|---|---|
| G-1 | A reporter never loses a report to a dead app, a dead tab, or a dropped connection | The core harm M.4 addresses: a report that was never received |
| G-2 | One logical submission never becomes two stored reports | Duplicates undermine confidence in every other report in the system |
| G-3 | The device holds no incident text longer than it must | The app's safety promise is that this data is transient |
| G-4 | Data has a defined lifetime, an executable deletion path, and an auditable trail | Retention is the largest unmitigated privacy risk (R-01) |
| G-5 | A pilot deployment is safe by construction, not by vigilance | TLS, proxy trust, CORS and headers must be defaults, not reminders |
| G-6 | Every claim in the interface is true | Users make safety decisions based on what the app says |
| G-7 | The change is small enough for one developer | Every extra mechanism is another thing that can leak |

### 1.2 Non-goals

M.4 does **not** introduce automatic offline submission, background execution, a queue, reporter
accounts, an admin dashboard, a moderator workflow, partner integrations, background location, a new
public API surface, or any new backend production dependency. See `requirements.md` § 7 for the
testable exclusion list.

### 1.3 Design principles applied

1. **Preserve, do not replace.** The backend idempotency implementation (`apps/backend/store.py`,
   `apps/backend/store_pg.py`) is proven and tested. M.4 does not touch it. The client change is
   *where the key lives*, not how it is computed or verified.
2. **One record, not a queue.** Exactly one pending report. A queue implies ordering, partial flush
   state, multi-key lifecycle and a background worker — four new failure modes for a feature the
   pilot has not shown it needs.
3. **Fail closed, fail visibly.** Unconfigured → refuse. Corrupt → delete and say so. Uncertain →
   say unknown and keep the record. Never silently proceed.
4. **No invented policy.** Retention periods, hosting, consent semantics and legal wording are
   founder and legal decisions. The code ships the *mechanism* and refuses to act until configured.
5. **Document what is not true.** The app's honesty is itself a privacy control: a user who believes
   Quick Exit erased the device will act differently than one who knows it did not.

---

## 2. Existing architecture and components to reuse

Everything below already exists and is preserved. M.4 adds around it.

```
┌──────────────────────────┐        ┌──────────────────────────┐
│  React web (apps/frontend)│        │ Flutter (apps/mobile)     │
│                          │        │                          │
│  App.tsx screen machine  │        │ SubmissionController      │
│    └ submission ref ─────┼── key ─┼──   ├ _key                │
│  lib/api.ts              │        │    ├ _signature           │
│    ├ buildPayload()      │        │    └ state machine        │
│    ├ newSubmissionKey()  │        │  ReportDraft (in memory)  │
│    └ createReport() 8 s  │        │  ReportApi (http)         │
└───────────┬──────────────┘        └───────────┬──────────────┘
            │ POST /api/reports                    │ POST /api/reports
            │ Idempotency-Key                     │ Idempotency-Key
            └──────────────────┬───────────────────┘
                               ▼
                   ┌───────────────────────┐
                   │ FastAPI (apps/backend)│
                   │  reports.py  POST     │  public, 201
                   │          GET / PATCH │  admin key
                   │  store.py  ──────────┼──▶ in-memory (dev only)
                   │  store_pg.py ────────┼──▶ PostgreSQL
                   │  ratelimit.py        │  per-process window
                   └───────────────────────┘
```

### 2.1 Reused unchanged

| Component | File | Why it is reused |
|---|---|---|
| Idempotency fingerprinting and duplicate prevention | `apps/backend/store.py:64-91`, `apps/backend/store_pg.py:48-75` | Proven under concurrency; requirement SR-10.1 forbids replacing it |
| Report API contract | `apps/backend/reports.py:35-58` | XR-14, XR-15 |
| Schema and constraints | `apps/backend/migrations/001_init.sql` | XR-13; the `reports` table is not altered |
| Payload shape | `apps/frontend/src/lib/api.ts:19-36`, `apps/mobile/lib/api/report_api.dart:64-74` | One canonical payload builder per client already exists |
| Key generation | `apps/frontend/src/lib/api.ts:39-43`, `apps/mobile/lib/api/report_api.dart:131-138` | Random UUID v4, never derived from content — reused verbatim |
| Client retry semantics | `apps/frontend/src/App.tsx:99-113`, `apps/mobile/lib/api/submission_controller.dart:78-115` | "Same payload → same key; changed payload → new key" |
| Submission state model | `apps/mobile/lib/api/submission_controller.dart:8-47` | `Idle / Submitting / Succeeded / ValidationFailed / NetworkFailed / RateLimited / UnexpectedResponse / NotConfigured` — extended, not replaced |
| Live-region error pattern | `apps/mobile/lib/widgets/safesignal_banner.dart`, `apps/frontend/src/components/ui/InlineBanner.tsx` | AR-4 |
| Localisation pipeline | `apps/mobile/lib/l10n/app_en.arb`, `app_sw.arb` | AR-3.2, AR-3.3 |
| Migration runner | `apps/backend/migrate.py` | Advisory lock, one transaction per file — reused if a migration is ever needed |
| Fail-closed admin dependency | `apps/backend/reports.py:14-29` | SR-1.1 |

### 2.2 New components

| Component | Location | Purpose |
|---|---|---|
| `PendingDraftStore` (abstract) | `apps/mobile/lib/storage/pending_draft_store.dart` | Interface: read / write / delete one pending record |
| `PendingDraft` (record) | `apps/mobile/lib/storage/pending_draft.dart` | Value object: version, payload, key, createdAt, expiresAt, checksum |
| `SecurePendingDraftStore` | `apps/mobile/lib/storage/secure_pending_draft_store.dart` | Android keystore-backed implementation |
| `InMemoryPendingDraftStore` | `apps/mobile/test/…` or `lib/storage/in_memory_pending_draft_store.dart` | Test double and non-Android fallback |
| `submissionKeyPolicy` (pure) | `apps/frontend/src/lib/submissionKeyPolicy.ts` | Extracts the React key-reuse rule so it can be unit-tested (FR-6.4) |
| `retention.py` | `apps/backend/retention.py` | CLI: delete reports past the configured window (FR-7) |
| Deployment templates | `apps/backend/deploy/` | Reverse proxy, service unit, backup script (FR-10) |

---

## 3. Flutter pending-report lifecycle and state machine

### 3.1 Scope of the pending slot

Exactly one pending report exists per app install. There is no list, no queue, and no second slot.
Replacing a pending report is an explicit choice by the user.

### 3.2 State machine

```
                       ┌──────────────────────────────────────────────┐
                       │                                              │
   app start ─────────►│  read pending record                        │
                       │        │                                     │
              ┌────────┴────────┴──────────┐                          │
              │ none                         │ found                   │
              ▼                             ▼                         │
        ┌───────────┐             ┌──────────────────┐                │
        │  Idle     │             │  RestorePrompt   │                │
        │ (no draft)│             │  [Restore][Keep] │                │
        └─────┬─────┘             └──┬───────────┬──┘                │
              │                       │           │                   │
              │ draft edits           │ Restore   │ Discard           │
              ▼                       ▼           ▼                   │
        ┌───────────┐         ┌───────────┐  (delete record)          │
        │ Drafting  │         │  Drafting │──────────────┐            │
        │ in memory │         │ + restored │             │            │
        │ + _key    │         │   _key     │             │            │
        └─────┬─────┘         └─────┬─────┘             │            │
              │                       │                   │            │
              │ explicit "Save"       │                   │            │
              ▼                       │                   │            │
        ┌───────────┐                 │                   │            │
        │  Saved    │◄────────────────┘                   │            │
        │ (record on│  (record updated in place)          │            │
        │  device)  │                                     │            │
        └─────┬─────┘                                     │            │
              │ explicit "Submit"                         │            │
              ▼                                           │            │
        ┌───────────┐   2xx      ┌───────────┐            │            │
        │Submitting │───────────►│ Succeeded │            │            │
        └─────┬─────┘            └─────┬─────┘            │            │
              │ timeout/network        │ delete record     │            │
              ▼                        ▼                   │            │
        ┌───────────┐            ┌───────────┐            │            │
        │ Failed    │            │  Idle     │◄───────────┘            │
        │ (record   │            └───────────┘                         │
        │  kept)    │                                                  │
        └───────────┘──────────────────────────────────────────────────┘
```

Transitions are table-driven in the controller; the diagram is the specification, the code mirrors it.

### 3.3 State meanings

| State | In-memory draft | Stored record | Key | Screen |
|---|---|---|---|---|
| `Idle` | empty | absent | none | Welcome |
| `Drafting` | present | absent | none or in-flight | Report / Support / Review |
| `Drafting` (restored) | present, restored from record | present | **the stored key** | Review |
| `Saved` | present | present | the stored key | Review, with a "saved" indicator |
| `Submitting` | present | present until success | the stored or in-flight key | Review, submitting |
| `Succeeded` | cleared | deleted | cleared | Confirmation |
| `Failed` | present | present if it was saved | the stored key | Review, with error banner |

### 3.4 Rules

- **R-1** A record is written only by an explicit user action (FR-1.2).
- **R-2** A record is written as **one** store entry containing payload + key + timestamps + checksum
  (FR-1.3, RR-4.1).
- **R-3** A record is deleted on: confirmed success (FR-5.4), manual discard (FR-3.2), Quick Exit
  (FR-11 in § 6), expiry (FR-4.2), and corruption detection (SR-4.2).
- **R-4** Restoring installs `_key` and `_signature` together (FR-2.3). This is the single most
  important line of the whole feature — without it the controller would see `_key == null` and mint a
  new key, silently turning one report into two.
- **R-5** The payload stored is the **canonical** payload (`ReportApi.payload(draft)`), not the raw
  draft, so the stored bytes are exactly the bytes that would be sent (RR-2.3).
- **R-6** A restore that is dismissed without a choice leaves the record untouched (FR-2.4).
- **R-7** The pending record is never submitted by the app on its own (FR-5.3, RR-5.1).

---

## 4. Encrypted storage design and key management

### 4.1 Approach — one value, one keystore

The pending record is a single JSON blob stored under one key. It is small (the report payload is
bounded by the API limits: route ≤ 120, area ≤ 120, vehicle ≤ 20, sacco ≤ 80 characters — under
1 KB total) and there is exactly one of it.

**Chosen: `flutter_secure_storage`** (Android `EncryptedSharedPreferences`, keystore-backed by
Android Keystore).

Alternatives considered and rejected:

| Alternative | Why not |
|---|---|
| `shared_preferences` (plain XML) | Plaintext on disk. Fails SR-3.1 directly. |
| SQLite (`sqflite`/`drift`) + a crypto package | A database file, a schema, a second crypto dependency, an import/export path, and a larger deletion surface — for one 1 KB record. Over-engineering. |
| `path_provider` + AES-GCM via `cryptography` | Needs a home-grown key-derivation and file-atomicity scheme. `flutter_secure_storage` already wraps the platform keystore, which is the correct root of trust for a mobile app. |

`flutter_secure_storage` is a **production dependency addition** to `apps/mobile/pubspec.yaml`. This is
the dependency question raised as D-10 in the M.4 scope proposal, and it is the only new client
dependency M.4 requires.

### 4.2 Record format

```jsonc
{
  "version": 1,                       // schema version; only 1 exists in M.4
  "payload": {                        // the exact canonical payload to POST
    "incident": "threats",
    "timing": "now",
    "route": "Thika Road",
    "area": "Githurai 45",
    "vehicle": "KDA 123A",
    "sacco": "Super Metro",
    "support": "private",
    "contactProvided": false,
    "consentToShare": false
  },
  "key": "0b9f2c1e-7a54-4c1d-9e0a-3f6d8b2a1c77",  // the idempotency key issued for this payload
  "createdAt": 1760000000000,         // epoch ms, client clock
  "expiresAt": 1760086400000,         // createdAt + expiry period
  "checksum": "…"                     // SHA-256 over version|payload|key|createdAt|expiresAt
}
```

Notes:

- `payload` is the **canonical** map from `ReportApi.payload(draft)`, so
  `jsonEncode(jsonDecode(stored))` reproduces it byte-for-byte. Dart's `jsonEncode` writes no
  whitespace and preserves insertion order; `ReportApi.payload` uses a fixed literal order, so the
  round trip is stable. This is what makes RR-2.3 testable.
- `checksum` is over the canonical string of the fields, **excluding** `checksum` itself.
- The `version` field exists so a future format change can be detected rather than misread.

### 4.3 Checksum and write atomicity

`flutter_secure_storage` writes a single key/value; the underlying `EncryptedSharedPreferences`
commit is atomic per value. Two layers protect against a torn write:

1. The whole record is one value — there is no multi-file or multi-key partial state to recover.
2. The checksum detects a value that was written but is not the record we intended (for example a
   value written by an older app version, or a value corrupted by a keystore fault).

On read:

```
read → parse JSON →  ok?  → verify checksum  →  ok?  → valid record
             │                                  │
             └──────┬───────────────────────────┘
                    ▼
          corrupt → delete record → notify user → continue with no pending report
```

The user is told the saved report could not be read and was deleted. The app never crashes and never
falls back to an unprotected copy (SR-4.2, SR-4.3, RR-4.2).

### 4.4 Key management

- The encryption key is held by the **Android Keystore**, non-exportable on devices with a hardware
  backing store. The app never sees raw key material and cannot export it (SR-3.3).
- No key, passphrase or seed is committed to the repository (SR-12.1).
- The idempotency key stored alongside the payload is protected by the same envelope. It is not a
  secret per se (it is 128 random bits), but possession of it plus the payload lets a party replay
  the request and read the original report, so it is treated as sensitive (PR-8.2).
- On devices where the keystore is unavailable or fails to initialise, the store reports an
  unavailable state; the app continues to work for in-memory reporting and tells the user that
  saving is not currently possible. **It must never silently fall back to plaintext storage.**

### 4.5 Expiry

- Expiry is an application constant, not a user setting (FR-4.4).
- Default: **24 hours**, defined as a compile-time constant in the store implementation so it can be
  overridden per build with `--dart-define` without a code change.
- Expiry is evaluated against the stored `expiresAt`, computed at save time from the client clock.
- A device clock set far in the future could make a record expire immediately; a clock set far in the
  past could extend its life beyond the intended window. This is accepted and documented: the window
  is a best-effort bound, and the storage is encrypted and deleted on success, discard and Quick Exit
  in the normal case.

---

## 5. Submission and idempotency recovery

### 5.1 The key-reuse rule, restated precisely

Both clients already implement this. M.4 makes it durable in Flutter and testable in React.

```
signature = canonicalJson(payload)

if (key == null || signature != storedSignature):
    key = newRandomKey()        // content changed → new logical report
    storedSignature = signature
else:
    reuse key                   // same content → same logical report
```

Restoring a pending record sets **both** `key` and `storedSignature` to the stored values, so the
first branch is false and the stored key is reused.

### 5.2 Recovery sequence

```
  user: Save for later                user: Submit
         │                                   │
         ▼                                   ▼
  canonical payload ──► write record      signature == stored?
  key = current key        (one value)         │
  expiresAt = now + 24h                      ┌────┴────┐
                                              │         │
                                             yes        no  (content edited)
                                              │         │
                                              │         ▼
                                              │    mint NEW key
                                              │    + show explicit notice
                                              ▼
                                   POST /api/reports
                                   Idempotency-Key: <key>
                                              │
              ┌───────────────┬───────────────┼───────────────┐
              ▼               ▼               ▼               ▼
            201            409             429             timeout
              │               │               │               │
              ▼               │               ▼               ▼
         delete record    keep record    keep record     keep record
         show code        (conflict:     (rate limited) (UNKNOWN outcome:
                         content differs                    "may or may not have
                          → new key +        keep record     reached the server;
                            notice)                           retry is safe")
```

### 5.3 The 409 case after a restore

If the server holds the key bound to a *different* payload than the one the client holds — which
should not happen, because the client stores the payload the key was issued for — the server returns
409. The client treats it as a conflict, mints a new key for the next attempt, and tells the user that
the report will be sent as a new report. This is the only path on which a restored report may receive
a new key, and it is never silent (FR-5.2, RR-3.2).

### 5.4 Uncertain acknowledgement

A timeout after the request was sent is the hardest case: the server may have stored the report.
The correct behaviour is to keep the record and its key, and to tell the user the truth:

> "We could not confirm whether your report was received. Your report is saved on this phone. Tap
> Submit again — the same report will not be sent twice."

This is the same guarantee the existing timeout integration test proves
(`apps/mobile/test/integration/backend_timeout_retry_test.dart:86-113`), now extended across an
application restart.

### 5.5 React — what changes

The React key policy is extracted into a pure module so it can be tested without a DOM:

```ts
// apps/frontend/src/lib/submissionKeyPolicy.ts
export type SubmissionKeyPolicy = { key: string; signature: string } | null

export function resolveSubmissionKey(
  current: SubmissionKeyPolicy,
  signature: string,
  newKey: () => string,
): SubmissionKeyPolicy {
  if (current && current.signature === signature) return current
  return { key: newKey(), signature }
}
```

`App.tsx` uses it in place of the current inline comparison. Observable behaviour is identical
(FR-6.2). This is the only React code change in M.4 besides copy (FR-6.3) and tests.

---

## 6. Quick Exit and deletion behaviour

### 6.1 Current behaviour (preserved)

`quickExit()` in `apps/mobile/lib/widgets/quick_exit_button.dart:11-15` resets the controller, pops
to the first route, and calls `SystemNavigator.pop()`. The web equivalent replaces the location with
a neutral page (`apps/frontend/src/lib/quickExit.ts:4-7`). Both are preserved (approved decision:
"Preserve existing immediate navigation behavior").

### 6.2 New behaviour

```
quickExit()
   │
   ├─► controller.reset()            clears in-memory draft + in-flight state
   │      │
   │      └─► deletePendingRecord()  ← NEW
   │             │
   │             ├─ success ──► continue to pop + exit
   │             └─ failure ──► show "The saved report could not be deleted
   │                            from this phone."  [Try again]  [Exit anyway]
   │                            (exit is not blocked; the user is told the truth)
   │
   ├─► Navigator.popUntil(first)
   └─► SystemNavigator.pop()
```

Design points:

- **Deletion happens before exit.** The order is: clear memory, delete the record, then close the app.
  Exiting first would race the deletion against process death.
- **Failure does not trap the user.** Quick Exit is a safety affordance; blocking it on a keystore
  error would be dangerous. The app shows a short, explicit message with **Try again** and **Exit
  anyway**, and the user chooses (RR-4.3, PR-8.1). The app never claims the device was cleared when
  it was not.
- **Web is unaffected.** The React app stores nothing, so its Quick Exit needs no deletion step.

### 6.3 Deletion points — complete list

| Trigger | Location | Record | In-memory draft | Key |
|---|---|---|---|---|
| Confirmed 2xx | `SubmissionController` on `SubmitAccepted` | deleted | cleared | cleared |
| Manual discard | New discard action | deleted | cleared | cleared |
| Quick Exit | `quickExit()` | deleted | cleared | cleared |
| "Done" on confirmation | existing `controller.reset()` | already deleted | cleared | cleared |
| Expiry on start | store read | deleted | n/a | n/a |
| Corruption detected | store read | deleted | n/a | n/a |

### 6.4 What is *not* claimed

The app must not say that Quick Exit erases Android system traces. The following remain outside the
app's control and must be stated in the privacy notice and in the UI:

- the Android recent-apps thumbnail (mitigated, not eliminated, by FLAG_SECURE — see § 7.1)
- screenshots and screen recordings taken by the user or a bystander
- keyboard and autocorrect learning data
- the system clipboard and its history (see § 7.3)
- anything already transmitted to the server, and anything in the server's backups

---

## 7. Android privacy hardening

### 7.1 FLAG_SECURE — evaluation and recommendation

**Evaluation.** `FLAG_SECURE` on the activity window blocks: screenshots, screen recording, and the
recent-apps thumbnail. It does not block: the keyboard learning database, the clipboard, or anything
already transmitted.

**Implementation without a new dependency.** The window flag is set natively in
`apps/mobile/android/app/src/main/kotlin/com/safesignal/app/MainActivity.kt`:

```kotlin
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
}
```

This is preferred over the `flutter_windowmanager` package: it needs no new pub dependency, it
covers the whole Flutter surface including the FlutterView, and it is a four-line change.

**Trade-off.** Users can no longer screenshot the confirmation screen to keep their reference code. The
copy button remains and is the recommended route; the confirmation screen already offers it
(`apps/mobile/lib/screens/confirmation_screen.dart:79-86`). A short note on the confirmation screen
should say that screenshots are blocked for privacy and that the code can be copied.

**Recommendation.** Enable it application-wide. **Decision required:** the founder must accept the
screenshot-blocking trade-off (recorded as an open decision in § 11).

### 7.2 Backup exclusion — evaluation and recommendation

**Evaluation.** Android auto-backup copies the app's private data to Google Drive (and, on Android 12+,
device-to-device transfer can include it). With `flutter_secure_storage`, the stored value is
encrypted by the keystore, but the *keystore key itself* does not migrate to a new device, so a
restored backup would produce undecryptable data. Excluding the app from backup is both a privacy
control and a correctness requirement.

**Implementation.**

1. `android:allowBackup="false"` on the `<application>` element in
   `apps/mobile/android/app/src/main/AndroidManifest.xml`.
2. `android:dataExtractionRules="@xml/data_extraction_rules"` pointing at a new
   `res/xml/data_extraction_rules.xml` that excludes the app's files, databases, shared preferences
   and no-backup directories from both cloud backup and device transfer:

```xml
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="file" />
        <exclude domain="database" />
        <exclude domain="sharedpref" />
        <exclude domain="external" />
    </cloud-backup>
    <device-transfer>
        <exclude domain="file" />
        <exclude domain="database" />
        <exclude domain="sharedpref" />
        <exclude domain="external" />
    </device-transfer>
</data-extraction-rules>
```

3. A verification step in the device test plan: `adb backup` (or the Android backup inspector) shows
   no SafeSignal data, and the app's data directory contains no report text after Quick Exit.

**Recommendation.** Apply both. Neither needs a new dependency.

### 7.3 Clipboard — assessment

**The constraint.** The app does not own the clipboard. Anything it does to it may affect content the
user placed for another app.

**Options assessed.**

| Option | Assessment |
|---|---|
| Clear the clipboard unconditionally on exit (`clearPrimaryClip()`, API 28+) | **Rejected.** It may destroy clipboard content belonging to another app, and it does so silently. |
| Read the clipboard to check whether it still holds our code, then clear it if so | **Rejected.** On Android 10+ reading the clipboard from a non-focused app surfaces a system notice and touches data the app does not own. |
| Do not read or clear; disclose the residual risk | **Chosen.** |

**Chosen behaviour.** The app writes the reference code to the clipboard only on an explicit user
action, never reads the clipboard, and never clears it. The privacy notice and the confirmation screen
state that the code may remain in the device's clipboard history, and that the copy button is the
recommended way to keep it (PR-10.1 … PR-10.3).

---

## 8. Backend retention and cleanup strategy

### 8.1 Principles

- Retention is **configured**, never hard-coded, and the tool is **inert** until configured
  (FR-8.1, FR-8.2).
- Deletion is **age-based and uniform**; status does not alter the window in M.4 (FR-8.3).
- Deletion of a report **cascades** to its idempotency key by the existing foreign key
  (`apps/backend/migrations/001_init.sql:26`). This is accounted for, not worked around (RR-6.2).
- The tool **reports** what it did, and never prints report content (FR-7.4, SR-5.3).

### 8.2 The referential-integrity coupling

```
   reports(id) 1───* idempotency_keys(report_id)  ON DELETE CASCADE
        │
        │  deleting a report
        ▼
   its idempotency key is removed automatically
        │
        ▼
   a retry arriving later, carrying that key, is treated as a NEW report
   and creates a second stored report
```

This is the central retention risk. Two consequences drive the design:

1. **Key expiry must not precede report expiry.** A key that is removed while its report is still
   retained means a retry of a live report creates a duplicate. Therefore the retention tool removes
   a key **only together with, or after, its report** (RR-6.1). With the current foreign key this
   happens automatically, and a separate key-expiry step is therefore unnecessary — and would be
   actively harmful if configured to run earlier than report retention.
2. **The window must exceed the realistic retry window.** A reporter retrying minutes or hours later
   is inside the window; a report deleted after that window will not be resurrected by a stale retry
   in practice. The window length itself is a policy decision and is not invented here.

**Consequence to disclose.** The privacy notice must state that a report may be deleted after its
retention window and that a retry submitted after deletion may be stored as a new report (PR-9.2).

**Alternative considered and deferred.** A tombstone table — keeping the key row with a nulled
`report_id` — would let a late retry be recognised as a duplicate and rejected rather than re-created.
It requires a schema migration and a policy decision about how long tombstones live. It is out of M.4
(XR-13) and is recorded as a future option.

### 8.3 Tool design

```
$ python retention.py --dry-run
[retention] window: 30 days (from SAFESIGNAL_REPORT_RETENTION_DAYS)
[retention] reports older than 2026-10-01T00:00:00Z: 412
[retention] idempotency keys that would be removed with them: 388
[retention] dry run: nothing was deleted

$ python retention.py
[retention] window: 30 days
[retention] deleted 412 reports, 388 idempotency keys, 0 rows locked
[retention] completed at 2026-10-21T03:14:07Z
```

Behaviour:

- **Fail closed.** `SAFESIGNAL_REPORT_RETENTION_DAYS` unset, empty, zero or non-numeric → the tool
  prints a message naming the variable and exits non-zero, deleting nothing (FR-8.1).
- **One statement, one transaction.** A single `DELETE ... WHERE created_at < %s` inside one
  transaction. Row locks are taken on the deleted rows only; the API's inserts touch different rows,
  so submission is not blocked beyond statement duration (FR-7.6).
- **Batched.** For large tables the delete runs in bounded batches with a short pause between them,
  so the transaction does not hold a long snapshot. The batch size is a constant.
- **Idempotent.** Running it twice in a row deletes nothing the second time.
- **Summary output.** Counts and timestamps only. No report content, no ids, no codes (SR-5.3).
- **Run summary file.** A JSON summary written to a path outside the repository (git-ignored), used by
  the runbook and by monitoring to detect a failed or skipped run (OR-1.2, OR-1.3).
- **No migration required.** The tool uses the existing `reports.created_at` column. An index on
  `reports (created_at)` already exists (`apps/backend/migrations/001_init.sql:21`); an index on
  `idempotency_keys.created_at` is not needed because keys are removed by cascade.

### 8.4 Scheduling

Run from `cron` or a systemd timer, daily, at a low-traffic hour. The runbook states the schedule, the
required environment (it needs `DATABASE_URL`), the expected output, and how to tell a failed run
from a run that found nothing (OR-1.1, OR-1.2).

### 8.5 What is not decided

The retention period itself, whether closed cases should be deleted sooner, the backup retention
period, and whether a reporter-initiated deletion path is needed are all founder and legal decisions
(FR-8.2, FR-8.3, OR-2.3, PR-11.1). The mechanism ships; the policy does not.

---

## 9. Deployment security architecture

### 9.1 Topology

```
                    ┌──────────────────────────────────────────┐
   Phone (Android)  │  TLS 1.2+                               │
   ────────────────►│  ┌────────────────────────────────────┐  │
                    │  │ reverse proxy (nginx / Caddy)      │  │
   Browser ─────────┤  │  • TLS termination + HSTS           │  │
   ────────────────►│  │  • overwrites X-Forwarded-For       │  │
                    │  │  • security headers                 │  │
                    │  │  • bodyless access logs             │  │
                    │  └──────────────┬─────────────────────┘  │
                    │                 │ 127.0.0.1:8000            │
                    │  ┌──────────────▼─────────────────────┐  │
                    │  │ uvicorn (ONE worker)                │  │
                    │  │  --proxy-headers                    │  │
                    │  │  --forwarded-allow-ips=127.0.0.1    │  │
                    │  └──────────────┬─────────────────────┘  │
                    │                 │                          │
                    │  ┌──────────────▼─────────────────────┐  │
                    │  │ PostgreSQL (localhost / socket)     │  │
                    │  │  role: safesignal_app (least priv)  │  │
                    │  │  port not exposed                   │  │
                    │  └─────────────────────────────────────┘  │
                    └──────────────────────────────────────────┘
                              │
                              ▼  nightly, encrypted
                    ┌──────────────────────────────────────────┐
                    │ off-host backup storage                  │
                    └──────────────────────────────────────────┘
```

### 9.2 Controls and where they live

| Control | Mechanism | Requirement |
|---|---|---|
| TLS, HSTS | Reverse proxy | SR-6.1, SR-9.1 |
| Real client identity | Proxy **overwrites** `X-Forwarded-For`; Uvicorn trusts only `127.0.0.1` | SR-7.1, SR-7.2 |
| CORS allow-list | `SAFESIGNAL_CORS_ORIGINS` env, parsed at startup; production requires it | SR-8.1, SR-8.2 |
| Security headers | Reverse proxy `add_header` directives | SR-9.1 |
| CSP for the web app | Reverse proxy `add_header` on the static web app | SR-9.2 |
| Environment validation | `apps/backend/main.py` lifespan check | FR-9.1 |
| Fail-closed admin key | Existing `require_admin` | SR-1.1 |
| Single worker | Service unit with exactly one worker | SR-11.2 |
| Least-privilege DB role | `safesignal_app` role, `DATABASE_URL` only | existing (`DATABASE.md`) |
| DB not exposed | PostgreSQL bound to localhost or a unix socket | existing (`DATABASE.md:25`) |
| Rate limiting | Per-process; documented single-worker constraint | SR-11.1 |
| Readiness | `GET /health/ready` monitored | OR-3.1 |
| Backups | Nightly encrypted `pg_dump -Fc` off-host; restore tested | OR-2.1, OR-2.2 |
| Log hygiene | Rotated logs; no bodies; no sensitive headers; retention ≤ report retention | SR-5.1, OR-4.1, OR-4.2 |
| Rate-limit-by-address honesty | Documented as unsupported unless the proxy overwrites the header | SR-7.3 |

### 9.3 Environment variables for a pilot deployment

| Variable | Required in production | Purpose |
|---|---|---|
| `SAFESIGNAL_ENV` | yes (`production`) | Selects production behaviour |
| `DATABASE_URL` | yes | PostgreSQL connection (least-privilege role) |
| `SAFESIGNAL_ADMIN_KEY` | yes, ≥ 32 characters | Shared admin secret |
| `SAFESIGNAL_CORS_ORIGINS` | yes | Comma-separated origin allow-list |
| `SAFESIGNAL_REPORT_RETENTION_DAYS` | no (inert until set) | Report retention window |
| `SAFESIGNAL_REPORT_RATE_LIMIT` / `_WINDOW` | optional | Report rate limit |
| `SAFESIGNAL_ADMIN_FAIL_LIMIT` / `_WINDOW` | optional | Admin lockout |
| `SAFESIGNAL_DB_POOL_MAX` | optional | Pool size (default 5) |
| `OPENROUTER_API_KEY` | optional | Assistant only; omit if the assistant is out of pilot scope |

Startup validation (§ FR-9) checks the first four and refuses to start otherwise, naming only the
variable, never its value (FR-9.2).

### 9.4 Hosting comparison — required before provisioning

The provider is **not** chosen by this specification. The comparison shall be recorded against the
following requirements (OR-8.1, OR-8.2):

| Criterion | Why it matters here |
|---|---|
| Data residency | Determines the DPA position and where incident data physically sits |
| Managed PostgreSQL availability and version | M.4 verifies against PostgreSQL 16/18; the target must match what was tested |
| Encrypted backups + off-host copy | Required by OR-2.1 |
| TLS and reverse-proxy control | Required by SR-6.1, SR-7.1 |
| Inbound firewall / port exposure control | The database must not be reachable from the internet |
| Cost ceiling | A pilot is a bounded, supervised activity |
| SSH / console access and audit log | Needed for the operator runbook (OR-7.1) |
| Incident-response and data-export support | Needed if a report must be produced or erased on request |

At least two candidates shall be compared and the decision recorded **before** a server is
provisioned (OR-8.2). This is an external dependency; the repository shall not assume a provider.

### 9.5 Web build for the pilot

The web app is served with `VITE_PROTOTYPE=false`, so the mock admin screen renders the
"Not available" panel instead of mock cases (`apps/frontend/src/screens/AdminScreen.tsx:27-37`,
`apps/frontend/src/lib/prototype.ts:1-6`). The flag is cosmetic and is not an authorisation
mechanism; the backend's admin key remains the only gate (SR-2.1).

---

## 10. Failure modes and recovery

| # | Failure | Detection | Behaviour | Recovery |
|---|---|---|---|---|
| F-1 | Write interrupted (process killed mid-save) | Checksum mismatch or absent key on read | Record is absent or rejected as corrupt; never partially submitted | User re-enters and saves again |
| F-2 | Stored record corrupt | Checksum mismatch | Record deleted; user told; app continues | User re-enters |
| F-3 | Record unparseable | JSON parse error | Treated as F-2 | User re-enters |
| F-4 | Deletion fails (keystore error) | Exception from the store | User told plainly; record retained | "Try again" / "Exit anyway" on Quick Exit; manual discard retries |
| F-5 | Server acknowledgement uncertain (timeout) | Client timeout / socket error | Record and key retained; outcome stated as unknown | User taps Submit again; same key → same report |
| F-6 | Server returns 409 for a restored key | 409 | New key minted; user told the report will be sent as new | User submits again |
| F-7 | Server returns 429 | 429 + `Retry-After` | Record retained; wait time shown (existing behaviour) | User retries after the wait |
| F-8 | Server returns 503 (database down) | 503 | Record retained; generic message, no server detail | User retries; nothing was stored |
| F-9 | App killed between "Save" and "Submit" | Process death | Record on device survives; key survives | Restore prompt on next launch |
| F-10 | App killed *during* submission | Process death | Record survives with its key | Restore prompt; retry uses the same key; server dedupes |
| F-11 | Retention job deletes a report the user is retrying | Race between the job and a retry | The retry creates a new report | Disclosed in the privacy notice (PR-9.2) |
| F-12 | Reverse proxy does not overwrite `X-Forwarded-For` | All clients share one rate-limit bucket | Rate limiting becomes ineffective or over-broad | Documented as unsupported (SR-7.3); deployment checklist verifies it |
| F-13 | Admin key leaked | Not detectable by the system | Full report read access for the holder | Rotation procedure in the runbook (OR-7.1) |
| F-14 | Keystore unavailable at save time | Store reports unavailable | Saving disabled with an explanation; in-memory reporting still works | Retry later; no plaintext fallback (§ 4.4) |
| F-15 | Backup restore is corrupt or empty | Restore test | Known before the pilot | Monthly restore test (OR-2.2) |

### 10.1 Recovery principle

No failure mode above may be handled by silently proceeding as if it did not happen. Each has an
explicit, user-visible outcome: absent, corrupt (deleted and reported), failed (reported and
retained), or unknown (retained and reported as unknown).

---

## 11. Risks, trade-offs, and unresolved decisions

### 11.1 Trade-offs accepted

| Trade-off | Chosen | Rejected alternative | Rationale |
|---|---|---|---|
| Offline protection | One encrypted pending record | A queue with automatic flush | Fewer failure modes; no background execution; no automatic submission |
| Storage technology | `flutter_secure_storage`, one value | Plain `shared_preferences`; SQLite + crypto | Platform keystore, minimal code, no second crypto dependency |
| Screenshots | Blocked app-wide via native `FLAG_SECURE` | Allowed; or `flutter_windowmanager` | No new dependency; native covers the whole Flutter surface; the copy button remains |
| Clipboard | Never read, never cleared | Read-then-clear; unconditional clear | The app does not own the clipboard; disclose instead |
| Web drafts | In memory, as today | `sessionStorage` / IndexedDB | Avoids storing incident text in the browser at all |
| React key policy | Extracted to a pure module | Left inline in `App.tsx` | Makes the rule testable; behaviour unchanged |
| Retention | Configured, fail-closed, no default | Hard-coded period | Avoids inventing legal policy; avoids accidental deletion |
| Key expiry | Coupled to report expiry | Independent shorter key TTL | A shorter key TTL would create duplicates for retained reports |
| Backend deps | Unchanged | Adding a scheduler library | A cron entry needs no dependency |
| Admin identity | Deferred, documented custody | Building an identity system now | Not required for a single-operator pilot; explicitly deferred |
| Migrations | None in M.4 | Adding audit/tombstone tables | Avoids schema churn before the policy decisions |

### 11.2 Unresolved decisions — blocking

| ID | Decision | Blocks | Owner |
|---|---|---|---|
| D-A | Report retention period, and whether closed cases are deleted sooner | FR-8.2, FR-8.3, PR-9.3, OR-2.3 | Founder + legal |
| D-B | Backup retention period | OR-2.3 | Founder + legal |
| D-C | Whether a reporter-initiated deletion path is needed | PR-9.1 | Founder + legal |
| D-D | Consent semantics: capture `consentToShare` for real, or remove it from the UI and schema | PR-3.2 | Founder + legal |
| D-E | Hosting provider | OR-8.1, OR-8.2, and the whole deployment task | Founder |
| D-F | Whether the AI assistant is in pilot scope | PR-7.1, PR-7.2 | Founder |
| D-G | Accepting the screenshot-blocking trade-off of FLAG_SECURE | § 7.1 | Founder |
| D-H | Whether a new pub dependency (`flutter_secure_storage`) is acceptable | § 4.1, SR-3.1 | Founder |
| D-I | Whether a new npm dev dependency set (test harness) is acceptable | OR-5.3 | Founder |
| D-J | Admin key custody owner and rotation trigger | SR-1.3 | Founder |
| D-K | Pilot scope, participants, start date, and the supervising operator | The validation tasks | Founder |
| D-L | Response team's actual metadata needs (timestamp precision) | PR-11.1 | Founder (depends on D-K) |

### 11.3 Unresolved risks

| Risk | Severity | Mitigation in M.4 | Residual |
|---|---|---|---|
| A client-side saved report is still sensitive data on a lost or stolen phone | High | Keystore encryption, app-private storage, backup exclusion, short expiry, delete on success/discard/Quick Exit | A rooted device or a compromised OS defeats keystore protection |
| Keystore-backed storage enlarges the app's attack surface | Medium | One dependency, one value, small code | Accepted; the alternative (plaintext) is worse |
| The retention tool deletes a report a reporter is still retrying | Medium | Window far exceeds the retry window; disclosed | Documented, not eliminated (F-11) |
| A shared admin key is a single point of compromise | High | Fail-closed, constant-time compare, lockout, single copy, rotation trigger, runbook | Not eliminated; deferred identity work |
| Rate limiting is ineffective behind a misconfigured proxy | Medium | Deployment checklist verifies the overwrite | Depends on operator discipline |
| The pilot collects real reports before legal review completes | High | Pilot-readiness checklist refuses to sign off while D-A…D-D are open | Process control only |
| FLAG_SECURE frustrates users who want to screenshot the reference code | Low | Copy button remains; the confirmation screen explains | Accepted trade-off (D-G) |
| Device clock manipulation extends the expiry window | Low | Expiry is a best-effort bound; deletion on success/discard/Quick Exit covers the normal case | Documented |

---

## 12. Testing strategy

### 12.1 Layered approach

| Layer | Tool | Scope | Gate |
|---|---|---|---|
| Backend unit + API | `pytest` (existing) | Idempotency, rate limiting, admin auth, DB config | CI, every push |
| Backend integration | `pytest` with a PostgreSQL service container | Transactional duplicate prevention, persistence, outage mapping, retention deletion | CI, every push (currently self-skips — must be fixed) |
| Backend tooling | `pytest` | `retention.py` dry-run, fail-closed config, batched delete, cascade accounting | CI |
| Flutter unit | `flutter test` | Store interface, checksum, expiry, key policy, controller transitions | CI |
| Flutter widget | `flutter test` | Save / restore / discard / error banners / Quick Exit with a saved record, both locales, 2× text scale | CI |
| Flutter integration (opt-in) | `flutter test test/integration` with a real uvicorn | Timeout, late acceptance, unchanged retry, **and restart-and-restore** | Manual / scheduled |
| React unit | Vitest | `buildPayload`, `newSubmissionKey`, `submissionKeyPolicy` | CI |
| React flow | Vitest + Testing Library | The reporting flow's submit, retry and failure messaging | CI |
| Device | Manual procedure | FLAG_SECURE, backup exclusion, Quick Exit, TalkBack, low-end performance, restart | Documented evidence |
| Controlled usability | Manual protocol | Simulated incidents, English/Kiswahili | Documented evidence |

### 12.2 Scenarios that must be covered

**Network interruption**
1. Request times out with no connectivity → error banner, record retained, same key held.
2. Request times out but the server later accepts it → retry returns the original code; exactly one
   stored report. (Extends `apps/mobile/test/integration/backend_timeout_retry_test.dart`.)
3. Connection refused / DNS failure → the existing `SubmitNetworkFailure` path, record retained.
4. Interruption during the save write → no partially valid record (F-1).
5. Server returns 503 → nothing stored; record retained.

**Duplicate submission**
6. Two identical submissions with the same key → one report (existing backend test).
7. 16 concurrent same-key submissions → one report (existing backend test).
8. Same key, different payload → 409, original untouched (existing backend test).
9. **New:** save → kill the app → restore → submit → the server sees the same key → one report.
10. **New:** save → kill the app → restore → edit the content → submit → a new key is minted and the
    user is told.

**Android process restart and restoration**
11. Save → force-stop the app → relaunch → the restore prompt appears with the saved time.
12. Restore → the draft fields match the saved payload.
13. Restore → submit → the request body is byte-identical to the saved payload.
14. Save → wait past expiry (time simulated in the test) → relaunch → the record is gone and the user
    is told.

**Quick Exit with a saved draft**
15. Save → Quick Exit → the store is empty afterwards.
16. Save → simulate a deletion failure → Quick Exit → the user is told and offered Try again /
    Exit anyway.
17. Save → confirm → the store is empty.

**Low-end Android performance**
18. Save and restore complete within a stated budget on the reference low-end device, with no jank
    on the reporting screens.
19. Cold start to first screen is not materially slower with the store present.

**English/Kiswahili accessibility**
20. Every new string exists in both locales (an automated parity test, extending the existing one).
21. No overflow at 2× text scale in either locale (automated).
22. Save / restore / discard are reachable and operable by TalkBack alone (manual, device).

**Controlled usability**
23. Simulated-incident walkthroughs with participants who have not used the app, in English and
    Kiswahili, covering: understanding what is sent, understanding what is saved on the phone,
    understanding that Quick Exit does not erase system traces, and completing a report while
    "offline".

### 12.3 Evidence rules

A scenario is **not** claimed as passed without evidence:

- Automated scenario → a named test file and a passing run.
- Device scenario → a dated note recording the device model, Android version, the steps, and the
  observed result.
- Usability scenario → a note recording the protocol, the participant count, and the observed
  outcomes, using simulated incidents only.

No physical-device, production or legal verification may be claimed without such a record
(OR-6.2).

---

## 13. File-change summary

### Flutter — `apps/mobile/`

| File | Change |
|---|---|
| `lib/storage/pending_draft.dart` | **New.** `PendingDraft` record + checksum helpers |
| `lib/storage/pending_draft_store.dart` | **New.** Abstract store interface |
| `lib/storage/secure_pending_draft_store.dart` | **New.** `flutter_secure_storage` implementation |
| `lib/storage/in_memory_pending_draft_store.dart` | **New.** Test double / non-Android fallback |
| `lib/api/submission_controller.dart` | **Extend.** Pending-state transitions; restore installs key + signature; delete on success |
| `lib/widgets/quick_exit_button.dart` | **Extend.** Delete the pending record before exit; failure path |
| `lib/screens/welcome_screen.dart` | **Extend.** Restore prompt on start |
| `lib/screens/review_screen.dart` | **Extend.** Save-for-later action, saved indicator, discard action |
| `lib/screens/confirmation_screen.dart` | **Extend.** Screenshot note |
| `lib/l10n/app_en.arb`, `app_sw.arb` | **Extend.** New strings in both locales |
| `android/app/src/main/kotlin/.../MainActivity.kt` | **Extend.** `FLAG_SECURE` |
| `android/app/src/main/AndroidManifest.xml` | **Extend.** `allowBackup="false"`, `dataExtractionRules` |
| `android/app/src/main/res/xml/data_extraction_rules.xml` | **New.** Backup exclusion rules |
| `pubspec.yaml` | **Add.** `flutter_secure_storage` (pending D-H) |

### React — `apps/frontend/`

| File | Change |
|---|---|
| `src/lib/submissionKeyPolicy.ts` | **New.** Pure key-reuse policy |
| `src/App.tsx` | **Modify.** Use the policy module (behaviour unchanged) |
| `src/screens/NextStepScreen.tsx` | **Modify.** Failure copy about reload losing the key |
| `package.json` | **Add.** Dev-only test harness (pending D-I) |

### Backend — `apps/backend/`

| File | Change |
|---|---|
| `retention.py` | **New.** Retention CLI |
| `main.py` | **Modify.** Startup environment validation; CORS from configuration |
| `.env.example` | **Modify.** New variables documented (no values) |
| `deploy/nginx-safesignal.conf.example` | **New.** Reverse proxy template |
| `deploy/safesignal-api.service.example` | **New.** Service unit template |
| `deploy/backup-postgres.sh.example` | **New.** Backup script template |
| `deploy/README.md` | **New.** What to fill in, what to verify |
| `tests/test_retention.py` | **New.** Retention tool tests |
| `tests/test_config.py` | **New.** Startup validation tests |

### Documentation

| File | Change |
|---|---|
| `docs/PRIVACY.md` | **New.** Privacy notice |
| `docs/PILOT_READINESS.md` | **New.** Readiness checklist and evidence register |
| `docs/RUNBOOK.md` | **New.** Operator runbook |
| `docs/SECURITY.md` | **Modify.** New controls, new limits |
| `docs/API.md` | **Modify.** CORS configuration note |
| `docs/CHECKLIST.md` | **Modify.** M.4 status |
| `docs/ROADMAP.md` | **Modify.** M.4 position |
| `docs/research/M4_*.md` | **Unchanged** |

## 14. What is explicitly not changed

- The `reports` table, its constraints and its indexes (XR-13).
- The `POST /api/reports` request/response contract and the `Idempotency-Key` contract (XR-14).
- `apps/backend/store.py`, `apps/backend/store_pg.py` and the idempotency mechanism itself (SR-10).
- The backend's production dependencies (XR-12).
- The React reporting screens, except the failure copy on the next-step screen (FR-6.1, FR-6.3).
- The Flutter reporting screens' layout and step structure.
- The existing M.3 design tokens, component library, widget library and animations.
- The Kiswahili translation of existing strings (only new strings are added, in both locales).
- The assistant implementation, beyond documenting its data handling for the pilot decision (PR-7).
