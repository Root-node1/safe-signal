# Retention and deletion policy — SafeSignal

**Status:** draft. **No retention value is decided.**
**Version:** 0.1 — the decision record is open; every value in § 2 is undecided.
**Last updated:** 21 October 2026
**Decision owner:** the founder (project owner), with legal review. Decisions D-A, D-B, D-C and D-D
are outstanding.
**Single source of truth:** this file. The retention tool and the privacy notice read from it;
neither is an independent source.
**Traces to:** `requirements.md` FR-8.2, FR-8.3, OR-2.3, PR-9.3, RR-6.2; `design.md` § 8.

> **Nothing in this document sets a period.** A report-retention period, a backup-retention period
> and a reporter-initiated deletion route are founder and legal decisions, and none of them has
> been made (D-A, D-B, D-C, D-D). This file records what has to be decided, what each decision
> constrains, and how deletion will run once a decision exists. Until a value is recorded here and
> signed off in § 9, the retention tool must stay unconfigured and must delete nothing.

---

## 1. Purpose and scope

This is the data-lifetime decision record for SafeSignal. It answers four questions:

1. How long each class of stored data is kept — the decision table (§ 2).
2. How the retention of idempotency keys is bound to the retention of reports (§ 3).
3. What happens to a report that is deleted, and to a retry that arrives afterwards (§ 4).
4. How deletion will be executed, scheduled, observed and authorised (§ 5).

It also fixes the change-control rule: this file is the single source of truth and is edited only
with the founder's approval (§ 6).

**In scope:** the server-side store of reports and idempotency keys, the database backups, and the
operator's manual deletion path.

**Out of scope:** the device-local data handled by the mobile app (the pending report planned for
M.4 has its own lifecycle — deleted on success, on discard, on Quick Exit and on expiry — which is
a device-side policy, not a server retention decision; that feature is not implemented yet);
application and proxy log rotation, except where OR-4.1 makes it a derived constraint on D-A; and
every question about who a report identifies, which is a privacy-notice and legal-review matter
rather than a lifetime decision.

### How to read the status column

| Marker | Meaning |
|---|---|
| **Undecided** | No value exists. The decision owner has not chosen one. |
| **Derived** | The value follows from another value and is not chosen independently. |

---

## 2. Decision table

Every row is undecided as of 21 October 2026. No value below is a policy; each is the place where a
policy must be written down before it can be applied.

| # | Item | Value | Status | Decision | Owner | Blocks |
|---|---|---|---|---|---|---|
| 1 | Report retention — open reports (status is not `Closed`) | — | **Undecided** | D-A | Founder + legal | FR-8.2, PR-9.3, T-24 activation |
| 2 | Report retention — closed reports (status is `Closed`) | — | **Undecided** | D-A | Founder + legal | FR-8.3 |
| 3 | Idempotency-key retention | Bound by the coupling rule (§ 3): never shorter than report retention | **Derived — undecided until D-A is set** | D-A (with D-D as noted in § 7) | Founder + legal | RR-6.1, FR-7.3, RR-6.3 |
| 4 | Backup retention (the `pg_dump -Fc` archives) | — | **Undecided** | D-B | Founder + legal | OR-2.3, the backup script in T-26 |
| 5 | Deleted-report tombstones | Not part of M.4; recorded as a future option (§ 4) | **Undecided** | D-A (as part of) | Founder + legal | Deferred; out of M.4 by XR-13 |
| 6 | Reporter-initiated deletion | — | **Undecided** | D-C | Founder + legal | PR-9.1 |
| 7 | Application and proxy log retention | Must be shorter than or equal to the report retention period (OR-4.1) | **Derived — undecided until D-A is set** | Follows D-A | Founder | OR-4.1 |

Two notes on rows 1 and 2, so that the table is not misread as a claim about the mechanism:

- **M.4's mechanism is uniform.** The retention window applies to all reports alike, by creation
  time, and status does not alter it (FR-8.3). Row 2 exists because a separate, shorter window for
  closed cases may be required by the policy; that is not decided, and the M.4 tool does not
  implement per-status windows.
- **Row 3 is not a free choice.** Its value is constrained by § 3. It may not be shorter than the
  report retention it protects.

Row 6 covers whether a reporter can require deletion of their own report from inside the product.
Today no such route exists: deletion is a manual operator action (§ 5.6), and `docs/PRIVACY.md`
§ 14 says so.

---

