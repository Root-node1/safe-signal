# Implementation Tasks — SafeSignal M.4 Reliability, Privacy & Controlled Validation

Each task is small, sequential and independently verifiable. Complete them in order; later tasks build
on earlier ones. **Do not implement anything until the founder approves Task 1.**

**Rules for every task**

- Documentation and implementation tasks are separated deliberately. A documentation task is finished
  when the document exists and says what it must; an implementation task is finished when its
  acceptance criteria pass.
- No task may change the report API contract, the idempotency mechanism, the `reports` table, the
  React reporting screens' structure, or the M.3 design tokens. If a task seems to require that, stop
  and raise it.
- No task may add a backend production dependency (XR-12).
- Do not commit or push until the milestone is approved.
- Tasks marked **[BLOCKED]** cannot start until the named decision is made. They are listed so the
  dependency is visible, not so work can be guessed at.

**Task groups**

| Group | Tasks | Theme |
|---|---|---|
| A — Documentation and decisions | T-01 … T-04 | Write the documents the pilot needs before it needs them |
| B — Test foundations | T-05 … T-07 | Make the existing suites actually run in CI |
| C — React | T-08, T-09 | Preserve behaviour, make the limitation visible |
| D — Flutter pending report | T-10 … T-20 | The core M.4 feature |
| E — Android hardening | T-21, T-22 | Device-level privacy |
| F — Backend | T-23 … T-25 | Retention and configuration |
| G — Deployment | T-26, T-27 | Pilot baseline and runbook |
| H — Verification | T-28 … T-33 | Prove the claims, then declare readiness |

---

# Group A — Documentation and decisions

## Task 01 — Write the privacy notice

**Status:** complete (21 October 2026). `docs/PRIVACY.md` written and checked against the behaviour
implemented in the repository. The retention period and the backup retention period are carried as
marked placeholders pending D-A and D-B. T-04 still has to confirm each claim against the code.

**Objective:** Produce `docs/PRIVACY.md`, the plain-language document the pilot depends on. It must
describe what SafeSignal does today, not what it might do later.

**Components:** `docs/PRIVACY.md` (new).

**Depends on:** none.

**Requirements:** PR-1.1, PR-2.1, PR-2.2, PR-3.1, PR-7.1, PR-7.2, PR-7.3, PR-8.2, PR-9.1, PR-9.2, PR-10.3, PR-11.1.

**Content**

1. What a report contains and what it never contains (no name, no phone number, no GPS, no account).
2. What is stored on the phone, when it is stored, that it is encrypted, that it is deleted on
   success, on discard and on Quick Exit, and that it expires.
3. What Quick Exit does **not** erase: the Android recent-apps thumbnail, screenshots, keyboard
   history, the clipboard, and anything already sent to the server or held in server backups.
4. That a report may be identifiable from its content — time, route, area, vehicle, operator — and
   that SafeSignal makes no guarantee of anonymity.
5. That SafeSignal does not share reports with SACCOs, police, NGOs or anyone else, and does not
   dispatch anyone.
6. Retention: how long reports are kept, how they are deleted, how backups are treated, and that a
   retry after deletion may be stored as a new report.
7. The clipboard note: a copied reference code may remain in the device's clipboard history.
8. The assistant: if the assistant is in pilot scope, name the third-party provider and state that
   free-text messages are sent to it after pattern redaction, and that redaction cannot catch every
   detail a person writes.
9. A contact route for questions and for asking about a stored report.

**Acceptance criteria**

- Every claim in the notice matches the implemented behaviour at the time of writing.
- The notice contains **no** statement that a report is anonymous, untraceable or confidential.
- The retention period appears as a clearly marked placeholder (`[RETENTION PERIOD — pending D-A]`)
  until D-A is decided.
- The notice states that SafeSignal does not erase system-level traces.

**Automated verification:** none — this is a document. A reviewer check-list task (T-04) confirms each
claim against the code.

**Manual verification:** read it against `docs/SECURITY.md` and the app's own UI strings; confirm no
statement contradicts any screen.
---

## Task 02 — Record the retention and deletion policy

**Status:** complete (21 October 2026). `docs/RETENTION.md` written: the data-lifetime decision
record, with every value in the decision table marked undecided pending D-A, D-B, D-C and D-D, so
the retention tool (T-24) stays inert until a period is approved. The idempotency-key /
report-retention coupling is stated once, in `docs/RETENTION.md` § 3, and is now referenced from
`requirements.md` RR-6.1. The founder's sign-off (§ 9 of the file) is still outstanding; the file is
left marked *undecided*, which is the safe path and does not require a decision to have been made.

**Objective:** Produce `docs/RETENTION.md`: the decision record for data lifetime, including the
values that are still undecided. This is what the retention tool and the privacy notice will read
from.

**Components:** `docs/RETENTION.md` (new).

**Depends on:** none. The decision itself is **BLOCKED — D-A, D-B, D-C, D-D (founder + legal)**.

**Requirements:** FR-8.2, FR-8.3, OR-2.3, PR-9.3, RR-6.2.

**Content**

1. The decision table, with every row still marked *undecided* unless D-A…D-D are resolved:
   report retention for open reports; report retention for closed reports; idempotency-key retention;
   backup retention; deleted-report tombstones; reporter-initiated deletion.
2. The rule that idempotency-key retention may not be shorter than report retention, with the
   duplicate-creation consequence explained.
3. The consequence that deleting a report cascades to its key, so a late retry becomes a new report.
4. The operational procedure: how the job is scheduled, what a run looks like, how a failure is
   detected, and who may authorise a manual delete.
5. A change-control rule: the policy file is the single source of truth and is edited only with the
   founder's approval.

**Acceptance criteria**

- No retention period is stated as if it were decided; undecided values are visibly marked.
- The idempotency-key / report-retention coupling is stated in one place and referenced by
  `requirements.md` RR-6.1.
- The file names who owns the decision.

**Automated verification:** none.

**Manual verification:** the founder signs off, or the file is left marked *undecided* and T-24's
tool remains inert.
---

## Task 03 — Compare hosting options and record the decision

**Status:** partial — comparison complete; host and database recorded, deployment inputs outstanding
(21 October 2026).
`docs/deploy/HOSTING_COMPARISON.md` written: the eight criteria from design § 9.4 with proposed
weights, three candidates scored against every criterion (Hetzner Cloud with self-managed
PostgreSQL, DigitalOcean with managed PostgreSQL, Railway with its PostgreSQL deployment model),
the pricing evidence with sources, currency and date checked, the cost model, the operational
responsibility differences, the security and privacy risks, the scoring methodology, and a register
of unverified claims. The comparison is unchanged and was not the basis of the choice. The founder
has since recorded the decision: a **Contabo Cloud VPS 4** (purchased, with `zindika.app` connected
and the firewall configured but **not independently audited**) for the application, and **Neon
PostgreSQL** for the data (existing project `agent-gate`, Frankfurt), whose **intended use for
SafeSignal is not yet confirmed**. The **VPS region, the PostgreSQL server version, the recovery
procedures and the deployment readiness remain unverified**, and **automatic Contabo backups are
not enabled**. The selection is recorded in § 10 of that file with the reasons still open; D-E is
**partially discharged** and the operational inputs (residency position, cost ceiling, named
operator, firewall audit, intended use of the Neon project) remain open decisions. The PostgreSQL
version criterion cannot be closed until T-31 has run against the real server.

**Objective:** Produce `docs/deploy/HOSTING_COMPARISON.md` comparing at least two hosting options
against the pilot's requirements, and recording the decision.

**Components:** `docs/deploy/HOSTING_COMPARISON.md` (new).

**Depends on:** none to write. The decision itself is **BLOCKED — D-E (founder)**.

**Requirements:** OR-8.1, OR-8.2.

**Content**

1. The criteria from design § 9.4: data residency, managed PostgreSQL availability and version,
   encrypted backups and off-host copy, TLS and reverse-proxy control, inbound firewall control, cost
   ceiling, SSH/console access and audit log, incident-response and data-export support.
2. At least two candidates, each scored against the criteria, with the cost estimate for the pilot's
   expected load.
3. The decision, the date, the reasons, and what would trigger a change.
4. An explicit statement that the provider was not chosen by the code or by this specification.

**Acceptance criteria**

- Two or more candidates compared against every criterion.
- The chosen provider is named, with the reasons, before any server is provisioned.
- The PostgreSQL version offered is one M.4 has been verified against (T-05, T-31).

**Automated verification:** none.

**Manual verification:** the founder records the decision in the file.
---

## Task 04 — Audit the exclusions

**Status:** complete — audit written, manual review outstanding (21 October 2026).
`docs/M4_SCOPE_CHECKLIST.md` written: all sixteen exclusions have a recorded search, a result and a
file-and-line citation, and the privacy notice, the retention record, SECURITY.md, API.md and
CHECKLIST.md were checked claim by claim against the React, Flutter, FastAPI and PostgreSQL code.
Nine exceptions (C-1 … C-9) are listed with an explanation and a task to resolve them; four of them
(C-1, C-2, C-3, C-7) need a founder decision to change the scope of another task or to add one. The
machine-checkable half of the audit is scripted in `apps/backend/tests/test_m4_scope_exclusions.py`
(31 checks: 30 passing, 1 expected failure until the C-7 citation drift is corrected), so it runs in
the existing backend CI job and a later change re-opens the check. The **manual verification is
outstanding**: a reviewer must read the results against the repository and accept the exceptions and
their resolution tasks. No application code, dependency, migration, workflow, infrastructure or
approved document was changed, no decision was taken or narrowed, the T-03 hosting decision (D-E)
remains open, and no T-05 work was started.

**Objective:** Produce `docs/M4_SCOPE_CHECKLIST.md`: a line-by-line check of `requirements.md` § 7
(XR-1 … XR-16) against the repository, so the exclusions are verified rather than asserted.

**Components:** `docs/M4_SCOPE_CHECKLIST.md` (new).

**Depends on:** none.

**Requirements:** XR-1 … XR-16, SR-1.2, SR-2.2, SR-10.1, SR-10.2, PR-1.1, PR-1.2, PR-3.1, PR-3.2, PR-3.3, PR-4.1, PR-5.1, PR-5.2, PR-6.1, PR-6.2, PR-10.1, PR-10.2, RR-5.2, PR-11.2.

**Method:** for each exclusion, record the search performed (file, pattern or route) and the result.
Examples: no `/api/reports` GET route is public (`apps/backend/reports.py:61-63`); the prototype admin
screen uses mock data only (`apps/frontend/src/screens/AdminScreen.tsx:23-24`); no background
execution permission is declared in `apps/mobile/android/app/src/main/AndroidManifest.xml`; the
backend dependency list is unchanged (`apps/backend/requirements.txt`); no column was added to
`reports` (`apps/backend/migrations/001_init.sql`).

**Acceptance criteria**

- All sixteen exclusions have a recorded check and a result.
- Each result cites a file and line.
- Any exception is listed with an explanation and a task to resolve it.

**Automated verification:** the checks that can be scripted (dependency lists, manifest permissions,
route table, schema diff against `001_init.sql`) are scripted in a small script under
`apps/backend/tests/` or `scripts/`, so a later change re-opens the check.

**Manual verification:** review the results against the repository.

---

# Group B — Test foundations

## Task 05 — Run the PostgreSQL integration suite in CI

