# SafeSignal privacy notice

**Version:** 1.0 (first version)
**Last updated:** 21 October 2026
**Covers:** the SafeSignal web app, the SafeSignal Android app, and the SafeSignal server that stores
reports.
**Written by:** the SafeSignal project.

> **Read this first.** SafeSignal is a prototype. It has not been deployed for public use and has not
> been tested with real users. It has not had a security audit or a legal review. Some behaviour
> described here is **planned but not yet available**; those sections are marked clearly. Where a
> decision has not been made yet, this notice says so instead of guessing.

---

## 1. In short

| Question | Answer |
|---|---|
| Do I need an account? | No. There is no sign-in, no password, and no account of any kind. |
| Do you collect my name or phone number? | No. Neither is ever sent or stored. |
| Do you collect my GPS location? | No. Location is only ever free text that you type yourself, and it is optional. |
| Do you track me in the background? | No. The Android app asks for one permission only: internet access. |
| Who can see my report? | Whoever holds the SafeSignal administrative key. There are no per-person accounts and no record of who looked. |
| Do you share my report with anyone? | No. Not with a SACCO, not with police, not with an NGO, not with anyone. |
| Do you contact anyone when I report? | No. Nobody is contacted, and nobody is dispatched. |
| How long do you keep my report? | There is no automatic deletion yet. The retention period is not yet decided — see section 10. |
| Can I be anonymous? | We cannot promise that. See section 13. |
| Is the AI assistant safe for me to use? | It sends your question to a third-party provider. See section 9. |

---

## 2. Who this notice covers

This notice describes the SafeSignal web app (run in your browser), the SafeSignal Android app, and
the SafeSignal server that both of them submit to. It also covers the SafeSignal guidance
assistant, which is only available on the web.

It does not cover anything outside these components: for example your phone operating system, your
keyboard app, your browser, or your network provider.

---

## 3. What a report contains

When you submit a report, SafeSignal sends the following and nothing else:

| Field | What it is | Required? |
|---|---|---|
| Incident type | One of: harassment, threats, unwanted touching, being followed, dangerous driving, or something else | Yes |
| Timing | Whether it is happening now or already happened | Yes |
| Route or corridor | Free text you type, up to 120 characters | No |
| Area or place | Free text you type, up to 120 characters | No |
| Number plate or vehicle name | Free text you type, up to 20 characters | No |
| SACCO or operator | Free text you type, up to 80 characters | No |
| What would help most | Your choice of: send it to SafeSignal only, or show me emergency and support numbers | Yes |
| Contact provided | A yes/no flag. It is always `false` today, and the server does not store it | No |
| Consent to share | A flag that is always `false`, because SafeSignal does not share reports | No |

Two of the four "what would help most" options — alerting someone you trust, and asking a
partner organisation to check in on you — are shown as unavailable. They are in development and
cannot be selected. Neither would involve SafeSignal contacting anyone today.

### What a report never contains

- **No name.** There is no field for one.
- **No phone number.** There is no field for one. The payload carries a yes/no "contact provided"
  flag, which is always `false` — the options that would have collected a number are unavailable —
  and the server does not store that flag either.
- **No GPS coordinates.** SafeSignal does not read your position. The "area" field is text you type.
- **No email address.**
- **No account, sign-in or password.**
- **No device identifier, advertising ID, or your contacts.**
- **No analytics, advertising or tracking software.** Neither app contains one.

### What you type is stored as you typed it

The free-text fields are saved exactly as entered. The app asks you not to type names or phone
numbers, but nothing detects, warns about or removes identifying detail that you type yourself. If a
name, a workplace, a school or a description of a person ends up in a free-text field, it is stored.

---

## 4. What stays on your device

### 4.1 The web app

The web app keeps your report in the page's memory only. There is no server-side session and no
draft is saved. Closing the tab, reloading the page, or pressing Quick Exit discards everything you
typed.

The single thing the web app writes to your browser is your light-or-dark theme choice, under the
key `safesignal-theme`. No report text, no reference code and no submission key is ever written to
browser storage.

### 4.2 The Android app

**Today, the Android app writes nothing about your report to the device.** Your draft is held in
memory only. If the app is closed, killed by the operating system, or you use Quick Exit, the draft
is gone.