## 3. Coupling rule — idempotency keys and reports

> **The rule.** An idempotency key shall never be removed while the report it refers to is still
> retained. Equivalently: **key retention ≥ report retention.** The rule is stated once, here, and
> is referenced by `requirements.md` RR-6.1.

**Why it exists.** A submission key is what lets the server recognise a retry of a report it has
already accepted, and return the original report instead of storing a second copy
(`apps/backend/store.py:80-91`, `apps/backend/store_pg.py:50-51`). If a key were removed while its
report was still on file, a reporter retrying that report would no longer be recognised: the retry
would be stored as a new report. One logical submission would become two stored reports, with two
reference codes. That is the outcome the whole idempotency contract exists to prevent (SR-10.1,
RR-3.1), and it is a privacy harm as well as a correctness one: a report the reporter thought was
a single record would exist twice.

**How M.4 satisfies it.** By never expiring a key independently of its report. The key row points
at the report with `ON DELETE CASCADE`
(`apps/backend/migrations/001_init.sql:26`), so a key is removed **with, or after**, its report and
never before. A separate key-expiry step is therefore unnecessary, and would be actively harmful
if it were configured to run earlier than report retention (`design.md` § 8.2). This is why row 3 of
the decision table is marked *derived* rather than *undecided by choice*.

**The constraint this places on D-A.** The report-retention period must be at least as long as the
realistic window in which a reporter might retry. A reporter retrying minutes or hours after a
timeout is inside the window; a report deleted after the window will not be resurrected by a
stale retry in practice. The length of the window itself is a policy decision and is not invented
here.

---

## 4. Deleting a report deletes its key, and a late retry becomes a new report

**What happens.** Deleting a report removes its idempotency key with it, by foreign-key cascade
(`apps/backend/migrations/001_init.sql:26`). The key is not left behind as a tombstone.

**The consequence.** A retry that arrives **after** the deletion carries a key the server no longer
knows. The server therefore treats it as a new report and stores it again. Two stored reports can
result from one logical submission, and they carry different reference codes. The reporter sees the
new code, not the old one; the earlier report is gone.

**What this requires of the disclosure.** The privacy notice must state that a report may be
deleted after its retention window, and that a retry submitted after the deletion may be stored as
a new report (PR-9.2). `docs/PRIVACY.md` § 10 states both.

**The alternative, deliberately not taken in M.4.** Keeping the key row with a nulled `report_id`
— a tombstone — would let a late retry be recognised and rejected rather than re-created. It
requires a schema migration and a policy decision about how long tombstones live, and M.4 adds no
table and no column to `reports` (XR-13, PR-11.2). It is recorded here as a future option
(`design.md` § 8.2) and is row 5 of the decision table.

---

## 5. Operational procedure

### 5.1 What runs today

**Nothing is scheduled, and nothing is deleted automatically.** There is no cron entry, no timer, no
queue and no TTL mechanism anywhere in the repository. The only deletion path is a manual statement
by the operator who holds `SAFESIGNAL_ADMIN_KEY`:

```
DELETE FROM reports WHERE code = 'SS-XXXX-XXXX';
```

(`apps/backend/DATABASE.md:51`; the same statement is recorded in `docs/PRIVACY.md` § 10 and
`docs/SECURITY.md` § "Privacy considerations".) There is no record of a deletion: no audit table,
no deletion log, and no per-person identity behind the admin key.

### 5.2 What M.4 will add, and why it is inert today

| Element | Rule | Requirement |
|---|---|---|
| Tool | `apps/backend/retention.py`, a command-line job with a `--dry-run` mode | FR-7.1, FR-7.2, T-24 |
| Configuration | `SAFESIGNAL_REPORT_RETENTION_DAYS` — a whole number of days. Unset, empty, zero or non-numeric → the tool prints a message naming the variable, deletes nothing and exits non-zero | FR-8.1 |
| No compiled-in default | No retention period is compiled into the tool, the API, or any configuration template. The tool ships inert and stays inert until a value is set | FR-8.2 |
| Test-database guard | The tool refuses to run against a database whose name does not end in `_test`, unless an explicit override flag is passed | T-24 |
| Locking | One statement inside one transaction, in bounded batches, so that report submission is not blocked beyond the duration of a statement | FR-7.6 |
| Key handling | Keys are removed only with their report, by the existing cascade. The tool never deletes a key independently of its report | FR-7.3, RR-6.1, RR-6.3 |
| Output | Window, counts, start and end time — to standard output and to a run-summary file outside the repository. No report content, no report id, no reference code | FR-7.4, SR-5.3 |
| Run record | The run-summary file is the record of the run. M.4 has no deletion-audit table | FR-7.4, § 4; XR-13 |