**Status:** complete — implemented, locally verified and **verified in GitHub Actions**
(21 October 2026).
`.github/workflows/ci.yml`: the backend job now has a `postgres:18` service container with a
`pg_isready` health check, installs the PostgreSQL client in the job only (the runtime dependency
set is unchanged, XR-12), creates the disposable `safesignal_test` database — a name that satisfies
the suite's existing `_test` guard, which was kept exactly as it is — and sets `TEST_DATABASE_URL`
for the job. `apps/backend/tests/test_store_postgres.py` was **not** modified: the skip condition
needed no adjustment, and no existing test was deleted or weakened. `docs/CHECKLIST.md` § 3, § 4 and
§ 9 updated. Verified locally against a disposable `postgres:18` container (PostgreSQL 18.6): the
suite goes from **86 passed, 1 skipped** (module self-skip, no `TEST_DATABASE_URL`) to **94 passed,
0 skipped** — the eight integration tests now run — with three consecutive identical runs, the
`_test` guard still refusing a non-`_test` database, the migration ledger showing `001_init` applied
in order, and the `reports` column set unchanged. Ruff clean.
**CI verification (21 October 2026):** GitHub Actions run **39652159825** on commit `88a07ba`
(https://github.com/Root-node1/safe-signal/actions/runs/39652159825) — the `backend` job
**succeeded**; the log shows the `postgres:18` container started with the `pg_isready` health check
and the disposable credentials, `ruff` reporting "All checks passed!", and `pytest -q -rs` reporting
**94 passed, 1 xfailed** with **zero skips** — the PostgreSQL integration tests execute, they do not
self-skip. The one expected failure is T-04's C-7 citation check, which is deliberately still armed.
No production or Neon database was contacted, no infrastructure was provisioned, and the T-04
findings (C-1, C-2, C-3, C-7) were not touched.

**Objective:** Make `apps/backend/tests/test_store_postgres.py` actually run on every push. Today it
self-skips unless `TEST_DATABASE_URL` points at a database whose name ends in `_test`, and CI provides
none, so the production storage path is untested in CI.

**Components:** `.github/workflows/ci.yml`, `apps/backend/tests/test_store_postgres.py` (only if the skip
condition needs adjusting), `docs/CHECKLIST.md`.

**Depends on:** none.

**Requirements:** OR-5.1, OR-5.4, SR-1.1, SR-10.3, RR-1.1.

**Changes**

1. Add a `postgres:18` service container to the backend CI job, with a health check.
2. Create a `safesignal_test` database (name ends in `_test`, satisfying the existing guard) and set
   `TEST_DATABASE_URL` for the job.
3. Install the PostgreSQL client only in the CI job; the runtime dependency set stays unchanged
   (XR-12).
4. Keep the existing `_test` name guard as-is — it is a safety property, not an obstacle.
5. Update `docs/CHECKLIST.md` § 4.

**Acceptance criteria**

- The CI log shows the PostgreSQL tests running, not skipping.
- The suite count rises from the in-memory-only figure to include the integration tests.
- No existing test was deleted or weakened.

**Automated verification:** the CI run itself. Confirm with `pytest -q` locally against a `_test`
database that the same set passes.

**Manual verification:** read the CI log to confirm zero skips in the PostgreSQL module.
---

## Task 06 — Add a Flutter CI job

**Status:** complete — implemented, locally verified and **verified in GitHub Actions**
(21 October 2026).
`.github/workflows/ci.yml` gains a `mobile` job: the Flutter SDK is pinned to **3.47.7** — the
version recorded in `docs/CHECKLIST.md` § 7, channel stable, installed with
`subosito/flutter-action@v2` — the pub cache is kept warm by that action's `cache: true` and the
Gradle cache by an `actions/cache@v4` step keyed on the Gradle wrapper properties, and the job runs
`flutter pub get`, `flutter analyze --fatal-infos` and `flutter test`. The opt-in integration test
under `apps/mobile/test/integration` is **not executed**: it self-skips unless
`SAFESIGNAL_BACKEND_IT=1`, because it needs a live backend and a loopback port, and it stays a
manual/scheduled task (T-29); the CI log shows it as skipped. Verified locally with the same
SDK: `flutter pub get` clean, `flutter analyze --fatal-infos` reports **no issues**, `flutter test`
gives **159 passed, 1 skipped** (the opt-in test), and the opt-in test on its own reports *"Skip:
set SAFESIGNAL_BACKEND_IT=1 to run against a local backend"*. The frontend and backend jobs are
otherwise untouched — the only change to them is T-05's `pytest -q -rs`. No application code,
dependency, lockfile or project file was changed: `apps/mobile/pubspec.yaml`, `pubspec.lock` and
every Dart source are byte-identical.
**CI verification (21 October 2026):** GitHub Actions run **39652159825** on commit `88a07ba`
(https://github.com/Root-node1/safe-signal/actions/runs/39652159825) — the `mobile` job
**succeeded**; the log shows Flutter 3.47.7 with Dart 3.13.5, `flutter analyze --fatal-infos`
reporting "No issues found!", and `flutter test` reporting **"159 tests passed, 1 skipped"** — the
single skip is the opt-in integration test, which is the expected result. The T-04 findings (C-1,
C-2, C-3, C-7) were not touched.

**Objective:** Run `flutter analyze` and `flutter test` on every push. Today the Flutter suite runs
only on a developer machine.

**Components:** `.github/workflows/ci.yml`.

**Depends on:** none.

**Requirements:** OR-5.2.

**Changes**

1. Add a `mobile` job with the Flutter SDK pinned to the version in use (see
   `docs/CHECKLIST.md` § 7 for the recorded version).
2. Run `flutter pub get`, `flutter analyze --fatal-infos`, `flutter test`.
3. Cache the pub cache and the Gradle cache.
4. Do not run the opt-in integration test in CI — it needs a live backend and a loopback port; it
   stays a scheduled/manual task (T-29).

**Acceptance criteria**

- The job runs the full Flutter test suite and fails on any test failure or analyzer issue.
- The existing backend and frontend jobs are unchanged and still pass.

**Automated verification:** the CI run.

**Manual verification:** none.
---

## Task 07 — Introduce a React test harness

**Status:** complete — implemented, locally verified and **verified in GitHub Actions**
(21 October 2026).
**D-I (approve the React test dev dependencies) is treated as granted by this instruction**, and
the addition is dev-only: `vitest ^5.0.5`, `jsdom ^30.1.3`, `@testing-library/react ^16.3.3`,
`@testing-library/jest-dom ^7.0.1`. The `dependencies` block is unchanged — no new runtime
dependency, so nothing test-related can reach the production bundle. `apps/frontend/package.json`
gains `"test": "vitest run"` and `"test:watch": "vitest"`; `apps/frontend/vitest.config.ts` (new)
uses the jsdom environment and includes only `src/**/*.test.ts(x)`; `apps/frontend/vitest.setup.ts`
(new) registers the jest-dom matchers; `apps/frontend/tsconfig.node.json` now type-checks the two
new config files. The first baseline tests are `apps/frontend/src/lib/api.test.ts` and
`apps/frontend/src/lib/theme.test.ts`: `buildPayload` produces the expected trimmed body (and sends
no phone number and no coordinates), `newSubmissionKey` returns a distinct 36-character UUID-shaped
string, and the theme preference key remains `safesignal-theme` — asserted behaviourally through the
storage key, so no production export was added. The frontend CI job now runs `npm run test` after
`npm run lint`. Verified locally from a clean `npm ci`: lint passes, 2 test files / 8 tests pass, and
`npm run build` emits the **same** assets as before T-07 — `index-CjguLTi7.js` 280.20 kB
(gzip 83.45 kB) and `index-CJNuPtxW.css` 35.48 kB (gzip 7.22 kB), identical hashes — so the test
tooling adds nothing to the shipped bundle.
**CI verification (21 October 2026):** GitHub Actions run **39652159825** on commit `88a07ba`
(https://github.com/Root-node1/safe-signal/actions/runs/39652159825) — the `frontend` job
**succeeded**; the log shows `npm run test` reporting **"Test Files 2 passed (2), Tests 8 passed
(8)"** and `npm run build` emitting the same two assets as before (`index-CJNuPtxW.css` 35.48 kB,
`index-CjguLTi7.js` 280.20 kB). OR-5.3 is therefore satisfied.
`npm audit` still reports two high-severity advisories (`vite` 8.3.0–8.3.2 and `source-map-js`
1.0.0–1.2.1); both were already in the lockfile at `HEAD` and are not fixed here, because the fix is
a dev-dependency version bump outside T-07's authorisation. Two T-04 items were adjusted for
accuracy, neither of them a carry-forward exception: the scripted check
`test_fr61_web_storage_holds_only_the_theme_choice` now skips `*.test.ts(x)` files (it was scanning
test code as if it were application code and failed on T-07's theme test — the exclusion still
applies to all application code), and the decision table in `docs/M4_SCOPE_CHECKLIST.md` § 5 was
corrected to the specification's D-A … D-L (it had carried the research document's older D-01 … D-12
subjects, which made D-I read as something else). C-1, C-2, C-3 and C-7 were not resolved.

**Objective:** Give the React app a test runner so the reporting flow can be verified automatically.
Today `apps/frontend/package.json` has no test script and no test dependency.

**Components:** `apps/frontend/package.json`, `apps/frontend/vite.config.ts` (or a separate vitest
config), `apps/frontend/src/**/*.test.ts(x)`.

**Depends on:** none. The dependency addition is **BLOCKED — D-I (founder)** for approval of the dev
dependency set.

**Requirements:** OR-5.3.

**Changes**

1. Add Vitest with the jsdom environment, plus `@testing-library/react` and
   `@testing-library/jest-dom`, as **dev** dependencies only. No new runtime dependency.
2. Add `"test": "vitest run"` and `"test:watch": "vitest"` scripts.
3. Add a CI step that runs `npm run test` after `npm run lint`.
4. Add the first baseline tests: `buildPayload` produces the expected body; `newSubmissionKey`
   returns a distinct 36-character UUID-shaped string; the theme preference key remains
   `safesignal-theme`.

**Acceptance criteria**

- `npm run test` runs and passes.
- The web build (`npm run build`) is unaffected.
- No production bundle size increase from the test tooling.

**Automated verification:** the CI run.

**Manual verification:** none.

---

# Group C — React

## Task 08 — Extract the submission-key policy into a pure module

**Status:** implemented and verified locally — the manual browser check is outstanding
(21 October 2026).
`apps/frontend/src/lib/submissionKeyPolicy.ts` (new) holds the policy exactly as `design.md` § 5.5
specifies it: `resolveSubmissionKey(current, signature, newKey)` returns the existing
`{key, signature}` when the signature is unchanged, and a fresh `{key: newKey(), signature}`
otherwise. `apps/frontend/src/App.tsx` now calls it: the `submission` ref was retyped from
`{sig, key}` to the module's `SubmissionKeyPolicy` (the task allows either shape), and the inline
comparison was replaced by the call. The fetch, the 8-second timeout, the error handling and the
key format are untouched, and the observable behaviour is identical (FR-6.2, RR-3.3).
Tests: `apps/frontend/src/lib/submissionKeyPolicy.test.ts` (new) covers the first call, the reuse
(the same policy object comes back and `newKey` is not called) and the changed signature;
`apps/frontend/src/App.test.tsx` (new) drives the real reporting flow and asserts the header the
app actually sends — the **same** `Idempotency-Key` for a retried identical submission, a
**different** one after the payload changes, and a **different** one after a successful submission
and a restart; `apps/frontend/src/lib/api.test.ts` gained two tests that pin the untouched
8-second abort and the `TimeoutError` mapping. Supporting changes: `apps/frontend/vitest.setup.ts`
now also registers the Testing Library cleanup after each test and stubs `window.matchMedia` and
`window.scrollTo`, which jsdom does not implement; `apps/frontend/tsconfig.node.json` gained the
`DOM` library so that setup file type-checks; `apps/frontend/src/App.test.tsx` imports
`@testing-library/jest-dom/vitest` for the matcher types. No dependency was added or changed, and
no test file is bundled.
Verification: `npm run test` → **4 files, 17 tests passed**; `npm run lint` clean; `npm run build`
succeeds, and the bundle changes only by the extracted policy (280.20 kB → 280.25 kB, gzip 83.45 →
83.47 kB); the backend suite is unaffected (86 passed, 1 skipped, 1 xfailed).
**Manual verification in a real browser (21 October 2026):** headless Chrome for Testing 131
driven over the DevTools protocol against the Vite dev server and an in-memory `uvicorn`, with
synthetic data only. The flow was completed end to end. The first submission was failed on purpose
and the retry with the unchanged payload carried the **same** `Idempotency-Key`; the confirmation
screen rendered **one** reference code (a single DOM element) and the fresh in-memory store held
exactly **one** report for that retried pair; after a successful submission and a restart the same
payload carried a **different** key and produced a second report; a changed payload carried a third
different key and a third report. Quick Exit replaced the page with the neutral one. No console
errors and no page exceptions were recorded. **Outstanding:** the next CI run of the frontend job.
The T-04 exceptions (C-1, C-2, C-3, C-7) and the retention and consent decisions were not touched.

**Objective:** Make the React idempotency rule testable without changing its behaviour.

**Components:** `apps/frontend/src/lib/submissionKeyPolicy.ts` (new),
`apps/frontend/src/App.tsx`.

**Depends on:** Task 7 (the test harness).

**Requirements:** FR-6.2, FR-6.4, RR-3.3.

**Changes**

1. Create `submissionKeyPolicy.ts` exactly as in design § 5.5: `resolveSubmissionKey(current,
   signature, newKey)` returns the existing `{key, signature}` when the signature is unchanged, and a
   fresh `{key: newKey(), signature}` otherwise.
2. Replace the inline comparison in `App.tsx:104-107` with a call to it. The `submission` ref keeps
   its `{sig, key}` shape or is retyped to the module's shape — either is acceptable provided the
   observable behaviour is identical.
3. Do not change the fetch, the timeout, the error handling, or the key format.

**Acceptance criteria**

- Same payload → the same key is reused.
- Changed payload → a new key is minted.
- Success clears the key; restart clears the key.
- The 8-second timeout and the `TimeoutError` mapping are untouched.

**Automated verification:** unit tests for `resolveSubmissionKey` covering reuse, change, and
first-call cases; plus a test that `App.tsx` still sends the same `Idempotency-Key` header for two
identical submissions.

**Manual verification:** complete the flow in a browser; the reference code appears once.
---

## Task 09 — Disclose the reload limitation in the React UI

**Status:** implemented and verified — reading the banner aloud with a screen reader is still
outstanding (21 October 2026).
`apps/frontend/src/screens/NextStepScreen.tsx` now appends one sentence to the failure banner in
**both** branches: *"Tapping Submit report again is safe as long as you stay on this page. Reloading
the page loses the submission key, so a report sent after a reload may be stored twice."* The
sentence is rendered inside the existing `<p>`, so the layout, the design tokens and the button
behaviour are unchanged, and it stays inside the `InlineBanner`'s `role="alert"` live region (the
error variant's default role) — it is not separated from it (FR-6.3, RR-3.3). The wording is
conditional: it says a report *may* be stored twice, and it promises no immunity.
Tests: `apps/frontend/src/screens/NextStepScreen.test.tsx` (new) renders the screen with a rejected
`onSubmit` and asserts, for the timeout branch (a `TimeoutError`) and the network branch alike, that
the banner carries the reload caveat and the "may be stored twice" wording; it also asserts the
banner is still the `role="alert"` region, that the wording does not promise a duplicate is
impossible, and that no banner appears before a submission is attempted.
Verification: `npm run test` → **5 files, 22 tests passed**; `npm run lint` clean; `npm run build`
succeeds, with the bundle growing only by the new sentence (280.25 kB → 280.43 kB); the backend and
Flutter suites are untouched (86 passed, 1 skipped, 1 xfailed; 159 passed, 1 skipped).
**Browser check (21 October 2026):** headless Chrome against the Vite dev server and an in-memory
`uvicorn`, with the report request deliberately held open so the app hits its own timeout. The
banner appeared **8.2 seconds** after the submit tap — the 8-second timeout and the `TimeoutError`
mapping are unchanged — inside a `role="alert"` region, showing the timeout text followed by the new
caveat. No console errors and no page exceptions were recorded. **Outstanding:** reading the banner
aloud with a screen reader (a human check), and the next CI run of the frontend job.
**T-04 C-1 is deliberately untouched.** The "stored temporarily and may be cleared" wording in the
confirmation and landing screens, in the assistant guidance and in the Flutter strings is *not* part
of T-09, which covers the failure banner only; it stays open as a separate follow-up.

**Objective:** Tell the user, in the failure state, that a page reload may lose the submission key and
that a retry after a reload can create a second report. This is the approved safeguard: the
limitation is disclosed rather than fixed, because fixing it would require storing incident text in
the browser.

**Components:** `apps/frontend/src/screens/NextStepScreen.tsx`.

**Depends on:** Task 8 (no hard dependency, but do it after so the wording matches the policy module).

**Requirements:** FR-6.3, RR-3.3.

**Changes**

1. Extend the existing error banner copy in the timeout and network branches
   (`apps/frontend/src/screens/NextStepScreen.tsx:160-178`) with one sentence: tapping again is safe
   **while the page stays open**; reloading the page loses the key, and a report sent after a reload
   may be stored twice.
2. Keep the banner a live region (`role="alert"`); the new sentence must not be separated from the
   live region.
3. Do not change the layout, the tokens, or the button behaviour.

**Acceptance criteria**

- The banner states both facts: retrying in place is safe, reloading is not.
- The wording does not promise that a duplicate is impossible in every case.
- The banner is announced by a screen reader (live region preserved).

**Automated verification:** a React test asserting the banner contains the reload caveat in both the
timeout and network branches.

**Manual verification:** trigger a timeout in the browser and read the banner aloud.

---

# Group D — Flutter pending report

## Task 10 — Define the pending-report record, checksum and expiry constant

**Status:** complete — implemented and verified (21 October 2026).
`apps/mobile/lib/storage/pending_draft.dart` (new) is a pure value object with no I/O and no
storage: `version` (1), `payload` (the canonical map from `ReportApi.payload(draft)`), `key` (the
idempotency key issued for that payload), `createdAt` and `expiresAt` (epoch milliseconds).
`toJson()` / `fromJson()` check the version explicitly: an unknown version is raised as
`PendingDraftCorruptException` — a corrupt record, not a parse failure — and so is a missing field
or a payload that is not the expected object. The checksum is SHA-256 over
`version|payload|key|createdAt|expiresAt`, using the canonical payload string and excluding the
checksum field itself; `verifyChecksum()` compares the checksum the record carries with the one
recomputed from its content, so corruption is detected rather than silently repaired.
`isExpired(DateTime now)` is true once the expiry timestamp is reached. The expiry policy is the
compile-time constant `kPendingDraftExpiryHours` (24 hours), overridable per build with
`--dart-define=SAFESIGNAL_PENDING_DRAFT_TTL_HOURS=…`; the override was exercised at 48 hours and
both the constant and the expiry arithmetic followed it.
**No dependency was added.** SHA-256 is implemented in the same file, because M.4 allows exactly one
new client dependency — `flutter_secure_storage` (D-H, still open) — and the checksum is an
integrity check over the record's own bytes rather than a security control: the record itself is
encrypted by the platform keystore (`design.md` § 4.1, § 4.3). The implementation is pinned to the
FIPS 180-4 test vectors.
Tests: `apps/mobile/test/pending_draft_test.dart` (new) covers the round trip (every field
preserved exactly; a stored checksum is kept, not recomputed), the payload-stability property
(`jsonEncode(jsonDecode(record.toJson()['payload']))` equals the original payload string byte for
byte, and equals the body the API would post), the checksum (stable for the same content; changed
by the payload, the key, the created timestamp or the expiry timestamp; the checksum field excluded
from the canonical string), the expiry check (not expired before the window, expired at and after
it, the 24-hour default), the corruption handling (unknown version, missing field, non-JSON
payload, and that the corruption reason carries no report content), and the SHA-256 vectors.
Verification: `flutter analyze --fatal-infos` → **no issues**; `flutter test` → **179 passed, 1
skipped** (the opt-in integration test, unchanged). The React and backend suites are untouched.
**Outstanding:** the next CI run of the `mobile` job, which must show 179 tests. Manual
verification: none required by the task.
**Record-format note:** `toJson()` writes the payload as its canonical JSON *string*, so that
`jsonDecode(toJson()['payload'])` yields the map — the property the acceptance criterion names.
`fromJson()` accepts either that string or an already-decoded object, and both forms yield the same
checksum, because the checksum is always computed over the canonical payload string.

**Objective:** Create the value object that will be stored, with its integrity check and the expiry
policy constant. Pure Dart, no storage yet, fully unit-testable.

**Components:** `apps/mobile/lib/storage/pending_draft.dart` (new).

**Depends on:** none.

**Requirements:** FR-1.3, FR-4.1, FR-4.4, SR-3.4, SR-4.1.

**Changes**

1. `PendingDraft`: `version` (1), `payload` (`Map<String, Object?>` — the canonical payload), `key`
   (the idempotency key issued for that payload), `createdAt` (epoch ms), `expiresAt` (epoch ms).
2. `toJson()` / `fromJson()` with an explicit `version` check; an unknown version is treated as
   corrupt, not as a parse failure.
3. `checksum`: SHA-256 over the canonical string of `version|payload|key|createdAt|expiresAt`,
   excluding the checksum itself.
4. `isExpired(DateTime now)`.
5. The expiry constant: `kPendingDraftExpiryHours = 24`, overridable at build time with
   `--dart-define=SAFESIGNAL_PENDING_DRAFT_TTL_HOURS`.
6. A `verifyChecksum()` method.

**Acceptance criteria**

- A round trip `toJson` → `fromJson` preserves every field exactly.
- The checksum is stable for the same content and changes when any field changes.
- `jsonEncode(jsonDecode(record.toJson()['payload']))` equals the original payload string exactly
  (this is what makes the restored request byte-identical — RR-2.3).

**Automated verification:** unit tests for the round trip, the checksum, the expiry check, and the
payload-stability property.

**Manual verification:** none.
---

## Task 11 — Define the store interface and an in-memory implementation

**Status:** complete — implemented and verified (21 October 2026).
`pending_draft_store.dart` defines `PendingDraftStore` (`read`, `write`, `delete`, `isAvailable`) with
the contract documented: one record, `read` returns `null` when absent, `write` replaces, `delete` is
idempotent. `in_memory_pending_draft_store.dart` implements it in pure Dart. In a release build the
in-memory store throws `StateError` unless an explicit `releaseReason` is given, and then logs that
reason through an injectable callback (no report content). T-10's record format and checksum are
untouched; no dependency, controller or copy change. Tests: `test/pending_draft_store_test.dart`
(reusable contract suite plus release-guard tests). Flutter: 195 passed, 1 skipped; analyze clean.

**Objective:** Introduce the abstraction that isolates the controller and the screens from the storage
mechanism, so the secure implementation can be swapped without touching them.

**Components:** `apps/mobile/lib/storage/pending_draft_store.dart` (new),
`apps/mobile/lib/storage/in_memory_pending_draft_store.dart` (new).

**Depends on:** Task 10.

**Requirements:** SR-3.2, SR-3.4, FR-1.3.

**Changes**

1. `abstract class PendingDraftStore` with `Future<PendingDraft?> read()`, `Future<void>
   write(PendingDraft)`, `Future<void> delete()`, and `Future<bool> isAvailable()`.
2. `InMemoryPendingDraftStore`: holds one record; used by widget tests and as the fallback when the
   platform keystore is unavailable. **It must be used only in tests and when the secure store is
   unavailable** — it must never be used as a silent production fallback over plaintext.
3. Document the interface contract: one record at a time; `read` returns `null` when absent; `write`
   replaces any existing record; `delete` is idempotent.

**Acceptance criteria**

- The controller and screens can be written against the interface only, with no storage import.
- The in-memory store cannot be selected in a release build without an explicit, logged reason.

**Automated verification:** unit tests for the interface contract against the in-memory
implementation.

**Manual verification:** none.
---

## Task 12 — Implement the encrypted store

**Status:** complete — implemented and verified by automated tests (21 October 2026); the on-device
encryption check remains T-31. `flutter_secure_storage` 11.2.0 added (D-H approved; 31 new
transitive lockfile package entries, plus the direct `flutter_secure_storage` dependency itself — 32
new entries in total, no existing package changed). `secure_pending_draft_store.dart` adds
`SecurePendingDraftStore` over a small `SecureKeyValue` adapter (real: `FlutterSecureKeyValue`), one
key `safesignal_pending_draft_v1`, the whole record as one JSON value. Read validates JSON, version and
checksum and raises `PendingDraftCorrupt` (an alias of `PendingDraftCorruptException`), including lazy
cast failures; platform failures raise the separate `PendingDraftStorageException`. `isAvailable()` is
a non-destructive read; there is no plaintext fallback. The plugin's Android backend is RSA-OAEP +
AES-GCM with the key in the Keystore, not `EncryptedSharedPreferences` (removed in 11.0.0); design.md
§ 4.1 was amended. Effective minSdk 24 (unchanged). Debug and release APKs build. **Android backup
exclusion (SR-13.3) is required before real-user deployment** and stays with its own task. Not wired
into the controller; T-13 untouched.

**Objective:** Store the pending report in app-private, keystore-backed encrypted storage.

**Components:** `apps/mobile/lib/storage/secure_pending_draft_store.dart` (new),
`apps/mobile/pubspec.yaml`.

**Depends on:** Tasks 10, 11. The dependency addition is **BLOCKED — D-H (founder)** for approval of
`flutter_secure_storage`.

**Requirements:** SR-3.1, SR-3.2, SR-3.3, SR-12.2, SR-13.5.

**Changes**

1. Add `flutter_secure_storage` to `apps/mobile/pubspec.yaml` dependencies.
2. `SecurePendingDraftStore` implements `PendingDraftStore` over one storage key,
   `safesignal_pending_draft_v1`.
3. Write the whole record as a single JSON value, so a torn write cannot leave a partial record
   (RR-4.1).
4. On read: parse → check the version → verify the checksum → return the record, or throw a
   `PendingDraftCorrupt` exception.
5. On keystore initialisation failure: `isAvailable()` returns `false`; the app continues in
   in-memory-only mode and tells the user that saving is currently unavailable. **Never fall back to
   plaintext storage.**
6. No key, passphrase or seed appears in the source or in the repository (SR-12.2).

**Acceptance criteria**

- The stored value in the app's shared-preferences directory is not readable as plain report text
  (verified on a device in T-31; the backend is the plugin's RSA-OAEP + AES-GCM cipher, not
  `EncryptedSharedPreferences`, which plugin 11.x removed — design.md § 4.1).
- A corrupt value raises `PendingDraftCorrupt` rather than returning a partial record.
- No secret material is committed.

**Automated verification:** unit tests against the interface using a fake secure-storage adapter —
write, read, corrupt, delete, and keystore-unavailable.

**Manual verification:** on a device, confirm the stored value is not plain text (T-31).
---

## Task 13 — Make the store robust against interrupted writes, corruption and failed deletion

**Status:** complete — implemented and verified by automated tests (22 October 2026).
`apps/mobile/lib/storage/pending_draft_store.dart` now carries the exception hierarchy and the
discard helper, both defined against the interface so neither depends on a concrete store:
`PendingDraftStoreException` is the base, with `PendingDraftCorrupt` (the stored value is not the
record we intended), `PendingDraftUnavailable` (the storage could not be reached — the record may
be perfectly good), `PendingDraftWriteFailed` (the record was not written) and
`PendingDraftDeleteFailed` (the record was not deleted). None of the reasons ever carries an
incident payload, a submission key or a stored value. `readOrDiscard()` reads, validates, and on
corruption deletes the record and rethrows a typed `PendingDraftCorrupt` so the caller can tell the
user; a storage failure is propagated unchanged and is never treated as an absent record, and
nothing is deleted for it. If the deletion of a corrupt record fails, `PendingDraftDeleteFailed` is
raised with the corruption as its cause, so the failure is never reported as success (RR-4.3).
`SecurePendingDraftStore` now wraps the platform error by operation — a read failure is
`PendingDraftUnavailable`, a write failure `PendingDraftWriteFailed`, a delete failure
`PendingDraftDeleteFailed` — and translates a rejected record into `PendingDraftCorrupt`; the
T-12 placeholders (`PendingDraftStorageException` and the `PendingDraftCorrupt` alias) are gone.
`InMemoryPendingDraftStore` refuses to return a record whose checksum does not verify, exactly as
the keystore-backed store does. The store's documentation now states why an interrupted write is
safe: the single-value write means there is no half-written record to recover, and the checksum
means a value that is present but not the record we intended is detected and deleted rather than
restored (RR-4.1).
Tests: `apps/mobile/test/pending_draft_store_robustness_test.dart` (new, 28 tests) covers the
hierarchy, `readOrDiscard` over a healthy store, over a corrupt record (corrupted JSON, unsupported
version, checksum mismatch — each discarded and reported, and never returned to the caller), over
an unavailable store (a failed read is not treated as absent and deletes nothing), the failed
write, the failed delete (reported, and the record left intact rather than half-deleted),
idempotent deletion, a failed deletion *during* a discard (reported as a delete failure with the
corruption as its cause), and the in-memory store's refusal to return an unverified record. The
T-12 store tests were updated to the new type names, with the same coverage.
Verification: `flutter analyze --fatal-infos` → **no issues**; `flutter test` → **254 passed, 1
skipped** (the opt-in integration test, unchanged; 226 before this task). The React and backend
suites are untouched. **Outstanding:** the next CI run of the `mobile` job. Expiry (T-14) and the
controller integration (T-15) are not part of this task and were not implemented.
**Note:** the T-12 status block above described the pre-T-13 exception names; that text is kept as
the record of T-12's state, and the current names are the ones listed here.

**Objective:** Give the store the deterministic failure behaviour the requirements demand.

**Components:** `apps/mobile/lib/storage/pending_draft_store.dart`,
`apps/mobile/lib/storage/secure_pending_draft_store.dart`,
`apps/mobile/lib/storage/in_memory_pending_draft_store.dart`.

**Depends on:** Task 12.

**Requirements:** SR-4.2, SR-4.3, RR-4.1, RR-4.2, RR-4.3.

**Changes**

1. Define a `PendingDraftStoreException` hierarchy: `PendingDraftCorrupt`, `PendingDraftWriteFailed`,
   `PendingDraftDeleteFailed`, `PendingDraftUnavailable`.
2. `read()` wraps the platform error; a read error is distinct from a corrupt value.
3. Provide a `readOrDiscard()` helper: read → validate → on corruption, delete the record and rethrow
   a typed `PendingDraftCorrupt` so the caller can tell the user.
4. `delete()` must be idempotent and must report failure explicitly rather than swallowing it
   (RR-4.3).
5. Document that the checksum plus the single-value write is what makes an interrupted write safe
   (RR-4.1).

**Acceptance criteria**

- A record whose checksum does not verify is never returned to the caller.
- A failed delete raises `PendingDraftDeleteFailed` and does not report success.
- A failed delete leaves the record intact (nothing is half-deleted).

**Automated verification:** unit tests for each exception path, including a fake store whose write,
read and delete each fail on demand.

**Manual verification:** none.
---

## Task 14 — Enforce expiry

**Status:** complete — implemented and verified by automated tests (22 October 2026).
`apps/mobile/lib/storage/pending_draft_store.dart` gains the expiry policy on the startup read and
the outcome types that keep the cases apart: `PendingDraftAbsent` (nothing is stored),
`PendingDraftAvailable` (a valid record that has not expired — it stays in storage so it can be
offered for restore) and `PendingDraftExpired` (the record had expired: it was deleted, it is never
offered for restore, and it carries only the time the report was saved, so the user can be told
*when* it expired and never what it contained, FR-4.3). The clock is injected
(`PendingDraftClock`), so expiry is deterministic under test and follows the device clock in the
app. `readOrDiscardAt(now)` reads, validates and applies the policy: a valid record inside the
window is returned and kept; a record at or past `expiresAt` is deleted and reported as expired; a
deletion that fails raises `PendingDraftDeleteFailed` and leaves the record in place, so the failure
is never reported as success (RR-4.3); a corrupt record is deleted and raised as
`PendingDraftCorrupt`; an unreachable store is raised as `PendingDraftUnavailable`. Expiry,
corruption and unavailability therefore stay three distinct things, and a report is never silently
dropped.
`apps/mobile/lib/api/submission_controller.dart` exposes the outcome through `readPendingReport()`
and the `pendingOutcome` getter, so the UI can say "The saved report from <time> expired and was
deleted." The controller takes an optional `pendingStore` and an optional clock; reading the pending
report does not touch the draft or the idempotency key — saving, restoring and discarding on
request remain T-15.
The T-13 exception hierarchy is unchanged, T-13's `readOrDiscard()` behaviour is preserved (its 28
tests still pass), the 24-hour default and its build-time override are unchanged, and no background
deletion was introduced.
Tests: `apps/mobile/test/pending_draft_expiry_test.dart` (new, 16 tests) covers a record just
inside the window, exactly at expiry and after expiry; the successful deletion of an expired
record; a failed deletion of an expired record (reported, the record left in place, and not
reported as success); a missing record; a corrupt record; an unavailable store; and the injected
clock, through the controller.
Verification: `flutter analyze --fatal-infos` → **no issues**; `flutter test` → **270 passed, 1
skipped** (the opt-in integration test, unchanged; 254 before this task). The React and backend
suites are untouched — the backend's T-04 citation check caught the one line reference into
`submission_controller.dart` that moved with this change, and that single citation in
`docs/M4_SCOPE_CHECKLIST.md` was corrected. **Outstanding:** the next CI run of the `mobile` job.
Manual verification: none required by the task.