The Android app requests exactly one permission: internet access. It requests no location,
camera, microphone, contacts, phone-state, notification or storage permission, and it runs no
background service.

One thing to be aware of: Android's automatic backup is **not** currently switched off for this
app. Because the app writes no report data to disk today, a device backup contains no report. This
is scheduled to be changed before reports can be saved on a phone — see section 4.3.

### 4.3 Saving a report for later (planned — not available yet)

> **Status: this feature does not exist in the current build. It is planned for the next release.**
> The section below describes what it will do, so that you know what to expect. It is not a
> description of today's behaviour.

When this feature is available, and **only** if you tap "Save for later" yourself:

- The report text and the submission key are written to the app's own private storage, encrypted
  using a key held by the Android Keystore — the phone's hardware-backed key store. The key is not
  a password, it is not in the app's files, and it is not recoverable from the app.
- Only one report can be saved at a time. There is no queue and no list.
- The saved report is deleted when the report is successfully submitted, when you discard it, and
  when you use Quick Exit.
- The saved report expires after 24 hours by default.
- The app will never send a saved report on its own. You always tap submit yourself.
- If the phone's key store is unavailable, the app will tell you that saving is not possible rather
  than fall back to storing your report unencrypted.

The web app will not have this feature. A browser draft would have to be written to browser
storage, which is readable by other scripts on the page and by browser extensions, and SafeSignal
will not put your report there. A web draft is lost if you reload the page.

---

## 5. Quick Exit: what it does, and what it does not do

Quick Exit is the red **Exit** button in the Android app, and the **Exit** button or the `Esc` key
on the web app. It clears what SafeSignal holds in memory and leaves the app immediately.

**Quick Exit does clear:**

- The report you are writing, on both the web app and the Android app.
- Any saved report, when the save-for-later feature described in section 4.3 is available.
- The app's waiting for a submission that had not yet been confirmed. The request itself may still
  have reached the server.

**Quick Exit does not erase:**

- **The Android recent-apps thumbnail.** When you leave the app, Android keeps a snapshot of the
  screen you were on. If that screen showed your route, plate or operator, that snapshot contains
  it. Quick Exit cannot reach it.
- **Screenshots and screen recordings.** You, or somebody near you, can capture the screen. Nothing
  blocks that today.
- **Your keyboard's history.** Autocorrect and keyboard-learning apps may keep words you typed into
  the report fields. That data belongs to the keyboard app, not to SafeSignal.
- **The clipboard, or the clipboard's history.** See section 12.
- **The browser's own history and back/forward cache** (web app). Quick Exit replaces the page with
  a neutral site, but the browser may keep the previous page in its back/forward cache.
- **Anything already sent to the server**, and anything in the server's backups.
- **Android's own app backup** of the app's data.

Quick Exit never blocks. If a saved report cannot be deleted, the app says so plainly and offers you
a choice, rather than pretending the device was cleared.

---

## 6. What the server stores

When a report reaches the server, the server stores:

| Field | Notes |
|---|---|
| A random internal identifier | Not linked to you |
| A reference code, such as `SS-K7QP-3M2X` | The code you see on screen. See section 12 |
| Incident type | |
| Urgency | Worked out by the server from the incident type and the timing |
| Timing, route, area, plate, SACCO, and what would help most | Your free text, as entered (the plate is stored in upper case) |
| Consent to share | Always `false` |
| Status, such as `Received` | Changed by the operator, not by you |
| The exact time the report was received | To the millisecond |
| The time a status was first changed | If it was |

The server also keeps a short row that links your submission key to your report. Its purpose is
simple: if you tap submit again after a failed or timed-out attempt, SafeSignal recognises the
retry and returns the report it already has instead of storing a second copy. That row holds the
submission key, a SHA-256 fingerprint of the report text, and a timestamp.

**The report database does not store your IP address.** The rate limiter counts submissions per
address in memory only, and those counters are lost when the server restarts.

In development, SafeSignal can run without a database, holding reports in memory only — in which
case every report is lost when the server restarts. The persistent mode uses PostgreSQL.

---

## 7. Who can see a report