### 5.3 Schedule — not set

The plan is a **daily** run at a low-traffic hour, from `cron` or a systemd timer
(`design.md` § 8.4, T-25). The hour, the host, and the enabling of the timer are an operator action
on the pilot host (T-26, T-27) and are **not decided here**. Until D-A is decided the tool has no
window to act on, so there is nothing to schedule.

### 5.4 What a run looks like

The tool prints the window it applied, the number of reports it found, the number of idempotency
keys that go with them, and whether it was a dry run. The shape below is the documented output
(`design.md` § 8.3); the window and the counts are **not** filled in, because no period exists:

```
[retention] window: <days> days (from SAFESIGNAL_REPORT_RETENTION_DAYS)
[retention] reports older than <cutoff timestamp>: <count>
[retention] idempotency keys that would be removed with them: <count>
[retention] dry run: nothing was deleted
```

A real run ends with the deleted counts and a completion timestamp, and writes the same summary as
JSON to the run-summary file. The run-summary file must live outside the repository and be
git-ignored (T-24).

### 5.5 Telling "ran and found nothing" from "did not run"

- **A run that found nothing** still rewrites the run-summary file, with a fresh timestamp and a
  count of zero. A fresh summary with zero counts is a successful run.
- **A run that failed** exits non-zero and does not produce a complete summary.
- **A run that did not happen** leaves the previous summary in place, with its old timestamp.

The exit status is what monitoring alerts on, and the summary file is what an operator reads to
confirm the last successful run (OR-1.1, OR-1.2, OR-1.3, T-25). No monitoring may capture report
content or the admin key (OR-3.3).

### 5.6 Who may authorise a manual delete

**The mechanism available today.** An operator holding `SAFESIGNAL_ADMIN_KEY` can delete a report
by its reference code. The key fails closed — unset, empty or blank authorises nobody — and every
failure returns the same 401 (SR-1.1). There is no per-person identity, no role, and no record of
who deleted what. The custody of that key is itself undecided (D-J), and the shared-key model is a
known limitation rather than a designed control.

**The rule while D-A is undecided.** A manual delete is an individually authorised action, not a
bulk operation, and no standing authorisation for bulk deletion exists while the window is
undecided. The founder owns this rule and this file is where a change to it is recorded. This is an
interim fail-closed position, not a decided policy: it exists because the alternative — a
half-decided window — would allow reports to be deleted on a schedule nobody approved.

**A reporter asking for deletion.** A reporter may ask the operator to delete their report and
quote the reference code; deletion is currently a manual step performed by the operator
(`docs/PRIVACY.md` § 14). Whether an established route for that request exists is D-C.

---

## 6. Change control

1. **This file is the single source of truth** for data-lifetime policy. The retention tool and the
   privacy notice read from it. Neither may introduce a value that is not recorded here.
2. **This file is edited only with the founder's approval.** Legal review is required for D-A, D-B,
   D-C and D-D before their values are written into § 2.
3. **Every change is recorded** in § 9: the date, the decision made, and who approved it.
4. **Writing a value down does not activate it.** A value becomes active only when it is also
   configured in the deployment (`SAFESIGNAL_REPORT_RETENTION_DAYS`) and reflected in
   `docs/PRIVACY.md`. A value present in the environment but absent here is a configuration error,
   and it must be reconciled before the next run.
5. **Until a value is recorded and signed off in § 9, the tool must remain unconfigured** and must
   refuse to delete anything (FR-8.1, FR-8.2).
6. **The release checklist refuses to ship with a placeholder.** The privacy notice carries the
   marked placeholder `[RETENTION PERIOD — pending D-A]` until D-A is decided, and the
   pilot-readiness checklist in T-33 must not be signed off while that placeholder is still in
   place (PR-9.3).

---

## 7. Open decisions

None of these is decided. Each one is recorded here so that the dependency is visible, not so that
work can be guessed at.