**Objective:** Delete an expired pending record on read and tell the user.

**Components:** `apps/mobile/lib/storage/pending_draft_store.dart`,
`apps/mobile/lib/api/submission_controller.dart`.

**Depends on:** Task 13.

**Requirements:** FR-4.2, FR-4.3.

**Changes**

1. On startup read, if the record is expired: delete it, set an `expired` outcome, and do not offer it
   for restore.
2. The controller exposes the expiry outcome so the UI can say "The saved report from <time> expired
   and was deleted."
3. Do not show the expired content at any point.
4. The expiry period remains an application constant, not a user setting (FR-4.4).

**Acceptance criteria**

- An expired record is never offered for restore.
- The user is told it expired and was deleted.
- The record is gone from storage afterwards.

**Automated verification:** unit tests with an injected clock: a record just inside the window is
kept; one just outside is deleted.

**Manual verification:** none.
---

## Task 15 — Integrate the pending report with the submission controller

**Status:** complete — implemented, corrected by founder decision, and verified by automated tests
(22 October 2026).
**FR-1.5 was amended twice by founder decision (22 October 2026)** to close the confirmed
duplicate-report edge case. It now reads: *saving shall not modify the in-memory draft or the
in-flight submission state; saving shall not replace a controller idempotency key that was issued
for the payload being saved; and a key for the payload being saved — the controller's current key
when that key applies to it, otherwise a newly generated one — may be installed together with its
payload signature, but only after the pending record has been successfully written.* The rationale is
recorded with the requirement: a saved report and a same-session submission of identical content must
share one idempotency key, because with two keys an ambiguous outcome followed by a restart and a
restore would send the retry under a second key and the server would store a second report for the
same content (RR-3.1). T-15's acceptance criterion was amended to match.
`SubmissionController` can now save, restore and discard the pending report. `savePending()` refuses
unless the draft would submit — an incident type and a support choice are chosen (FR-1.4) — writes
the canonical `ReportApi.payload(draft)` map with the controller's current key when that key was
issued for this exact payload, and with a newly generated key otherwise, together with the creation
time and the expiry time (FR-1.3, FR-1.2). It touches neither the in-memory draft nor the
in-flight submission state, and it never replaces a key that was issued for the payload being
saved. **After the record has been written successfully, the controller installs the key for that
payload together with the matching signature** — the current key when it applies, otherwise the key
the record now carries — so the next submit of the same content reuses it instead of minting another
one, and the controller's key always belongs to the content it is working on. A failed write leaves
the controller's key and signature exactly as they were.
`restorePending()` reads through the expiry-aware path, then restores the draft fields
from the stored payload (FR-2.2) **and installs the stored key together with the stored payload
signature** (FR-2.3, RR-2.1, RR-3.2) — the load-bearing step, because without the signature the
next submit would see a missing or mismatched signature and mint a new key.
`discardPending()` deletes the record first and only then clears the draft and the key, so a failed
deletion is raised and never reported as a discard that happened (RR-4.3). The outcomes are
`SaveSucceeded` / `SaveRefused` and `RestoreSucceeded` / `RestoreNothingSaved` / `RestoreExpired` /
`RestoreCorrupt`; none of them carries the payload or the key, so nothing sensitive can leak through
them. A corrupt record gives `RestoreCorrupt` (it was deleted by the read), while an unreachable
store still raises `PendingDraftUnavailable`, so storage failure stays distinguishable from
corruption and is never reported as "there was nothing saved" (SR-4.2, SR-4.3). No timer, no
connectivity listener and no automatic submission was added (RR-5.1, RR-5.2).
`apps/mobile/lib/models/report_draft.dart` gained only the payload → draft mapping helper: unknown
or missing values are ignored rather than fatal, so a record written by another version cannot crash
the app.
Tests: `apps/mobile/test/pending_report_controller_test.dart` (new, 25 tests) covers save and
restore with an identical payload and key; restore followed by a submission using the same key and
the same body bytes; an edit after restore minting a new key; an unchanged restored report reusing
the stored key on retry; an explicit discard; the expired, corrupt and unavailable cases; failed
write and failed delete operations; no submission without an explicit call; and the outcomes
carrying neither the payload nor the key. **The corrected sequence is covered by a regression test:**
save → the record carries key A and the controller holds key A → submit sends key A and the saved
body → the outcome is ambiguous (the request may or may not have reached the server) and the record
is kept → a new controller represents the restart → the restore adopts key A and sends nothing by
itself → the retry sends key A with the same body, so every attempt of the report used one key and
the server sees one logical submission. The test also checks that a failed write leaves the
controller keyless, that saving preserves an existing controller key, that an edit after a save
generates a new key, and that saving changes neither the draft nor the submission state.
Verification: `flutter analyze --fatal-infos` → **no issues**; `flutter test` → **299 passed, 1
skipped** (the opt-in integration test, unchanged; 270 before this task, 291 before the first
FR-1.5 correction, 295 before the second). The T-13 and T-14 suites are green (44 tests). The React
and backend suites are unaffected — the backend's T-04 citation into `submission_controller.dart`
still resolves, so no citation needed correcting by this change.
**Remaining integration work, deliberately not done here:** the restore prompt and its wording
(T-16), the discard control and its wording (T-17), deleting the record on success and on Quick Exit
(T-19), and passing the real keystore-backed store to the controller from the app's startup path —
until that is done, `readPendingReport()` and `restorePending()` report `PendingDraftAbsent` in the
running app. The app also has no "replace or keep" question yet: FR-1.1 requires the user to be
offered a choice when a record already exists, which belongs to the T-16/T-17 screens. On-device
verification remains T-31.
**The A → B → A consequence, accepted under the existing key policy:** because the controller's key
always belongs to the content it is working on, editing a report from payload A to payload B and
back to A again can generate a new key for A. A changed payload is a new logical submission under
the existing policy (design § 5.1: content changed → new key), so the key issued for A is not
recovered; the report is still one logical report at a time, and T-19 deletes the record after a
confirmed submission.
**Stale submission responses — corrected at the controller level (22 October 2026), with the
user-facing part still open.** An earlier in-flight submission could complete after the user had
edited or saved a newer draft, and the earlier success then cleared the newer in-memory draft and
presented the older report as the current one. `submit()` now compares the signature of the request
it sent with the signature of the draft on hand when the response arrives. When they differ, the
result is **not** applied to the newer draft: the newer draft, its key and its saved record are left
intact, and the earlier report's confirmation code is preserved in a new, distinguishable
`SucceededButDraftChanged` state — deliberately not a `Succeeded` state, so the review screen does
not navigate to a confirmation screen that would present the older report as the current one. A late
failure keeps the ordinary failure semantics, and a key conflict no longer takes a newer draft's
key. The ordinary path — an unchanged draft — is untouched, and the earlier report's code is never
discarded. **Still open, for the UI and localisation tasks (T-16, T-18, T-20):** the app does not
yet *tell* the user that an earlier report was filed while their draft has moved on; that needs a
banner and an announcement in both locales, and the string set is due in T-20. **Also open for
T-19:** deleting the pending record after a confirmed success must not delete a *newer* record when
the success that arrived was stale. **Also open, and not part of this correction:** the system back
gesture is still unguarded while a submission is in flight — the review screen disables its own Back
button, but `appRoute` sets no `canPop`, so the user can return to the report screen and change the
draft mid-request. The controller now keeps that newer work safe, but blocking the gesture would
remove the path at its source and is a separate decision.