- **Whoever holds the SafeSignal administrative key.** Administrative access is a single shared
  secret. It fails closed: if it is unset, empty or blank, nobody can get in.
- Administrative access can list every report in full, and can change a report's status.
- **There are no per-person accounts, no roles and no record of who read or changed a report.** If
  someone with the key opens your report, nothing logs that they did.
- **Your reference code cannot be looked up.** There is no page or service where you can enter your
  code and see your report. See section 12.
- Reports are not published, listed, mapped or searchable by the public.

SafeSignal has not yet deployed a service for real use, so in practice the only people who could
see a report are the project maintainers who hold the administrative key.

---

## 8. What SafeSignal does not do

SafeSignal does **not**:

- contact police, a SACCO, an NGO, a transport operator, or any other third party;
- forward, share, sell or publish your report;
- contact anyone, send an SMS, or make a call on your behalf;
- dispatch anyone to help you;
- verify, corroborate or review reports, or tell you whether a route, vehicle or stage is safe;
- publish incident maps, feeds, counts or any individual report;
- monitor your location, or your routes, in the background.

**SafeSignal is not an emergency service.** Nothing you write will bring anyone to you. If you are
in immediate danger, call **999** or **112**.

---

## 9. The guidance assistant (web app only)

The web app has a guidance assistant that explains how reporting works and gives general commuter
safety tips. It is not available in the Android app.

If you type a question of your own, the following happens:

- Your message, together with up to six earlier turns of the conversation, is sent to **OpenRouter**,
  a third-party company outside Kenya, which passes it to an AI model. Earlier turns include any
  built-in guidance topics you opened earlier in the same conversation.
- Before sending, the server removes text that matches certain patterns: email addresses, Kenyan
  phone numbers, number plates, coordinates, and long runs of digits.
- **That redaction is a safety net, not a guarantee.** It does not catch names, employers, schools,
  descriptions of people, the route you take, the time you travel, or anything else you write in
  your own words.
- Nothing is saved. The conversation is not written to the database, and your message text is not
  written to the server's logs. The OpenRouter key stays on the server. The conversation itself
  stays in the open page until you close it or use the Reset button.
- **The assistant never receives your report.** It cannot see reports, and it cannot check whether
  a route or vehicle is safe.
- The assistant's answers are AI-generated. They may be wrong. They are general guidance, not
  professional emergency, medical or legal advice.
- The assistant does not promise anonymity or confidentiality, and neither does the rest of the
  product.

If you do not want your question sent to a third-party provider, do not type a question. The
built-in guidance topics are fixed text written by SafeSignal and are answered without calling the
provider.

---

## 10. How long reports are kept, and how they are deleted

**There is currently no automatic deletion.** A report stays in the database for as long as the
service runs.

The retention period has not been decided and must be approved before any real report is collected:

> **[RETENTION PERIOD — pending D-A]**

The decision record for this is [docs/RETENTION.md](RETENTION.md). It lists what has to be decided
and who owns each decision. No period has been set there either.

Until that is set, the following is the whole of the deletion story:

- **An operator can delete one report by its reference code**, using
  `DELETE FROM reports WHERE code = 'SS-XXXX-XXXX'`.
- **Deleting a report also deletes its submission key.** This is deliberate: a key must not outlive
  the report it refers to, or a retry of a report that is still on file would be stored a second
  time.
- **A retry that arrives after a deletion is treated as a brand-new report**, and is stored again.
  If you submit the same report twice after it has been deleted, you may end up with two stored
  reports.
- There is no record of a deletion, no bulk or age-based deletion, and no scheduled job.

**There is no way for you to ask for your report to be deleted from inside the app.** That route has
not been established — see sections 14 and 15.

---

## 11. Backups

- The operational plan is a nightly encrypted database dump, kept off the server.
- The dumps contain the same text as the live database, so they are as sensitive as the reports
  themselves.
- The backup retention period has not been decided:

> **[BACKUP RETENTION PERIOD — pending D-B]**

- No restore has been performed or verified on a server yet.
- **A deleted report can still exist in a backup** that was taken before the deletion. Deleting a
  report removes it from the live database, not from every copy of it that has ever been made.

---

## 12. Your reference code and the clipboard