| ID | Decision | What it settles | Blocks | Owner | Needed by |
|---|---|---|---|---|---|
| D-A | Report retention period, and whether closed cases are deleted sooner | Rows 1, 2, 3 and 5 of § 2; the value of `SAFESIGNAL_REPORT_RETENTION_DAYS` | FR-8.2, FR-8.3, PR-9.3, OR-2.3; before the retention tool may delete anything (T-24), and before T-33 | Founder + legal | Before any real report is collected |
| D-B | Backup retention period | Row 4 of § 2 | OR-2.3; before T-26's backup script is finalised | Founder + legal | Before T-26 |
| D-C | Whether a reporter-initiated deletion path is needed | Row 6 of § 2 | PR-9.1; before the privacy notice is finalised | Founder + legal | Before T-01 is finalised |
| D-D | Consent semantics: capture `consentToShare` for real, or remove it from the interface and the schema | Whether row 3 of § 2 needs a separate treatment for reports whose consent state is known | PR-3.2; before T-01 is finalised | Founder + legal | Before T-01 is finalised |

**On D-D and the key-retention row.** `consent_to_share` is a stored column that is always `false`,
because both clients hard-code it (`apps/backend/migrations/001_init.sql:14`,
`apps/frontend/src/lib/api.ts:34`, `apps/mobile/lib/api/report_api.dart:73`). It therefore
affects no retention rule today, and M.4 adds no metadata field to `reports` (PR-11.2, XR-13). D-D
is listed here because it is a data-lifetime decision of the same policy set, not because anything
in § 3 depends on it today.

---

## 8. What the code does today

The facts this policy rests on, as of 21 October 2026. Each is verifiable in the repository.

| Fact | Evidence |
|---|---|
| A report's lifetime is anchored to `reports.created_at` (`timestamptz`, server default `now()`), which is indexed | `apps/backend/migrations/001_init.sql:17`, `:21` |
| An idempotency key references its report with `ON DELETE CASCADE` | `apps/backend/migrations/001_init.sql:26` |
| An idempotency key has its own `created_at`, which no code reads | `apps/backend/migrations/001_init.sql:27` |
| Report statuses include `Closed`; status does not currently affect any lifetime rule | `apps/backend/migrations/001_init.sql:16` |
| The same key with the same payload replays the original report; the same key with a different payload is a 409 conflict | `apps/backend/store.py:80-84`, `apps/backend/store_pg.py:40-45`, `apps/backend/reports.py:55-58` |
| A replay consumes no rate-limit allowance: the allowance is charged only when a new report would be created | `apps/backend/store.py:80-86`, `apps/backend/store_pg.py:50-51`, `:73-74` |
| No automatic deletion of reports or idempotency keys exists | `apps/backend/DATABASE.md:50` |
| Deletion by reference code is the only path, and it is manual | `apps/backend/DATABASE.md:51` |
| Backups are a nightly encrypted `pg_dump -Fc` copied off the host, and their retention is not specified | `apps/backend/DATABASE.md:36-37` |
| In-memory mode loses all reports and idempotency keys on restart; it is development only | `docs/SECURITY.md:20` |
| The admin key fails closed and is compared in constant time | `docs/SECURITY.md:7` |
| The privacy notice carries the retention period as a marked placeholder | `docs/PRIVACY.md:265-267`, `:291-293` |
| A deletion does not remove a report from a backup taken before it | `docs/PRIVACY.md:296-297` |

---

## 9. Approval record

No decision has been approved. This table is the record of the decisions that will be, and each
entry is made only by the founder, with legal review for D-A, D-B, D-C and D-D.

| Date | Decision | Value recorded | Approved by | Legal review |
|---|---|---|---|---|
| — | — | — | — | — |

**Sign-off for the policy as a whole** (to be completed when D-A and D-B are decided and the tool
is activated):

| Role | Name | Signature | Date |
|---|---|---|---|
| Founder (decision owner) | | | |
| Legal review | | | |

---

## Related documents

- [docs/PRIVACY.md](PRIVACY.md) — the user-facing notice; it carries the marked retention and
  backup placeholders until D-A and D-B are decided
- [docs/SECURITY.md](SECURITY.md) — the controls that exist, and the work still required
- [apps/backend/DATABASE.md](../apps/backend/DATABASE.md) — database setup, backups, and the manual
  deletion command
- [docs/PILOT_READINESS.md](PILOT_READINESS.md) — *not yet written* (T-33); it will list this file
  as the evidence for the retention requirements
- [docs/RUNBOOK.md](RUNBOOK.md) — *not yet written* (T-27); it will carry the schedule, the
  environment and the failure-handling procedure from § 5