**Objective:** Teach `SubmissionController` about the pending report: saving it, restoring it, and
restoring the **key** with it.

**Components:** `apps/mobile/lib/api/submission_controller.dart`,
`apps/mobile/lib/models/report_draft.dart` (a payload → draft mapping helper only).

**Depends on:** Tasks 11, 13, 14.

**Requirements:** FR-1.1, FR-1.2, FR-1.4, FR-1.5, FR-2.2, FR-2.3, RR-2.1, RR-3.2, RR-5.1.

**Changes**

1. Inject a `PendingDraftStore` into `SubmissionController`; keep it optional so existing tests and
   call sites that do not provide one still work.
2. `Future<SaveOutcome> savePending()`:
   - refuses unless the draft would submit (incident and support chosen) — FR-1.4;
   - computes the canonical payload with `ReportApi.payload(draft)` — FR-1.3;
   - uses the controller's **current** key; if there is no key yet, mint one with the existing
     `newIdempotencyKey()` — FR-1.5;
   - writes one `PendingDraft` with `createdAt` and `expiresAt` — FR-1.2;
   - does not touch the in-memory draft, the submission state, or the key it already holds.
3. `Future<RestoreOutcome> restorePending()`:
   - reads the record; if absent, expired or corrupt, returns the corresponding outcome;
   - restores the draft fields from the stored payload (incident, timing, support, route, area,
     vehicle, sacco) — FR-2.2;
   - sets `_key = record.key` **and** `_signature = jsonEncode(record.payload)` — FR-2.3, RR-2.1,
     RR-3.2. This is the load-bearing change: without setting `_signature`, the next `submit()`
     would see `_key == null` or a mismatched signature and mint a new key.
   - sets the in-memory signature so the first submit after restore reuses the stored key.