- Your reference code looks like `SS-K7QP-3M2X`. It is generated by the server.
- The app copies it to the clipboard **only** when you tap "Copy code".
- **The app never reads the clipboard** and **never clears it**. Reading it would expose whatever
  else you had copied, and clearing it could destroy something belonging to another app.
- **The clipboard may keep a history of what was copied.** That history can be seen by other apps,
  or by another person using the same device. The copy button is the recommended way to keep your
  code.
- **Your code cannot be looked up today.** Nobody, including you, can use it to retrieve your
  report. Write it down or copy it if you need it.
- In the current prototype, storage may be temporary, so a code may stop being valid.

---

## 13. Why we cannot promise that you are unidentifiable

SafeSignal does not ask for your name or your phone number, and it does not read your position. Even
so, **a report is often identifying from its own contents**:

- The report records the **exact time** it arrived, to the millisecond.
- Combined with a route, a stage, a number plate and an operator, that timestamp can single out
  **one vehicle, on one corridor, in one minute**. Other people on that vehicle may well recall who
  was aboard.
- A free-text field may contain a nickname, a workplace, a school or a description of a person. You
  chose it, and SafeSignal does not remove it.
- Anyone you told, anyone who saw you typing, or anyone who knows exactly where you were and when,
  may be able to connect the report to you.
- We have not yet decided how much time precision the response team actually needs. Until we do,
  the millisecond timestamp is kept as it arrives.
- SafeSignal stores no account, no phone number, and no coordinates read from your device, but it
  also has **no way of proving that a particular report came from a particular person** — and no way
  of proving that it did not.

**SafeSignal makes no guarantee of anonymity, of confidentiality, or that a report cannot be traced
to the person who made it.** Nothing in the app claims otherwise, and this notice does not either.

---

## 14. Contacting us, and asking about a stored report

**No dedicated privacy or data-protection contact has been established yet.** Until one is, the
current route is a private message to the repository owner at
<https://github.com/Root-node1/safe-signal>. Please use a private message or a private security
advisory rather than a public issue, and do not include real incident details in a public issue.

If your question is about a report you filed:

- **Quote your reference code.** Without the exact code, the operator cannot find your report —
  there is no lookup service and no search by content.
- If you want your report deleted, say so explicitly, and quote the code. Deletion is currently a
  manual step performed by the operator.
- A formal route for asking about access to, correction of, or erasure of your report has **not**
  been established. It is an open item (section 15).

---

## 15. What is not settled yet

These decisions are outstanding. Where the answer changes what SafeSignal does, this notice will
be updated.

| Open item | Why it matters to you |
|---|---|
| Report retention period | How long a report about an assault or a threat is kept |
| Backup retention period | How long deleted reports can still exist in a copy |
| A route for you to ask for deletion of your own report | Right now only an operator can delete, and only by code |
| Whether "consent to share" is ever captured, or removed | The field is always `false` and nothing shares reports |
| Where the service and its data are hosted | Determines which country's law applies to your report |
| Whether the guidance assistant is part of a pilot | If it is, your questions go to OpenRouter |
| Whether the Android app blocks screenshots | Today screenshots are possible |
| The saved-report expiry window on the phone | 24 hours by default, once that feature ships |

---

## 16. Changes to this notice

This notice is versioned and dated. It will be updated when:

- a pilot begins and the service is actually deployed;
- the retention period and the backup retention period are set;
- the save-for-later feature is enabled on the phone;
- any of the decisions in section 15 is made.

Every version change will be recorded here:

| Version | Date | Change |
|---|---|---|
| 1.0 | 21 October 2026 | First version. Describes the prototype as built, and marks planned behaviour as planned. |

---

## Related documents

- [docs/SECURITY.md](SECURITY.md) — the technical controls that exist, and the work still required
- [docs/RETENTION.md](RETENTION.md) — the data-lifetime decision record: what has to be decided, and the rule that binds idempotency-key retention to report retention
- [docs/API.md](API.md) — the HTTP endpoints as implemented
- [apps/backend/DATABASE.md](../apps/backend/DATABASE.md) — database setup, backups, and the manual
  deletion command
- [docs/ARCHITECTURE.md](ARCHITECTURE.md) — how the pieces fit together