4. `discardPending()`: delete the record, clear the draft, clear the key.
5. No background timer, no connectivity listener, no automatic submit — RR-5.1.

**Acceptance criteria**

- Save → restore → submit sends the **same** `Idempotency-Key` and the **same** body bytes.
- Save → restore → edit one field → submit mints a new key (the content is a different report).
- Save does not replace a key that was issued for the payload being saved; the key for the saved
  payload — the controller's current key when it applies, otherwise a newly generated one — is
  installed together with its payload signature **after** the record has been written, so a
  same-session submission of the same content uses the same key (FR-1.5 as amended, RR-3.1).
- No code path submits without an explicit call.

**Automated verification:** unit tests against the in-memory store:
`save → restore → submit` yields the same key and body; `save → restore → edit → submit` yields a
different key; the draft is unchanged by a save.

**Manual verification:** none.
---

## Task 16 — Add the restore prompt

**Status:** complete — implemented and verified by automated tests (22 October 2026). `9a8f53d`.
`apps/mobile/lib/screens/welcome_screen.dart` shows a modal `AlertDialog` with Restore and Keep saved
actions when a valid pending record exists; dismissing (back, barrier, Keep saved) preserves the
record (FR-2.4). The prompt states when the report was saved and that it has not been submitted
(FR-2.5); no incident content beyond the timestamp is shown. Accessibility: `AlertDialog` provides the
dialog role and accessible name, focus moves into and out of the dialog, minimum 48 × 48 dp targets,
and all banners are `Semantics(liveRegion: true)` (AR-1.2, AR-2.2, AR-4.1). Error states — corrupt,
expired, unavailable, and failed-deletion — each show a live-region banner and never offer the bad
record for restore (SR-4.2, SR-4.3, RR-4.3). `flutter gen-l10n` clean; `flutter analyze --fatal-infos`
no issues; `flutter test` 332 passed, 1 skipped (the opt-in integration test, unchanged). Remaining
accessibility and device-verification work stays with T-31, T-32.

**Objective:** On startup, if a pending report exists, offer the user to restore it or to keep it
saved — and never send it automatically.

**Components:** `apps/mobile/lib/screens/welcome_screen.dart`,
`apps/mobile/lib/widgets/` (a new small dialog widget, or an inline dialog in the welcome screen),
`apps/mobile/lib/app.dart` (the startup read).

**Depends on:** Task 15.

**Requirements:** FR-2.1, FR-2.4, FR-2.5, AR-1.1, AR-1.2, AR-1.3, AR-2.1, AR-2.2, AR-3.1, AR-4.1, AR-4.2, AR-5.1.

**Changes**

1. On app start, the controller performs one `read()` (T-15) and stores the outcome.
2. The welcome screen shows a prompt when a valid record exists: when it was saved, and that it has
   **not** been sent.
3. Actions: **Restore** and **Keep saved** (dismiss). Do not auto-restore and do not auto-send.
4. Dismissing leaves the record on the device (FR-2.4).
5. Accessibility: `Semantics` with an accessible name on the dialog, focus moved to it on open and
   restored to the invoking control on close, minimum 48 × 48 dp targets, a live region announcing
   the outcome of the choice, contrast meeting WCAG AA in light and dark mode, no overflow at 2×
   text scale.
6. All strings come from the ARB files (Task 20).

**Acceptance criteria**

- A pending report is never submitted or restored without an explicit choice.
- Dismissing does not delete the record.
- The prompt is operable by screen reader alone and by keyboard alone.
- The prompt states that the report has not been sent.

**Automated verification:** widget tests — prompt appears when a record exists; does not appear when
none exists; **Restore** populates the draft; **Keep saved** leaves the record; the prompt is announced
as a dialog; the error path (corrupt record) shows the error banner and deletes the record.

**Manual verification:** TalkBack pass on a device (T-31).
---

## Task 17 — Add the discard action

**Objective:** Let the user delete a pending report deliberately, and say so honestly if the deletion
fails.

**Components:** `apps/mobile/lib/screens/review_screen.dart`,
`apps/mobile/lib/screens/welcome_screen.dart` (discard from the restore prompt),
`apps/mobile/lib/widgets/`.

**Depends on:** Tasks 15, 16.

**Requirements:** FR-3.1, FR-3.2, FR-3.3, AR-1.1, AR-2.1, AR-2.2, AR-3.1, AR-4.1, AR-4.2, AR-5.1.

**Changes**

1. A "Discard saved report" action on the review screen and in the restore prompt, with a
   confirmation step ("This deletes the report saved on this phone. It cannot be undone.").
2. Discarding deletes the record, clears the draft, and returns to the start of the flow (FR-3.2).
3. If the deletion fails, the failure is announced through the error live region and the app does
   **not** say the report was deleted (FR-3.3, RR-4.3).
4. Accessibility: same standards as Task 16.

**Acceptance criteria**

- Discard removes the record from storage and clears the in-memory draft.
- A failed deletion is reported and the record is retained.
- The confirmation names what is being deleted and that it cannot be undone.

**Automated verification:** widget tests — successful discard; failed discard (a store that throws)
shows the error banner and keeps the record.

**Manual verification:** TalkBack pass (T-31).

**Status:** complete — implemented and verified by automated tests (23 October 2026).
`apps/mobile/lib/widgets/discard_confirmation.dart` — a new `showDiscardConfirmation(BuildContext)` helper
that returns `Future<bool>`: a modal `AlertDialog` titled "Discard saved report?" with the body
"This deletes the report saved on this phone. It cannot be undone.", a Cancel button, and a destructive
Discard button in the theme error colour. Barrier, back, and Cancel all return `false` (report preserved).
`SubmissionController.discardPending()` (T-15) deletes the record, clears the draft and key, resets
`_pendingOutcome` and `_pendingReadError`, and calls `notifyListeners`; a `_discarding` guard prevents
duplicate deletion requests on double-tap. On `PendingDraftDeleteFailed` the failure is caught, the record
is retained, and an error banner ("Could not delete the saved report." / "The report is still saved on
this phone.") is shown as a live region (FR-3.3, RR-4.3). Widget tests cover: successful discard from the
restore prompt (record gone, prompt dismissed, returns to Report an incident), successful discard from
the review screen (pops to the first route), cancel/barrier/back in the confirmation all preserve the
record (FR-3.2, FR-3.3), failed discard retains the record and shows the honest error banner (AR-4.1),
discard error banner is a live region, English/ Kiswahili localisation, 2× text scaling on both screens,
retry-after-failure. `flutter gen-l10n` clean; `flutter analyze --fatal-infos` no issues;
`flutter test` 351 passed, 1 skipped.

---

## Task 18 — Make submission of a restored report correct

**Objective:** Cover the three submission paths a restored report can take: unchanged, edited, and
uncertain outcome.

**Components:** `apps/mobile/lib/api/submission_controller.dart`,
`apps/mobile/lib/screens/review_screen.dart`.

**Depends on:** Task 15.

**Requirements:** FR-5.1, FR-5.2, FR-5.3, FR-5.6, RR-2.2, RR-2.3, RR-3.1, RR-4.4, AR-4.1.

**Changes**

1. **Unchanged:** the restored key is reused; the request body is byte-identical to the stored
   payload (RR-2.2, RR-2.3).
2. **Edited:** the payload signature changes, so a new key is minted — and the app shows an explicit
   notice: *"You changed the saved report, so it will be sent as a new report."* Never silent
   (FR-5.2).
3. **Uncertain acknowledgement:** on a timeout or socket failure the record and its key are retained,
   and the banner states that the outcome is unknown and that tapping Submit again is safe because
   the same report will not be sent twice (FR-5.6, RR-4.4).
4. On a confirmed 2xx, delete the record (see Task 19 for the failure path) (FR-5.4).
5. Submission remains exclusively user-initiated (FR-5.3).

**Acceptance criteria**

- Unchanged restore → the same key and the same body are sent.
- Edited restore → a different key is sent and the notice is shown.
- An uncertain outcome keeps the record and the key.
- A 409 on a restored key mints a new key for the next attempt and is explained to the user.

**Automated verification:** unit tests with a fake transport for each path; widget tests for the
notice and the unknown-outcome banner.

**Manual verification:** none beyond T-29.
---

## Task 19 — Delete the pending record on success and on Quick Exit

**Objective:** Close the deletion lifecycle: after a confirmed submission, and on Quick Exit.

**Components:** `apps/mobile/lib/api/submission_controller.dart`,
`apps/mobile/lib/widgets/quick_exit_button.dart`,
`apps/mobile/lib/screens/confirmation_screen.dart`.

**Depends on:** Tasks 15, 18.

**Requirements:** FR-11.1, FR-11.2, FR-11.3, FR-11.4, FR-5.4, FR-5.5, FR-3.3, RR-4.3, PR-8.1, AR-4.1.

**Changes**

1. On `SubmitAccepted`, delete the record before showing the confirmation screen (FR-5.4).
2. If that deletion fails, keep the record, show the error banner, and do not claim the device was
   cleared (FR-5.5).
3. `quickExit()` becomes: `controller.reset()` (which deletes the record) → pop to the first route →
   `SystemNavigator.pop()` — deletion happens **before** exit so it is not raced against process death
   (FR-11.1, design § 6.2). The existing immediate-navigation behaviour is preserved unchanged
   (FR-11.3).
4. If the deletion fails during Quick Exit, show a short message with **Try again** and **Exit
   anyway**. The exit is not blocked — Quick Exit is a safety affordance — but the user is told the
   truth (FR-11.2, RR-4.3, PR-8.1).
5. The existing comment in `quick_exit_button.dart` that lists what Quick Exit cannot erase stays, and
   is extended to mention the saved pending report (FR-11.4).

**Acceptance criteria**

- After a successful submission, the store is empty.
- After Quick Exit, the store is empty.
- A failed deletion during Quick Exit shows the message and offers both choices.
- The app never states that system-level traces were erased.

**Automated verification:** unit tests — success path empties the store; Quick Exit with a failing
store shows the message and still pops the route.

**Manual verification:** on a device, save a report, Quick Exit, and confirm the app's data directory
holds no report text (T-31).
---

## Task 20 — Add the new strings in English and Kiswahili

**Objective:** Add every new user-facing string to both ARB files, with placeholder metadata, so the
localisation parity test keeps passing and no string is hard-coded in a widget.

**Components:** `apps/mobile/lib/l10n/app_en.arb`, `apps/mobile/lib/l10n/app_sw.arb`,
`apps/mobile/lib/l10n/app_localizations*.dart` (regenerated).

**Depends on:** Tasks 16, 17, 18, 19.

**Requirements:** AR-3.2, AR-3.3.

**Changes**

1. Add the strings for: save-for-later, saved confirmation, restore prompt, discard, discard
   confirmation, expired record, corrupt record, deletion failure, unknown outcome, edited-report
   notice, screenshot-blocked note.
2. Add the same keys to `app_sw.arb`. The Kiswahili wording is machine-drafted and **must be marked
   as unreviewed** in `docs/TRANSLATION.md`, consistent with the existing position on M.2C.
3. Regenerate the localisations.
4. Run the existing localisation parity test — it must pass unchanged.

**Acceptance criteria**

- The ARB files have identical key sets.
- No new user-facing string is hard-coded in a Dart file.
- The parity test passes.

**Automated verification:** `flutter test test/localization_test.dart`.

**Manual verification:** a fluent speaker reviews the new strings (T-32 / the existing translation
review backlog).

---

# Group E — Android hardening

## Task 21 — Block screenshots and screen capture

**Objective:** Set `FLAG_SECURE` on the activity window so the recent-apps thumbnail, screenshots and
screen recordings cannot capture the report screens.

**Components:** `apps/mobile/android/app/src/main/kotlin/com/safesignal/app/MainActivity.kt`.

**Depends on:** none. The trade-off is **BLOCKED — D-G (founder)** for acceptance of the
screenshot-blocking behaviour.

**Requirements:** SR-13.1, SR-13.2.

**Changes**

1. Set `WindowManager.LayoutParams.FLAG_SECURE` in `MainActivity.onCreate`, exactly as in design
   § 7.1. No new pub dependency.
2. Add a line to the confirmation screen explaining that screenshots are blocked for privacy and that
   the reference code can be copied instead (SR-13.2). The string goes through Task 20's ARB files.
3. Note the consequence in `docs/SECURITY.md`: users cannot screenshot the reference code.

**Acceptance criteria**

- A screenshot on a physical device produces a black or blocked frame.
- The recent-apps thumbnail shows no report content.
- The copy button still works.
- No new dependency was added.

**Automated verification:** none — this is platform behaviour.

**Manual verification:** device test in T-31.
---

## Task 22 — Exclude the app from backup and re-check the permission set

**Objective:** Stop Android auto-backup and device-to-device transfer from copying the app's data, and
confirm the manifest still requests no permission other than `INTERNET`.

**Components:** `apps/mobile/android/app/src/main/AndroidManifest.xml`,
`apps/mobile/android/app/src/main/res/xml/data_extraction_rules.xml` (new).

**Depends on:** Task 12 (a backup of undecryptable keystore data is also a correctness problem).

**Requirements:** SR-13.3, SR-13.4, SR-13.5, PR-4.2, PR-4.3, RR-5.3.

**Changes**

1. Add `android:allowBackup="false"` to the `<application>` element.
2. Add `android:dataExtractionRules="@xml/data_extraction_rules"` and create the rules file exactly as
   in design § 7.2, excluding the `file`, `database`, `sharedpref` and `external` domains from both
   cloud backup and device transfer.
3. Re-check the manifest: the only permission is `INTERNET` (PR-4.3). No location permission, no
   background-execution permission, no notification permission (RR-5.3).
4. Record the manifest state in `docs/SECURITY.md`.

**Acceptance criteria**

- The manifest declares only `INTERNET`.
- Both backup paths are excluded.
- The app still builds and installs.

**Automated verification:** a script that parses the merged manifest and asserts the permission set
and the backup attributes — added to the scope-check script from Task 4.

**Manual verification:** device test in T-31 (an `adb backup` shows no SafeSignal data).

---

# Group F — Backend

## Task 23 — Validate the environment at startup and make CORS configurable

**Objective:** Refuse to start in production when the configuration is incomplete, and read the CORS
allow-list from configuration instead of hard-coding the development origin.

**Components:** `apps/backend/main.py`, `apps/backend/.env.example`, `apps/backend/tests/test_config.py`
(new).

**Depends on:** none.

**Requirements:** FR-9.1, FR-9.2, FR-9.3, SR-8.1, SR-8.2, SR-8.3, SR-5.2, RR-7.1, RR-7.2.

**Changes**

1. Add a `validate_production_config()` called from the lifespan before `db.init()`:
   - `SAFESIGNAL_ENV=production` requires `DATABASE_URL`, a non-empty `SAFESIGNAL_ADMIN_KEY` of at
     least the configured minimum length, and a non-empty `SAFESIGNAL_CORS_ORIGINS`;
   - the failure message names the missing variable and never its value (FR-9.2).
2. Read the CORS allow-list from `SAFESIGNAL_CORS_ORIGINS` (comma-separated). Outside production,
   default to `http://localhost:5173` so development is unchanged (SR-8.1).
3. Keep the allowed methods and headers exactly as they are (SR-8.3).
4. Keep the production in-memory refusal as it is (FR-9.3).
5. Preserve the generic 503 mapping and the readiness behaviour (RR-7.1, RR-7.2).
6. Add the new variables to `.env.example` with no values.
7. No new backend dependency (XR-12).

**Acceptance criteria**

- Production without `DATABASE_URL`, without `SAFESIGNAL_ADMIN_KEY`, or without
  `SAFESIGNAL_CORS_ORIGINS` refuses to start, naming only the variable.
- Development still starts with the current defaults.
- The existing backend test suite still passes.

**Automated verification:** `apps/backend/tests/test_config.py` — one test per missing variable, one
for a valid configuration, one asserting the error message does not contain the secret value.

**Manual verification:** none.
---

## Task 24 — Build the retention tool

**Objective:** Provide the command-line tool that deletes reports past the configured window, with a
dry-run mode, fail-closed configuration and a content-free summary.

**Components:** `apps/backend/retention.py` (new), `apps/backend/tests/test_retention.py` (new).

**Depends on:** Task 2 for the policy shape; the tool itself ships **inert** until a period is
configured.

**Requirements:** FR-7.1 … FR-7.6, FR-8.1, RR-6.1, RR-6.3, SR-5.3, OR-1.1, PR-9.2.

**Changes**

1. `retention.py --dry-run` and `retention.py`, exactly as in design § 8.3.
2. Read `SAFESIGNAL_REPORT_RETENTION_DAYS`. Unset, empty, zero or non-numeric → print a message naming
   the variable, exit non-zero, delete nothing (FR-8.1).
3. Delete in one statement inside one transaction, in bounded batches with a short pause between them
   (FR-7.6).
4. Count the idempotency keys removed with the reports, using the cascade (FR-7.3, RR-6.3).
5. Do not delete a key independently of its report (RR-6.1).
6. Print and write a summary — window, counts, timestamps — and never a report id, code or content
   (FR-7.4, SR-5.3).
7. Write the run summary to a path outside the repository, git-ignored.
8. Write the tool's behaviour against a **test** database only; it must refuse to run against a
   database whose name does not end in `_test` unless an explicit override flag is passed.

**Acceptance criteria**

- With the variable unset, the tool deletes nothing and exits non-zero.
- `--dry-run` deletes nothing and reports the same counts.
- A second run immediately after the first deletes nothing more.
- The summary contains no report content.
- The tool refuses to run against a non-test database without the override flag.

**Automated verification:** `apps/backend/tests/test_retention.py` against the CI PostgreSQL service —
all of the above, including the cascade count.

**Manual verification:** run `--dry-run` against a staging database and read the output.
---

## Task 25 — Schedule the retention job and expose its health

**Objective:** Make the retention run visible and monitored, so a skipped or failed run is noticed.

**Components:** `apps/backend/deploy/retention.service.example`,
`apps/backend/deploy/retention.timer.example` (new), `docs/RUNBOOK.md` (section, written in T-27).

**Depends on:** Task 24.

**Requirements:** OR-1.2, OR-1.3, OR-3.2.

**Changes**

1. A systemd service and timer (or a cron entry) that runs the tool daily at a low-traffic hour.
2. The run summary file path is fixed so monitoring can read it.
3. A non-zero exit is surfaced by monitoring as an alert.
4. The runbook explains how to tell "ran, found nothing" from "did not run".

**Acceptance criteria**

- The timer is defined and documented; the actual enabling happens on the server in T-26.
- A failed run is distinguishable from an empty run.

**Automated verification:** none — operational configuration.

**Manual verification:** on the pilot host, trigger the service manually and confirm the summary file
appears.

---

# Group G — Deployment

## Task 26 — Write the deployment configuration templates

**Objective:** Commit inert, correct-by-default templates for the reverse proxy, the service unit and
the backup script, so a deployment is assembled from reviewed configuration rather than improvised.

**Components:** `apps/backend/deploy/nginx-safesignal.conf.example` (new),
`apps/backend/deploy/safesignal-api.service.example` (new),
`apps/backend/deploy/backup-postgres.sh.example` (new),
`apps/backend/deploy/README.md` (new).

**Depends on:** Task 23 (the variable names), Task 3 (the hosting decision for the paths and the
domain).

**Requirements:** FR-10.1 … FR-10.4, SR-5.1, SR-5.2, SR-6.1, SR-7.1, SR-7.2, SR-9.1, SR-9.2, SR-11.2, SR-12.1, OR-2.1, OR-3.1, OR-4.1, OR-4.2, RR-7.1.

**Changes**

1. **Proxy template:** TLS termination with a modern cipher set; HSTS with `max-age` and
   `includeSubDomains`; `X-Content-Type-Options: nosniff`; `X-Frame-Options: DENY`;
   `Referrer-Policy: no-referrer`; a CSP for the web app (`default-src 'self'`, `connect-src` to the
   API origin, `object-src 'none'`, `base-uri 'self'`, `frame-ancestors 'none'`);
   `proxy_set_header X-Forwarded-For $remote_addr` — **overwriting**, never appending; a custom
   `log_format` that excludes request bodies and the `Idempotency-Key` and `X-Admin-Key` headers;
   plain HTTP redirected to HTTPS.
2. **Service unit:** one Uvicorn worker; `--proxy-headers --forwarded-allow-ips=127.0.0.1`; the
   environment file path; the working directory; restart on failure; a read-only filesystem where
   possible.
3. **Backup script:** `pg_dump -Fc` piped through encryption, uploaded off-host, old archives removed
   past the backup retention, `set -euo pipefail`, no credentials in the script (SR-12.1).
4. **README:** what to fill in, what to verify, and the "do not copy verbatim" warning.
5. All site-specific values are placeholders (FR-10.4).

**Acceptance criteria**

- No template contains a credential or a real hostname.
- The proxy template overwrites `X-Forwarded-For`.
- The service unit runs exactly one worker and trusts only `127.0.0.1`.
- The access log format cannot emit a request body or a sensitive header.

**Automated verification:** a lint script that greps the templates for the forbidden patterns
(`proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for`, a second `--workers`, a literal
password) and fails the build.

**Manual verification:** review each template line by line before it is used.
---

## Task 27 — Write the operator runbook and the deployment checklist

**Objective:** Give the person operating the pilot one document: how it is deployed, how the key is
custody'd and rotated, how retention and backup run, and what to do if something goes wrong.

**Components:** `docs/RUNBOOK.md` (new).

**Depends on:** Tasks 23, 24, 25, 26.

**Requirements:** SR-1.1, SR-1.2, SR-1.3, SR-2.1, SR-7.3, SR-11.1, OR-1.2, OR-3.1, OR-3.3, OR-4.1, OR-7.1, PR-11.1, PR-11.2.

**Changes**

1. Topology diagram and the components in play.
2. The environment variable table and how each is sourced.
3. **Admin key custody:** who holds it, that there is exactly one copy, and the rotation trigger
   (personnel change, suspected leak, quarterly). The rotation procedure (SR-1.3).
4. The single-worker rule and why the rate limiter depends on it (SR-11.1).
5. The proxy requirement to overwrite `X-Forwarded-For`, and what to check if rate limiting behaves
   oddly (SR-7.3).
6. The retention job: schedule, environment, expected output, how to tell a failed run from an empty
   one, and who may authorise a manual delete.
7. Backup and restore: how to take a backup, how to restore, and the restore-test cadence.
8. Log locations, rotation and retention, and the confirmation that no request body is logged.
9. The incident-response path for a suspected key leak (rotate, review access, notify) and for a
   suspected data exposure.
10. The pilot deployment checklist: `VITE_PROTOTYPE=false` is set, the mock admin screen is not
    reachable, the admin key is not the development value, and the backups have been restored at least
    once (SR-2.1).
11. A note that the response team's metadata needs are still undecided (PR-11.1).

**Acceptance criteria**

- An operator who did not build the system can perform a backup, a restore, a retention run and a key
  rotation from this document alone.
- Every checklist item is objectively checkable.

**Automated verification:** none.

**Manual verification:** a dry run of the backup and restore procedure against a scratch database.

---

# Group H — Verification

## Task 28 — Flutter widget tests for the pending-report flows

**Objective:** Automated coverage of every pending-report screen and message.

**Components:** `apps/mobile/test/pending_draft_test.dart` (new),
`apps/mobile/test/pending_draft_flow_test.dart` (new), `apps/mobile/test/helpers.dart` (a fake store
helper).

**Depends on:** Tasks 15, 16, 17, 18, 19, 20.

**Requirements:** AR-1.3, AR-3.1, AR-4.1, AR-4.2, AR-5.1, RR-1.1.

**Coverage**

- Save writes exactly one record containing the canonical payload and the current key.
- Restore populates the draft and installs the key.
- Discard deletes the record and clears the draft.
- The restore prompt appears only when a valid record exists.
- The corrupt-record path shows the error banner and deletes the record.
- The expired-record path shows the expiry message and deletes the record.
- The edited-after-restore path shows the notice and mints a new key.
- The unknown-outcome path keeps the record and states that retrying is safe.
- Every new message is announced through a live region.
- No overflow at 2× text scale, in English and in Kiswahili.
- Contrast and touch-target assertions for the new controls.

**Acceptance criteria:** all pass, in both locales, at the default and 2× text scale.

**Automated verification:** the suite itself.

**Manual verification:** none.
---

## Task 29 — Integration test: restart, restore, and the unchanged retry

**Objective:** Extend the opt-in integration test to cover the case the whole feature exists for: the
app is killed between saving and submitting.

**Components:** `apps/mobile/test/integration/backend_timeout_retry_test.dart` (extend),
`apps/mobile/test/integration/pending_draft_restart_test.dart` (new).

**Depends on:** Tasks 15, 18.

**Requirements:** RR-2.1, RR-2.2, RR-2.3.

**Scenario**

1. Start a real uvicorn against the in-memory store (the existing pattern).
2. Save a pending report through the real controller and the real store.
3. Drop the controller and the store instance, and construct a fresh pair — simulating a process
   restart.
4. Restore, then submit.
5. Assert: the request carried the **same** `Idempotency-Key` as before; the request body was
   byte-identical to the saved payload; exactly one report is stored; the returned code is the
   original's.

A second scenario: freeze the server so the first attempt times out, resume it so it accepts late,
then restart, restore and retry — asserting still one stored report and the original code.

**Acceptance criteria:** the test passes with `SAFESIGNAL_BACKEND_IT=1` against a local backend, and
is skipped with a clear reason otherwise.

**Automated verification:** the test itself.

**Manual verification:** run it once on a desktop before the device test.
---

## Task 30 — React reporting-flow tests

**Objective:** Automated coverage of the React submission path, including the failure messaging from
Task 9.

**Components:** `apps/frontend/src/lib/submissionKeyPolicy.test.ts` (new),
`apps/frontend/src/screens/NextStepScreen.test.tsx` (new).

**Depends on:** Tasks 7, 8, 9.

**Requirements:** FR-6.1, FR-6.2, RR-1.2, RR-3.3.

**Coverage**

- `resolveSubmissionKey` reuses the key for an unchanged signature and mints a new one for a changed
  signature.
- Two identical submissions send the same `Idempotency-Key` header.
- A changed payload sends a different key.
- A timeout shows the timeout banner, including the reload caveat.
- A network error shows the network banner, including the reload caveat.
- The submit button is disabled while a submission is in flight.
- No incident content is written to `localStorage` (assert the storage is empty after a flow).

**Acceptance criteria:** all pass; `npm run test` is green.

**Automated verification:** the suite itself.

**Manual verification:** none.
---

## Task 31 — Device verification on physical Android hardware

**Objective:** Produce dated evidence for everything that cannot be asserted in an emulator: FLAG_SECURE,
backup exclusion, process restart, Quick Exit, TalkBack, and low-end performance.

**Components:** `docs/M4_DEVICE_VERIFICATION.md` (new), `docs/DEVICE_TEST.md` (extend).

**Depends on:** Tasks 19, 21, 22, 29.

**Requirements:** AR-6.2, PR-8.1, SR-6.2, SR-13.4, OR-2.2.

**Checks**

1. **FLAG_SECURE:** a screenshot on the report and review screens produces a blocked frame; the
   recent-apps thumbnail shows no report content.
2. **Backup exclusion:** an `adb backup` / backup inspection shows no SafeSignal data; the app's data
   directory holds no report text after Quick Exit.
3. **Process restart:** save a report, force-stop the app, relaunch, restore, submit — one report, the
   original code.
4. **Quick Exit with a saved draft:** save, Quick Exit, relaunch — no restore prompt, no report text on
   disk.
5. **TalkBack:** save, restore, discard, and the error paths are operable by TalkBack alone, in
   English and in Kiswahili.
6. **Low-end performance:** on the reference low-end device, save and restore complete within a stated
   budget, with no visible jank on the reporting screens; cold start is not materially slower with a
   record present.
7. **Restore test:** a backup taken on the pilot host is restored into a clean database and the row
   counts compared (OR-2.2).

**Acceptance criteria:** each check has a dated record naming the device model, the Android version,
the steps and the observed result.

**Automated verification:** none — this is the manual evidence task.

**Manual verification:** this task *is* the manual verification.

**Note:** no claim of physical-device verification may appear anywhere until this task is complete and
recorded (OR-6.2).
---

## Task 32 — Controlled usability testing with simulated incidents

**Objective:** Check that people understand what the app does with their report — especially what is
saved on the phone and what Quick Exit does not erase — using simulated scenarios only.

**Components:** `docs/M4_USABILITY_PROTOCOL.md` (new), `docs/M4_USABILITY_FINDINGS.md` (new).

**Depends on:** Tasks 1, 16, 19, 20.

**Requirements:** AR-6.1, AR-6.2, PR-2.1, PR-2.2, PR-8.2.

**Protocol**

1. Scenarios are **simulated**: no real incident data, no real victim accounts, no real vehicles or
   operators. A written scenario sheet covers: reporting something that just happened offline; seeing
   the "save for later" offer; restoring after a restart; using Quick Exit with a saved report; and
   reading the disclosure text.
2. Participants are recruited to match the pilot audience, with informed consent and the right to stop.
3. Sessions are in English and in Kiswahili, in both locales.
4. Measurements: task completion, the number of unprompted questions about what is stored and what is
   sent, and whether any participant believes a report is anonymous or that Quick Exit erased the
   device.
5. Findings are recorded without personal identifiers.

**Acceptance criteria**

- The protocol exists and is followed before the pilot.
- Every participant who believed the report was anonymous, or that Quick Exit erased the device, is
  recorded as a comprehension failure and fed back into the copy in Task 1.

**Automated verification:** none.

**Manual verification:** this task *is* the manual verification.

**Note:** this is **BLOCKED — D-K (founder)**: it needs an approved participant group, a session slot
and an ethics/consent position.
---

## Task 33 — Assemble the pilot-readiness document

**Objective:** Produce `docs/PILOT_READINESS.md`: the single place that says what is ready, what is
verified, and what is not.

**Components:** `docs/PILOT_READINESS.md` (new), `docs/CHECKLIST.md`, `docs/ROADMAP.md`,
`docs/SECURITY.md` (final pass).

**Depends on:** all previous tasks.

**Requirements:** OR-6.1, OR-6.2, PR-7.1, PR-7.2, XR-1 … XR-16.

**Changes**

1. A table of every requirement in `requirements.md` with its status and the evidence that backs it
   (a test file, a device record, a document, or the named blocker).
2. An explicit list of what is **not** verified: anything without evidence stays on that list.
3. A readiness checklist for the pilot decision: the retention period is set (D-A), the backup
   retention is set (D-B), the hosting is chosen and the templates are applied (D-E), the admin key
   custody is assigned (D-J), the legal review is complete, the assistant scope is decided (D-F), the
   screenshot trade-off is accepted (D-G), the pilot participants and operator are named (D-K).
4. Any requirement that is still blocked is listed with its owner. The document must not present a
   blocked item as done.
5. Update `docs/CHECKLIST.md` § 5, § 7, § 10, § 12 and `docs/ROADMAP.md` with the M.4 position.

**Acceptance criteria**

- Every requirement appears exactly once with a status and evidence.
- No blocked requirement is marked complete.
- No physical-device, production or legal verification is claimed without a dated record.
- The pilot checklist has no unchecked item.

**Automated verification:** a script that cross-checks the requirement identifiers in
`requirements.md` against the ones listed in `docs/PILOT_READINESS.md` and fails if any is missing.

**Manual verification:** the founder walks the checklist.

---

---

# Traceability matrix

## Requirement → task

| Requirement | Tasks |
|---|---|
| FR-1 Flutter capture | T-10, T-11, T-15 |
| FR-2 Restore | T-15, T-16 |
| FR-3 Discard | T-17, T-19 |
| FR-4 Expiry | T-10, T-14 |
| FR-5 Submission of a restored report | T-18, T-19 |
| FR-6 React: no persistent browser storage | T-08, T-09, T-30 |
| FR-7 Retention tooling | T-24 |
| FR-8 Retention configuration, fail closed | T-02, T-24 |
| FR-9 Production environment validation | T-23 |
| FR-10 Deployment configuration artifacts | T-26 |
| FR-11 Quick Exit deletes the pending report | T-19 |
| SR-1 Admin authentication | T-04, T-05, T-27 |
| SR-2 No public admin surface | T-04, T-27 |
| SR-3 Encryption at rest | T-10, T-11, T-12 |
| SR-4 Storage integrity | T-10, T-13 |
| SR-5 No sensitive data in logs | T-23, T-24, T-26 |
| SR-6 Transport security | T-26, T-31 |
| SR-7 Trusted proxy configuration | T-26, T-27 |
| SR-8 Restricted CORS | T-23 |
| SR-9 Security response headers | T-26 |
| SR-10 Idempotency contract integrity | T-04, T-05 |
| SR-11 Rate limiting behind a proxy | T-26, T-27 |
| SR-12 Secrets handling | T-12, T-26 |
| SR-13 Android local hardening | T-12, T-21, T-22, T-31 |
| PR-1 No account required | T-01, T-04 |
| PR-2 No anonymity guarantee | T-01, T-32 |
| PR-3 No automatic sharing | T-01, T-04 |
| PR-4 Location and tracking | T-04, T-22 |
| PR-5 No public individual reports | T-04 |
| PR-6 No new sensitive analytics | T-04 |
| PR-7 AI assistant data handling | T-01, T-33 |
| PR-8 Device-local traces disclosure | T-01, T-19, T-31, T-32 |
| PR-9 Retention and deletion disclosure | T-01, T-02, T-24 |
| PR-10 Clipboard residual risk | T-01, T-04 |
| PR-11 Metadata minimisation | T-01, T-04, T-27 |
| RR-1 Existing idempotency preserved | T-05, T-28, T-30 |
| RR-2 Durable client key recovery | T-15, T-18, T-29 |
| RR-3 Duplicate prevention | T-08, T-09, T-15, T-18, T-30 |
| RR-4 Deterministic failure handling | T-13, T-18, T-19 |
| RR-5 No automatic background submission | T-04, T-15, T-22 |
| RR-6 Retention and key expiry coupling | T-02, T-24 |
| RR-7 Deployment availability | T-23, T-26 |
| AR-1 Announcing the saved-report state | T-16, T-17, T-28 |
| AR-2 Touch targets and focus | T-16, T-17 |
| AR-3 Text scaling and localisation | T-16, T-17, T-20, T-28 |
| AR-4 Error announcement | T-16, T-17, T-18, T-19, T-28 |
| AR-5 Contrast | T-16, T-17, T-28 |
| AR-6 Keyboard and screen-reader pass | T-31, T-32 |
| OR-1 Retention job operation | T-24, T-25, T-27 |
| OR-2 Backup and restore verification | T-02, T-26, T-31 |
| OR-3 Monitoring | T-25, T-26, T-27 |
| OR-4 Log hygiene | T-26, T-27 |
| OR-5 CI gates | T-05, T-06, T-07 |
| OR-6 Pilot-readiness documentation | T-33 |
| OR-7 Runbook | T-27 |
| OR-8 Hosting decision | T-03 |
| XR-1 … XR-16 Exclusions | T-04, T-33 |

## Task → requirement

| Task | Requirements |
|---|---|
| T-01 | PR-1.1, PR-2.1, PR-2.2, PR-3.1, PR-7.1, PR-7.2, PR-7.3, PR-8.2, PR-9.1, PR-9.2, PR-10.3, PR-11.1 |
| T-02 | FR-8.2, FR-8.3, OR-2.3, PR-9.3, RR-6.2 |
| T-03 | OR-8.1, OR-8.2 |
| T-04 | XR-1 … XR-16, SR-1.2, SR-2.2, SR-10.1, SR-10.2, PR-1.1, PR-1.2, PR-3.1, PR-3.2, PR-3.3, PR-4.1, PR-5.1, PR-5.2, PR-6.1, PR-6.2, PR-10.1, PR-10.2, RR-5.2, PR-11.2 |
| T-05 | OR-5.1, OR-5.4, SR-1.1, SR-10.3, RR-1.1 |
| T-06 | OR-5.2 |
| T-07 | OR-5.3 |
| T-08 | FR-6.2, FR-6.4, RR-3.3 |
| T-09 | FR-6.3, RR-3.3 |
| T-10 | FR-1.3, FR-4.1, FR-4.4, SR-3.4, SR-4.1 |
| T-11 | SR-3.2, SR-3.4, FR-1.3 |
| T-12 | SR-3.1, SR-3.2, SR-3.3, SR-12.2, SR-13.5 |
| T-13 | SR-4.2, SR-4.3, RR-4.1, RR-4.2, RR-4.3 |
| T-14 | FR-4.2, FR-4.3 |
| T-15 | FR-1.1, FR-1.2, FR-1.4, FR-1.5, FR-2.2, FR-2.3, RR-2.1, RR-3.2, RR-5.1 |
| T-16 | FR-2.1, FR-2.4, FR-2.5, AR-1.1, AR-1.2, AR-1.3, AR-2.1, AR-2.2, AR-3.1, AR-4.1, AR-4.2, AR-5.1 |
| T-17 | FR-3.1, FR-3.2, FR-3.3, AR-1.1, AR-2.1, AR-2.2, AR-3.1, AR-4.1, AR-4.2, AR-5.1 |
| T-18 | FR-5.1, FR-5.2, FR-5.3, FR-5.6, RR-2.2, RR-2.3, RR-3.1, RR-4.4, AR-4.1 |
| T-19 | FR-11.1, FR-11.2, FR-11.3, FR-11.4, FR-5.4, FR-5.5, FR-3.3, RR-4.3, PR-8.1, AR-4.1 |
| T-20 | AR-3.2, AR-3.3 |
| T-21 | SR-13.1, SR-13.2 |
| T-22 | SR-13.3, SR-13.4, SR-13.5, PR-4.2, PR-4.3, RR-5.3 |
| T-23 | FR-9.1, FR-9.2, FR-9.3, SR-8.1, SR-8.2, SR-8.3, SR-5.2, RR-7.1, RR-7.2 |
| T-24 | FR-7.1 … FR-7.6, FR-8.1, RR-6.1, RR-6.3, SR-5.3, OR-1.1, PR-9.2 |
| T-25 | OR-1.2, OR-1.3, OR-3.2 |
| T-26 | FR-10.1 … FR-10.4, SR-5.1, SR-5.2, SR-6.1, SR-7.1, SR-7.2, SR-9.1, SR-9.2, SR-11.2, SR-12.1, OR-2.1, OR-3.1, OR-4.1, OR-4.2, RR-7.1 |
| T-27 | SR-1.1, SR-1.2, SR-1.3, SR-2.1, SR-7.3, SR-11.1, OR-1.2, OR-3.1, OR-3.3, OR-4.1, OR-7.1, PR-11.1, PR-11.2 |
| T-28 | AR-1.3, AR-3.1, AR-4.1, AR-4.2, AR-5.1, RR-1.1 |
| T-29 | RR-2.1, RR-2.2, RR-2.3 |
| T-30 | FR-6.1, FR-6.2, RR-1.2, RR-3.3 |
| T-31 | AR-6.2, PR-8.1, SR-6.2, SR-13.4, OR-2.2 |
| T-32 | AR-6.1, AR-6.2, PR-2.1, PR-2.2, PR-8.2 |
| T-33 | OR-6.1, OR-6.2, PR-7.1, PR-7.2, XR-1 … XR-16 |

## Task dependency order

```
T-01 Privacy notice ──────────────┐
T-02 Retention policy record ──┐   │
T-03 Hosting comparison ───────┤   │
T-04 Scope & exclusion audit ──┤   │
                                │   │
T-05 PostgreSQL in CI ──────────┤   │
T-06 Flutter CI job ────────────┤   │
T-07 React test harness ────┐   │   │
                             │   │   │
T-08 key policy module ◄─────┘   │   │
T-09 reload disclosure ◄──────────┘   │
                                        │
T-10 record model ─► T-11 interface ─► T-12 encrypted store ─► T-13 robustness ─► T-14 expiry
                                                        │                              │
                                                        ▼                              ▼
                                            T-15 controller integration ─► T-16 restore prompt
                                                        │                     └► T-17 discard
                                                        │                     └► T-18 submission paths
                                                        │                              │
                                                        └──────────────────────────────┴──► T-19 deletion + Quick Exit
                                                                                                │
                                                                    T-20 strings ◄──────────────┘
                                                                        │
T-23 env validation ─┐                            T-21 FLAG_SECURE ─┐  │
T-24 retention tool ─┼─► T-25 scheduling ─┐      T-22 backup excl ─┤  │
T-02 retention policy┘                     │                       │  │
                                          ▼                       │  │
                          T-26 deployment templates ◄── T-03 hosting┘  │
                                          │                              │
                                          ▼                              │
                                 T-27 runbook                           │
                                          │                              │
                                          ▼                              ▼
                        T-28 Flutter tests ──► T-29 restart integration ──► T-31 device verification
                        T-30 React tests ─────────────────────────────────► T-32 usability testing
                                                                                 │
                                                                                 ▼
                                                                        T-33 pilot readiness
```

---

# External dependencies and blocked work

| Item | Blocks | Owner | Needed by |
|---|---|---|---|
| D-A Report retention period (and whether closed cases differ) | FR-8.2, FR-8.3, PR-9.3, OR-2.3 | Founder + legal | Before the retention tool may delete anything (T-24), and before T-33 |
| D-B Backup retention period | OR-2.3 | Founder + legal | Before T-26's backup script is finalised |
| D-C Reporter-initiated deletion path | PR-9.1 | Founder + legal | Before T-01 is finalised |
| D-D Consent semantics | PR-3.2 | Founder + legal | Before T-01 is finalised |
| D-E Hosting provider | OR-8.1, OR-8.2; all of Group G | Founder | Before T-26 is applied to a server |
| D-F Assistant in pilot scope | PR-7.1, PR-7.2 | Founder | Before T-01 is finalised |
| D-G Accept the screenshot-blocking trade-off | SR-13.1 | Founder | Before T-21 |
| D-H Approve `flutter_secure_storage` | SR-3.1; all of Group D | Founder | Before T-12 |
| D-I Approve the React test dev dependencies | OR-5.3 | Founder | Before T-07 |
| D-J Admin key custody and rotation trigger | SR-1.3 | Founder | Before T-27 |
| D-K Pilot participants, operator and session slot | T-32, T-33 | Founder | Before T-32 |
| D-L Response team's metadata needs | PR-11.1 | Founder (needs D-K) | Before T-27 |

**Not blocked, and safe to start on approval:** T-01 (draft with placeholders), T-02 (draft with
placeholders), T-03, T-04, T-05, T-06, T-07 (after D-I), T-08, T-09, T-10, T-11, T-13, T-14, T-15,
T-16, T-17, T-18, T-19, T-20, T-23, T-24 (shipped inert), T-25, T-26 (as templates), T-27, T-28, T-29,
T-30, T-31, T-33.

---

# Definition of done for M.4

1. Every requirement in `requirements.md` appears in `docs/PILOT_READINESS.md` with a status and
   evidence.
2. Every task above is complete, or is explicitly recorded as blocked with an owner.
3. The full test suite is green in CI: backend unit, backend PostgreSQL integration, Flutter unit and
   widget, React.
4. The device verification record exists, dated, with nothing claimed that was not observed.
5. The retention tool is inert until a period is configured — it must never delete on a default.
6. Nothing in the app or the documentation claims anonymity, or claims that Quick Exit erased the
   device, or claims a verification that has not happened.
7. The pilot checklist in `docs/PILOT_READINESS.md` has no unchecked item.

**Implementation starts only on the founder's approval of Task 1.**
