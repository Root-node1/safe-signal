# SafeSignal M.4 — Hosting comparison for the pilot

**Task:** T-03 (`tasks.md` § "Task 03").
**Requirements traced:** OR-8.1, OR-8.2.
**Status of this document:** comparison complete; **the application host and the database provider
are now selected and recorded in § 10.** The deployment inputs that make that decision operable
(region, server version, recovery, cost ceiling, residency) remain open.
**Decision owner:** founder — **D-E: host and database provider decided on 21 October 2026; the
remaining deployment decisions are still open.**
**All provider facts and prices below were checked on 21 October 2026** (see § 12, Sources).

---

## 1. What this document is, and what it is not

This document does three things:

1. it fixes the **criteria** a SafeSignal pilot host must satisfy, taken from `design.md` § 9.4;
2. it **compares three candidate providers** against every criterion, with the evidence behind each score
   and the pricing evidence behind each cost figure;
3. it carries a **decision record**, with the open inputs, the dependencies and the triggers that
   would force a change.

The **comparison** deliberately does **not** choose a provider: no candidate is preferred, no
ranking is published, and no cost ceiling, data-residency position or legal conclusion is asserted.
The **founder has since recorded a decision** (§ 10): a Contabo Cloud VPS 4 for the application and
Neon PostgreSQL for the data. That choice was **not** derived from the scores in § 5 — it selects
infrastructure that already exists, which the three candidates did not cover — and it was recorded
after the comparison was written, so the comparison is left standing as the record of what was
evaluated and what the criteria require.

> **The provider was not chosen by the code or by this specification.** Nothing in
> `apps/`, `docs/`, the M.4 requirements or the M.4 design selects, implies or depends on a hosting
> provider. The application is provider-agnostic: it is a FastAPI service behind a reverse proxy with a
> PostgreSQL database, and it reads its configuration from environment variables
> (`design.md` § 9.1–9.3). The choice in § 10 was made by a person, and it is recorded here so that
> there is exactly one record of it (OR-8.2).

**Reading the markers**

| Marker | Meaning |
|---|---|
| **VERIFIED** | Checked against a public provider source on 21 Oct 2026; the source is listed in § 12. |
| **UNVERIFIED** | Not established from a public source in this session. Must be confirmed before provisioning. Never a guess. |
| **ASSUMPTION** | A stated working assumption used to make a cost estimate comparable. Not a decision, not a fact about the provider. |
| **FOUNDER INPUT** | A value only the founder can supply (cost ceiling, residency position, acceptable operational load). |

---

## 2. Evaluation criteria and weighting

The criteria are those in `design.md` § 9.4, unchanged in substance, with the "why it matters" column
carried over so that each score can be re-read against its purpose.

| # | Criterion | Why it matters here (design § 9.4) | Proposed weight | Weight status |
|---|---|---|---|---|
| C1 | **Data residency** | Determines the DPA position and where incident data physically sits | 15 | Proposed — founder to confirm |
| C2 | **Managed PostgreSQL availability and version** | M.4 verifies against PostgreSQL 16/18; the target must match what was tested | 15 | Proposed — founder to confirm |
| C3 | **Encrypted backups + off-host copy** | Required by OR-2.1 | 15 | Proposed — founder to confirm |
| C4 | **TLS and reverse-proxy control** | Required by SR-6.1, SR-7.1 | 15 | Proposed — founder to confirm |
| C5 | **Inbound firewall / port-exposure control** | The database must not be reachable from the internet | 10 | Proposed — founder to confirm |
| C6 | **Cost ceiling** | A pilot is a bounded, supervised activity | 10 | Proposed — founder to confirm |
| C7 | **SSH / console access and audit log** | Needed for the operator runbook (OR-7.1) | 10 | Proposed — founder to confirm |
| C8 | **Incident-response and data-export support** | Needed if a report must be produced or erased on request | 10 | Proposed — founder to confirm |

Total 100. **The weights are a proposal, not a decision.** Two criteria (C1 residency position, C6 cost
ceiling) cannot be scored at all until the founder supplies the input, so the weighting cannot be applied
until then. The weights exist so the comparison is reproducible, not so a result is pre-loaded.

### 2.1 Why C2 cannot be closed inside M.4

`design.md` § 9.4 states that M.4 verifies against PostgreSQL 16/18 and that the target must match what
was tested. Today that verification does not exist yet:

- `docs/CHECKLIST.md` § 4 — *"Verified on PostgreSQL 16 or the chosen server version"* is unchecked.
- T-05 (PostgreSQL service container in CI) has not run; its service container is specified as
  `postgres:18` in `tasks.md` § Task 05.
- T-31 (physical-device and server verification) has not run.

**Consequence:** the PostgreSQL version offered by any candidate is **UNVERIFIED** here, and acceptance
criterion 3 of T-03 ("the PostgreSQL version offered is one M.4 has been verified against") **cannot be
satisfied until T-05 and T-31 have run**. This is recorded as a hard constraint on the eventual choice,
not as a defect of any candidate.

---

## 3. Scoring methodology

**Scale (per criterion, per candidate)**

| Score | Meaning |
|---|---|
| 5 | Fully met by the provider's published product, with the control in the provider's hands. |
| 4 | Met, with a documented caveat the pilot can live with. |
| 3 | Met only with additional operator work of roughly a day or more, or with a caveat that touches a privacy requirement. |
| 2 | Not met by the provider; the pilot must build or substitute the control itself. |
| 1 | Conflicts with a stated M.4 requirement or the design topology. |
| 0 | The provider makes the control impossible. |
| **U** | **UNVERIFIED** — no public evidence was found. Not scored, not rounded, not treated as a low score. |
| **F** | **FOUNDER INPUT** — cannot be scored until the founder supplies a value. |

**Rules for using the scores**

1. A score is only assigned where a public source supports it. The source is listed in § 12; an
   unsupported score is written as **U**, never as a low number.
2. **U and F scores are excluded from any arithmetic** and are called out explicitly. A criterion that is
   unverified is not a weakness; it is a gap in the evidence.
3. Scores measure **fit with the M.4 design and requirements**, not general provider quality, and not
   price alone.
4. **No weighted total is published in this document.** The weights in § 2 are the founder's to set, two
   criteria cannot yet be scored, and a total computed from partial inputs would look like a
   recommendation. § 10 provides the worksheet for computing it once the inputs exist.
5. Any score may be revised with a citation. Where a score changed during this task, the reason is
   recorded in the relevant cell.

---

## 4. The candidates

Three candidates are compared, as directed. They were chosen to span the three shapes a pilot could take,
not because one of them was preferred.

| Candidate | Shape | PostgreSQL model | Operator's mental model |
|---|---|---|---|
| **Hetzner Cloud** | IaaS virtual machines | **Self-managed** — PostgreSQL installed and run by the operator on a cloud server; no managed PostgreSQL product | "I run the server" |
| **DigitalOcean** | IaaS virtual machines + a managed data service | **Provider-managed** — DigitalOcean Managed Databases for PostgreSQL | "I run the app; the provider runs the database" |
| **Railway** | Container platform (PaaS) | **Provider-managed single node**, convertible to a provider-managed HA cluster (Patroni / etcd / HAProxy) | "I push a container; the platform runs it" |

### 4.1 The managed-PostgreSQL distinction, stated precisely

The distinction matters because it decides who carries the risk of a data-loss or unavailability
incident during the pilot, and because it decides whether M.4's deployment templates (T-26) apply.

| Model | What the provider runs | What the operator still runs | Applies to |
|---|---|---|---|
| **Provider-managed database service** | The database engine: engine patching, minor-version maintenance, storage management, backup service, (for some editions) automated failover | Credentials, least-privilege roles, schema and migrations, the retention job, restore drills, and the *choice* of network path to the database | DigitalOcean Managed Databases; Railway PostgreSQL (single node, and the HA cluster) |
| **Provider-hosted but operator-maintained database** | Only the machine, the disk and the network | Everything, including PostgreSQL itself: installation, engine patching, major-version upgrades, backup tooling, WAL/archive management, and capacity planning | Hetzner Cloud (no managed PostgreSQL product); **and Railway PostgreSQL if the template image is customised** — Railway's own documentation states that changing the shipped image, start command or variables makes the database the customer's to manage, which moves it out of Railway's support scope |

Consequence for the pilot: a self-managed database is not a cheaper version of a managed one. It is the
same database plus an unfunded, unnamed on-call responsibility for the engine — the exact role that
M.4's runbook (T-27) has to name and staff.

---

## 5. Criterion-by-criterion comparison

Notation: **VERIFIED** facts cite § 12. Scores follow § 3.

### C1 — Data residency

| Candidate | Regions offered (VERIFIED) | African region? | Score | Notes |
|---|---|---|---|---|
| Hetzner Cloud | Falkenstein (DE, `fsn1`), Nuremberg (DE, `nbg1`), Helsinki (FI, `hel1`), Ashburn VA (US, `ash`), Hillsboro OR (US, `hil`), Singapore (SG, `sin`) | **No** | **F** | Location list and location IDs VERIFIED (`docs.hetzner.com/cloud/general/locations`). The page also carries a note on data protection at the Singapore location, which makes Singapore the location with the most questions to ask. |
| DigitalOcean | Droplet datacentres: San Francisco, Richmond, New York, Kansas City, Atlanta, Toronto, Amsterdam, London, Frankfurt, Bangalore, Singapore, Sydney. Managed-PostgreSQL availability table lists `NYC1–3`, `AMS3`, `SFO2/3`, `SGP1`, `LON1`, `FRA1`, `TOR1`, `BLR1`, `SYD1`, `ATL1`, `RIC1`, `MKC1`, `MEM1` | **No** | **F** | Both lists VERIFIED. Managed-PostgreSQL is not available in every Droplet region — the availability table marks some region/plan combinations as restricted. |
| Railway | US West (California, `us-west2`), US East (Virginia, `us-east4-eqdc4a`), EU West (Amsterdam, `europe-west4-drams3a`), Southeast Asia (Singapore, `asia-southeast1-eqsg3a`) | **No** | **F** | Region table VERIFIED. |

**Common fact, stated once:** **none of the three candidates offers a data centre in Africa.** Any Kenyan
data-residency expectation must therefore be met by choosing the geographically closest region (EU or
South Africa — the latter is not offered by these three) and by a written position on cross-border
transfer, or by a fourth candidate outside this comparison.

**This criterion is scored F, not a number, because the acceptable answer is a legal and commercial
position, not a technical one.** The research record carries this as D-05 (*"Deployment target and data
residency — Hosting region, operator, and whether reports are stored in Kenya. Affects the DPA position
and the backup story."*, `docs/research/M4_SCOPE_PROPOSAL.md` § 7). **This document does not state a
position on it.** The founder and the legal reviewer must.

**FOUNDER INPUT (F-1):** may incident data be stored outside Kenya for a supervised pilot? If yes, which
region group? If no, the candidate set must be reopened, because none of these three qualifies on its own.

### C2 — Managed PostgreSQL availability and version

| Candidate | PostgreSQL model | Version offered | Score |
|---|---|---|---|
| Hetzner Cloud | **None.** No managed PostgreSQL product appears in the Hetzner Cloud catalogue (Cloud / Storage / Managed product lines reviewed 21 Oct 2026). PostgreSQL is installed by the operator on a cloud server; the version is whatever the operator's package source provides. | **UNVERIFIED** (operator-chosen; `apps/backend` currently runs PostgreSQL 18 locally per `docs/CHECKLIST.md` § 4) | **2** — the provider does not offer the service, so the pilot must build and operate the database itself. Self-managing is a legitimate answer to the *requirement*; it is simply not an answer to *this criterion*, and the score records that difference in who carries the risk |
| DigitalOcean | **Managed Databases for PostgreSQL** — "Fully managed resources running popular database engines", with Standard and Advanced editions, node types (Basic, General Purpose, Storage Optimized), and additional nodes. Pricing blurb states "Free daily backups, automated failover, and more". | **UNVERIFIED** — the major versions offered for managed clusters were not retrievable from the public pages consulted on 21 Oct 2026. The product documentation index (`docs.digitalocean.com/llms.txt`) lists PostgreSQL features/pricing/availability/limits pages, but the version matrix was not published on the pages retrieved. A product SLA for Managed Databases is published at `digitalocean.com/sla/databases`. | **4** — managed service exists with backups and failover; the version remains open |
| Railway | **Railway PostgreSQL** — a single node that "Railway maintains", convertible to a **provider-managed high-availability cluster** (Patroni, etcd, HAProxy) with automatic failover, with native **backups** (daily kept 6 days / weekly 27 days / monthly 89 days) and **point-in-time recovery**, plus optional PgBouncer pooling and in-place major-version upgrades with a preflight check and one-click revert. | **UNVERIFIED** — the template is built on the official `postgres` Docker image; the major version shipped by the template was not stated on the page consulted. | **4** — managed single node and managed HA are both available; version remains open |

**Version constraint (applies to all three):** whatever is chosen must be a version M.4 has actually been
verified against after T-05 and T-31. Until then, no candidate satisfies acceptance criterion 3 of T-03.

### C3 — Encrypted backups and an off-host copy

OR-2.1 requires an encrypted archive off the host; the design's topology shows a nightly encrypted
`pg_dump -Fc` copied to off-host storage.

| Candidate | Provider-side backup | Off-host copy | Encryption control | Score |
|---|---|---|---|---|
| Hetzner Cloud | **Backups and Snapshots** are copies of the server's disk (VERIFIED). **Backups** are created automatically daily, with **seven slots** per server; the oldest is deleted when a new one is taken, and **all backups are deleted when the server is deleted** — a backup is not a substitute for an off-host copy. **Snapshots** (up to 30 across a project) are manual, are never deleted automatically, and can be protected from deletion. Neither is location-bound. **UNVERIFIED**: the price of automatic backups — the provider's documentation directs readers to the price box on `hetzner.com/cloud`, which was not captured on 21 Oct 2026. | **Storage Box** — off-host backup storage priced per plan: BX11 **€3.20/mo** (1 TB), BX21 **€10.90/mo** (5 TB), BX31 **€20.80/mo** (10 TB), BX41 **€40.60/mo** (20 TB), all excl. VAT. The object-storage line ("Object Storage, S3-compatible") also exists — pricing not captured. | Operator-side: `pg_dump -Fc` piped through encryption, uploaded to the Storage Box (the T-26 backup script template, `apps/backend/deploy/backup-postgres.sh.example`, is written for exactly this shape). | **3** — the off-host half is a first-class, cheap product; the encryption and the copy are the operator's job, and server-side backup pricing is still unverified |
| DigitalOcean | **Backups**: percentage-based — **20% (weekly)** or **30% (daily)** of Droplet cost per month; usage-based from **$0.01/GiB/month**, retention 3 days–6 months. **Snapshots $0.06/GB/month**. Managed Databases include **free daily backups**. | **Spaces** (S3-compatible object storage) from **$5/month**; Volumes from $10/month. | Operator-side encryption of `pg_dump -Fc` in the backup script, as in T-26. | **4** — both halves exist as priced products; managed-DB backups are included |
| Railway | Volume **backups** with daily/weekly/monthly schedules (daily kept 6 days, weekly 27 days, monthly 89 days) and **point-in-time recovery**; storage is a volume attached to the service. | **Object storage $0.015/GB-month, free egress**; service **egress $0.05/GB**. | Operator-side: `pg_dump -Fc` uploaded to object storage, as in T-26 — but a `pg_dump` cannot be produced by the T-26 systemd service unit as written, because Railway has no systemd (see § 6). | **2** — backup mechanisms exist, but the off-host copy path and the M.4 backup template both need redesign for the platform |

**Note on the backup-retention period:** how long archives are kept is **D-B (founder + legal)** and is
still undecided; `docs/RETENTION.md` records it as undecided. No candidate's default retention is
presented here as the policy.

### C4 — TLS and reverse-proxy control

M.4 requires TLS termination with HSTS, a bodyless access log, an **overwriting** `X-Forwarded-For`, and
security headers (SR-6.1, SR-7.1, SR-9.1, SR-9.2). `design.md` § 9.1 puts the reverse proxy
(nginx/Caddy) in front of uvicorn on `127.0.0.1:8000`.

| Candidate | TLS | Reverse-proxy control | Score |
|---|---|---|---|
| Hetzner Cloud | Operator's own nginx/Caddy on the host (T-26 template). | **Full** — the operator owns the proxy configuration, the cipher set, the `log_format`, and the header directives. This is exactly the control surface the T-26 templates assume. | **5** |
| DigitalOcean | Operator's own nginx/Caddy on a Droplet (T-26 template). Optional managed Load Balancer from **$12/month** (Let's Encrypt and HTTP/3 support), but a load balancer does not replace the reverse-proxy configuration the requirements demand. | **Full** — same as above, on a Droplet. | **5** |
| Railway | **Automatic SSL** certificates, provisioned and renewed automatically; Railway-provided `*.railway.app` domains and custom domains; traffic is routed through Railway's edge network. | **Partial and different in kind**: TLS is provider-managed, but the *header and logging* controls the requirements specify (HSTS, CSP, `X-Forwarded-For` overwrite, bodyless log format) are edge configuration, not a config file the operator edits, and the specific directives in the T-26 nginx template do not apply. The rate-limit client identity assumption (SR-7.1/SR-7.2) must be re-established by measurement on the platform, not by reading a proxy config. | **2** |

### C5 — Inbound firewall / port-exposure control

The database must not be reachable from the internet (`apps/backend/DATABASE.md`: "Listen on
localhost/socket only; do not expose port 5432").

| Candidate | Control | Score |
|---|---|---|
| Hetzner Cloud | **Stateful cloud firewalls** — the provider states these "enable easy infrastructure security **without additional costs**", with rules applied to unwanted incoming and outgoing traffic, assignable to many servers. Plus the host's own `ufw`/`nftables`, and the ability to run PostgreSQL on a unix socket or `127.0.0.1`. | **5** |
| DigitalOcean | **Cloud firewalls** — "Restrict traffic with network-based, stateful firewalls for Droplets"; the platform lists free cloud firewalls. **VPC** — free, with free private networking and free intra/inter-datacentre transfer; a **Private Droplet** can be created with no public IP at all. | **5** |
| Railway | Services are private by default; a database is exposed publicly only by explicitly enabling **Public Access**, which creates a **TCP Proxy** (billed at network-egress rates). Railway also offers an **edge WAF** with an on-demand "Under Attack Mode" that browser-checks visitors and stops DDoS and bot floods (VERIFIED) — but that is application-layer flood defence at the edge, **not** a stateful firewall with user-defined source/port rules. Exposure control is therefore "expose this service or do not, and let the edge absorb floods" rather than "allow port X from address Y". | **3** |

### C6 — Cost ceiling

Scored **F**: the ceiling is a founder input, and the pilot's size is **D-K (founder)**, also open.
The measured figures below are the evidence for that decision, not a recommendation. See § 7 for the
pricing evidence and the worked estimates.

### C7 — SSH / console access and audit log

OR-7.1 needs an operator who can take a backup, restore, rotate the admin key and investigate.

| Candidate | Host access | Audit trail | Score |
|---|---|---|---|
| Hetzner Cloud | **Root SSH**, provider console, and a full REST API + CLI. The operator owns the host, so every task in the T-27 runbook is directly performable. | **UNVERIFIED** — no account-level audit log for cloud actions was found in the public product material consulted. The operator can rely on host logs and on their own records, but the provider-side action log is not established. | **4** |
| DigitalOcean | **Root SSH**, provider console, API. A Droplet with no public IP is available (Private Droplet) for a database-only host. | **UNVERIFIED** — the public documentation index for DigitalOcean (`docs.digitalocean.com/llms.txt`, 629 entries, consulted 21 Oct 2026) contains **no audit-log page**, so an account-level provider action log is not established for the pilot tier. | **4** |
| Railway | **No host shell in the root/VM sense.** The platform is container-based: access is a shell into the service container via the CLI/dashboard, and configuration through the platform API. There is no systemd, no `ufw`, no `/etc/ssh`, and no nginx configuration owned by the operator. Many T-27 runbook tasks (rotate a key on the host, read the proxy log, patch the OS) have **no equivalent** as written. | **Workspace audit logs** — VERIFIED: a record of actions in the workspace (projects, services, deployments, variables, workspace settings), visible to workspace admins and exportable through the GraphQL API. **Retention by plan: Free/Trial/Hobby 48 hours; Pro 30 days; Enterprise 18 months.** Service log history: 3 days (Free), 7 days (Hobby), 30 days (Pro). | **2** |

### C8 — Incident-response and data-export support

| Candidate | Data export | Incident response | Score |
|---|---|---|---|
| Hetzner Cloud | Complete operator control: `pg_dump` from a host the operator owns, to storage the operator owns. Data deletion is an operator action on a machine they control. | The provider publishes a 99.9% uptime SLA for Cloud and 24/7 email support, and states its own data centres are ISO/IEC 27001 certified (DE and FI). The operator remains responsible for the application-level incident response the runbook describes. | **5** |
| DigitalOcean | `pg_dump` from the Droplet; managed-database export is available through the provider's tooling and credentials. **UNVERIFIED**: the exact export procedure and any provider-side fee or delay were not established from the pages consulted. | Public status page, and the platform publishes a **Managed Databases SLA** (`digitalocean.com/sla/databases`) — content not read in this task. 24/7 support and support plans from $0. | **4** |
| Railway | Export by running `pg_dump` against the database from the operator's own machine (`railway connect` / `DATABASE_URL` over the TCP Proxy) or from a service container; the operator can copy the archive to object storage at $0.015/GB-month with free egress. Deletion on cancellation follows the provider's process — **UNVERIFIED**. | The provider publishes a status page, incident retrospectives and a published incident-severity scheme, with SLOs and contractual remedies reserved for Enterprise plans. | **4** |

### 5.1 Score summary

| Criterion | Weight (proposed) | Hetzner Cloud | DigitalOcean | Railway |
|---|---|---|---|---|
| C1 Data residency | 15 | F | F | F |
| C2 Managed PostgreSQL availability and version | 15 | 2 | 4 | 4 |
| C3 Encrypted backups + off-host copy | 15 | 3 | 4 | 2 |
| C4 TLS and reverse-proxy control | 15 | 5 | 5 | 2 |
| C5 Inbound firewall / port-exposure control | 10 | 5 | 5 | 3 |
| C6 Cost ceiling | 10 | F | F | F |
| C7 SSH / console access and audit log | 10 | 4 | 4 | 2 |
| C8 Incident-response and data-export support | 10 | 5 | 4 | 4 |
| **Weighted total** | 100 | *not computed* | *not computed* | *not computed* |

**No total is published, and none should be published yet.** Two criteria are unscored (F), C2 carries an
unresolved version constraint for every candidate, and the weights themselves are unconfirmed. A total
computed from that state would be a false precision, and it would edge into the provider selection this
document is required not to make. § 10 is the worksheet for computing it once the inputs exist.

---

## 6. Operational responsibilities

The largest differences between these candidates are not in the price list; they are in **who is
responsible for the parts of the system that M.4's requirements assume exist**. `design.md` § 9.1 fixes
the target topology: a reverse proxy terminating TLS, **one** Uvicorn worker trusting only `127.0.0.1`, a
PostgreSQL bound to localhost or a socket, and a systemd service unit. T-25 and T-26 write templates
for exactly that shape.

| Operational duty | Hetzner Cloud | DigitalOcean | Railway |
|---|---|---|---|
| OS patching and hardening | **Operator** | **Operator** | **Provider** (container image; operator patches the image) |
| PostgreSQL engine patching / major upgrades | **Operator** | **Provider** (managed edition) | **Provider** (managed single node / HA cluster), **operator** if the image is customised |
| TLS certificates | **Operator** (T-26 nginx template) | **Operator** (T-26 nginx template) | **Provider** (automatic SSL, renewal) |
| Reverse-proxy header configuration (HSTS, CSP, `X-Forwarded-For` overwrite, bodyless log) | **Operator**, full control | **Operator**, full control | **Provider-managed edge**; the T-26 nginx template does not apply — the equivalent controls must be re-established and evidenced differently |
| Single-worker rule (SR-11.2) | Enforced in the service unit the operator writes | Enforced in the service unit the operator writes | Platform-level replica control instead; the "one worker" rule becomes a platform configuration the operator must express differently |
| Retention job schedule (T-25, systemd timer or cron) | **Native** — cron or a systemd timer on the host, exactly as T-25 specifies | **Native** — cron or a systemd timer on the Droplet | **Different mechanism** — Railway provides cron jobs as a platform feature; the T-25 systemd-timer template and its summary-file conventions need a Railway-shaped replacement |
| Backup script (T-26 `backup-postgres.sh.example`) | **Applies as written** (`pg_dump -Fc` → encryption → off-host upload) | **Applies as written** | **Needs rework** — the script assumes shell access to a host with a local PostgreSQL client and a `pg_dump`; on Railway the dump must be produced differently (from a service container or from the operator's machine over the TCP Proxy) |
| One-off administration (rotate the admin key, read proxy logs, inspect the disk) | **Operator**, directly | **Operator**, directly | **Operator**, via the platform API/CLI and container shell only |
| Backup restore drill (OR-2.2, T-31) | Operator-run, on a host the operator controls | Operator-run; the managed-database restore path is a provider procedure and needs confirming | Operator-run, but restore semantics differ between the volume backup and a logical `pg_dump` |
| Monitoring `/health/ready` and alerting (OR-3.1) | Operator tooling (e.g. on-host agent) | DigitalOcean **Uptime** — 1 check/month included, one free check per account, alerts by email or Slack | Platform monitoring; alerting configuration is platform-native |
| Provider acceptable-use policy | Must be reviewed before the pilot | Must be reviewed before the pilot | Must be reviewed before the pilot — Railway publishes a trust-and-safety policy describing what content it permits on the platform (**UNVERIFIED** for a safety-reporting workload) |

**Reading.** The first two columns (Hetzner, DigitalOcean) are compatible with the M.4 deployment
baseline in `design.md` § 9.1 and with the T-25/T-26 templates as written. The third column is not:
choosing Railway would require T-25 and T-26 to be re-specified before anything is deployed, and would
change the evidence that SR-6.1, SR-7.1, SR-7.2, SR-9.1 and SR-9.2 rest on. **That is a cost of that
shape of deployment, not a judgement about that provider.**

---

## 7. Pricing evidence and assumptions

### 7.1 Evidence table

All figures below are as published on the date checked (21 October 2026), from the sources in § 12.

| Provider | Item | Price as published | Currency | Tax | Date checked | Source |
|---|---|---|---|---|---|---|
| Hetzner | Cloud server CPX02 — 1 vCPU (AMD), 1 GB RAM, 20 GB NVMe | €6.49 / month (€0.0104 / hour) | EUR | excl. VAT | 2026-10-21 | S1 |
| Hetzner | CPX12 — 1 vCPU, 2 GB, 40 GB | €11.99 / month (€0.0192 / hour) | EUR | excl. VAT | 2026-10-21 | S1 |
| Hetzner | CPX22 — 2 vCPU, 4 GB, 80 GB | €19.99 / month (€0.0320 / hour) | EUR | excl. VAT | 2026-10-21 | S1 |
| Hetzner | CPX32 — 4 vCPU, 8 GB, 160 GB | €35.99 / month (€0.0577 / hour) | EUR | excl. VAT | 2026-10-21 | S1 |
| Hetzner | CPX42 — 8 vCPU, 16 GB, 320 GB | €69.99 / month (€0.1122 / hour) | EUR | excl. VAT | 2026-10-21 | S1 |
| Hetzner | CPX52 — 12 vCPU, 24 GB, 480 GB | €100.99 / month (€0.1618 / hour) | EUR | excl. VAT | 2026-10-21 | S1 |
| Hetzner | CPX62 — 16 vCPU, 32 GB, 640 GB | €130.49 / month (€0.2091 / hour) | EUR | excl. VAT | 2026-10-21 | S1 |
| Hetzner | Singapore (ap-southeast / `SIN1`) price for the same plans | CPX02 €7.99, CPX12 €15.99, CPX22 €26.99, CPX32 €49.49, CPX42 €93.99, CPX52 €134.99, CPX62 €172.49 | EUR | excl. VAT | 2026-10-21 | S1 |
| Hetzner | US-West (`HIL1` / `ASH1`) — the matrix lists a **different plan set** for the US | CPX11 €17.99 (2 vCPU / 2 GB / 40 GB), CPX21 €32.49 (3 vCPU / 4 GB / 80 GB), CPX31 €62.99 (4 vCPU / 8 GB / 160 GB), CPX41 €120.99 (8 vCPU / 16 GB / 240 GB), CPX51 €238.49 (16 vCPU / 32 GB / 360 GB) | EUR | excl. VAT | 2026-10-21 | S1 |
| Hetzner | Cloud server traffic | EU ≥ 20 TB included; US ≥ 1 TB included; AP ≥ 0.5 TB included. Additional TB are billed **per TB per hour**: €1.00 (EU-Central and US), €7.40 (AP) | EUR | excl. VAT | 2026-10-21 | S1 |
| Hetzner | Storage Box BX11 / BX21 / BX31 / BX41 (1 / 5 / 10 / 20 TB) | €3.20 / €10.90 / €20.80 / €40.60 per month | EUR | excl. VAT | 2026-10-21 | S2 |
| Hetzner | Primary IPv4 address | **€0.50 / $0.60 per month** (€0.0008 / $0.0010 per hour), one primary IPv4 and one primary IPv6 per server | EUR | excl. VAT | 2026-10-21 | S14 |
| Hetzner | Cloud server automatic backups | **UNVERIFIED** — the provider's documentation points to the price box on `hetzner.com/cloud`, which was not captured on 2026-10-21. Semantics VERIFIED: automatic daily disk copies, 7 slots per server, oldest deleted automatically, all backups deleted when the server is deleted (S15) | EUR | excl. VAT | 2026-10-21 | S15 |
| DigitalOcean | Droplet Basic 512 MiB / 1 vCPU / 10 GB | $4.00 / month | USD | — | 2026-10-21 | S3 |
| DigitalOcean | Droplet Basic 1 GiB / 1 vCPU / 25 GB | $6.00 / month | USD | — | 2026-10-21 | S3 |
| DigitalOcean | Droplet Basic 2 GiB / 1 vCPU / 50 GB | $12.00 / month | USD | — | 2026-10-21 | S3 |
| DigitalOcean | Droplet Basic 2 GiB / 2 vCPU / 60 GB | $18.00 / month | USD | — | 2026-10-21 | S3 |
| DigitalOcean | Droplet Basic 4 GiB / 2 vCPU / 80 GB | $24.00 / month | USD | — | 2026-10-21 | S3 |
| DigitalOcean | Droplet Basic 8 GiB / 4 vCPU / 160 GB | $48.00 / month | USD | — | 2026-10-21 | S3 |
| DigitalOcean | Droplet Basic 16 GiB / 8 vCPU / 320 GB | $96.00 / month | USD | — | 2026-10-21 | S3 |
| DigitalOcean | Droplet billing | per-second billing effective 1 January 2026, minimum charge 60 s or $0.01; bundled plans have a monthly cap | USD | — | 2026-10-21 | S3 |
| DigitalOcean | Managed PostgreSQL, Standard, Basic node, 1 GiB / 1 vCPU, storage 10–30 GiB | $15.15 / month ($0.02254 / hour); storage $0.215 / GiB / month in 10 GiB increments | USD | — | 2026-10-21 | S4 |
| DigitalOcean | Managed PostgreSQL, Standard, Basic node, 2 GiB / 1 vCPU | $30.45 / month ($0.04531 / hour) | USD | — | 2026-10-21 | S4 |
| DigitalOcean | Managed PostgreSQL, Standard, Basic node, 4 GiB / 2 vCPU | $60.90 / month ($0.09063 / hour) | USD | — | 2026-10-21 | S4 |
| DigitalOcean | Managed PostgreSQL, Standard, Basic node, 8 GiB / 4 vCPU | $122.10 / month ($0.18170 / hour) | USD | — | 2026-10-21 | S4 |
| DigitalOcean | Managed PostgreSQL, Standard, Basic node, 16 GiB / 6 vCPU | $244.35 / month ($0.36362 / hour) | USD | — | 2026-10-21 | S4 |
| DigitalOcean | Droplet Backups | 20% of Droplet cost (weekly) or 30% (daily) per month; usage-based from $0.01 / GiB / month, retention 3 days–6 months | USD | — | 2026-10-21 | S3 |
| DigitalOcean | Droplet Snapshots | $0.06 / GB / month | USD | — | 2026-10-21 | S3 |
| DigitalOcean | Spaces object storage | from $5 / month | USD | — | 2026-10-21 | S5 |
| DigitalOcean | Cloud firewalls; VPC | free (VPC $0, free cloud firewalls) | USD | — | 2026-10-21 | S5 |
| DigitalOcean | Outbound transfer | included from 500 GiB / month; overage $0.01 / GiB; inter-datacentre VPC transfer $0.01 / GiB | USD | — | 2026-10-21 | S5 |
| DigitalOcean | Load Balancer; Uptime; Support plan | $12 / month; one Uptime check/month included, further checks priced; support from $0 / month | USD | — | 2026-10-21 | S5 |
| Railway | Hobby plan | $5 / month, including $5 / month of usage credit; max 48 vCPU / 48 GB per service, 6 replicas, 7-day log history | USD | — | 2026-10-21 | S6 |
| Railway | Pro plan | $20 / month per workspace, including $20 / month credit; max 1,000 vCPU / 1 TB per service, 42 replicas, 30-day log history | USD | — | 2026-10-21 | S6 |
| Railway | Enterprise plan | custom — SSO, RBAC, extended audit logs, contractual SLAs, support SLOs, HIPAA BAAs | USD | — | 2026-10-21 | S6 |
| Railway | Memory | $0.00000386 / GB-second (≈ $10 / GB / month) | USD | — | 2026-10-21 | S6 |
| Railway | CPU | $0.00000772 / vCPU-second (≈ $20 / vCPU / month) | USD | — | 2026-10-21 | S6 |
| Railway | Volumes | $0.00000006 / GB-second (≈ $0.15 / GB / month) | USD | — | 2026-10-21 | S6 |
| Railway | Egress (services) | $0.05 / GB | USD | — | 2026-10-21 | S6 |
| Railway | Object storage | $0.015 / GB-month, free egress | USD | — | 2026-10-21 | S6 |
| Railway | Audit-log retention | Free / Trial / Hobby 48 hours; Pro 30 days; Enterprise 18 months | — | — | 2026-10-21 | S7 |
| Railway | Workspace audit logs | record of project, service, deployment, variable and workspace-setting actions; visible to workspace admins; exportable via GraphQL API | — | — | 2026-10-21 | S7 |

### 7.2 Cost model

The recurring cost of a pilot host is driven by six things. A cost comparison that quotes only the
compute line is not comparable across these candidates, because the database, the backup store and the
off-host copy are bought differently by each.

| Cost driver | Hetzner Cloud | DigitalOcean | Railway |
|---|---|---|---|
| **Application compute** (API + web build) | Cloud server, €6.49–€35.99 / month (EU) | Droplet, $6–$48 / month | Service usage: CPU ≈ $20 / vCPU-month + memory ≈ $10 / GB-month, metered per second |
| **Database** | **Included in the same cloud server** (self-managed) or a second server from €11.99 / month | Managed cluster, $15.15 / month (1 GiB) to $60.90 / month (4 GiB) | Service usage (CPU + memory) + volume at ≈ $0.15 / GB-month |
| **On-host backup (optional)** | Cloud Backups (price UNVERIFIED) | 20–30% of Droplet cost | Volume backups (daily/weekly/monthly schedules) + point-in-time recovery (pricing not published in the pages consulted) |
| **Off-host backup store** | Storage Box, €3.20 / month (1 TB) | Spaces, from $5 / month | Object storage, $0.015 / GB-month, free egress |
| **Public IPv4 address** (if the host is not behind a provider-managed edge) | €0.50 / month | included with the Droplet's public IP | not applicable — TLS terminates at the platform edge |
| **Egress** | ≥ 20 TB included in EU; extra €1.00 / TB | ≥ 500 GiB included; $0.01 / GiB over | $0.05 / GB (no included allowance published on the pricing page) |
| **Plan fee** | none | none | $5 / month (Hobby) or $20 / month (Pro) |

**Not in the cost model — because it cannot be priced honestly here:** the operator's time. A
self-managed PostgreSQL on Hetzner, a managed PostgreSQL on DigitalOcean and a containerised PostgreSQL
on Railway consume different amounts of operator attention per month. The pilot's operator cost is
**FOUNDER INPUT**.

### 7.3 Reference pilot profile and worked estimates

**ASSUMPTION (profile).** Because D-K (pilot scope, participants, start date, operator) is undecided, the
figures below use one stated reference profile so the candidates can be compared at all. **This profile
is an assumption, not a decision, and the estimates must be recomputed against the profile the founder
actually approves.**

> Reference profile: one always-on API instance; one PostgreSQL instance sized for a small supervised
> pilot; ≤ 200 reports per day; ≤ 20 KB per report; ≤ 1 GB of egress per month; one encrypted
> off-host backup per day, retained for 30 days; a static web build served by the same host or by the
> provider's static hosting.

| Line | Hetzner Cloud (EU) | DigitalOcean | Railway (Pro) |
|---|---|---|---|
| Application compute | CPX22, 2 vCPU / 4 GB / 80 GB — **€19.99** | Droplet Basic 2 GiB / 1 vCPU — **$12.00** | 1 vCPU + 2 GB — **≈ $40.00** (CPU $20 + memory $20) |
| Database | same host (self-managed) — **€0.00** incremental | Managed PostgreSQL Basic 1 GiB — **$15.15** (2 GiB: $30.45) | 1 vCPU + 2 GB + 10 GB volume — **≈ $41.50** |
| Off-host backup store | Storage Box BX11 (1 TB) — **€3.20** | Spaces — **$5.00** | Object storage, 1 GB — **≈ $0.02** |
| On-host backup | **UNVERIFIED** (optional) | Droplet Backups, daily 30% of $12 — **$3.60** (weekly 20%: $2.40) | included in the plan's usage credit; PITR price not published |
| Public IPv4 address | **€0.50** | included | not applicable (edge-terminated TLS) |
| Plan fee | none | none | **$20.00** (Pro) |
| Egress (1 GB) | included (20 TB EU) | included (500 GiB) | **≈ $0.05** |
| **Indicative total / month** | **≈ €23.69** (excl. VAT, excl. server-backup price, excl. operator labour) | **≈ $35.75** | **≈ $101.57** |

**Read these totals as arithmetic, not as a ranking.** They are not comparable without a currency
conversion rate and a decision on VAT/tax treatment, both of which are **FOUNDER INPUT**. They exclude
the operator's time, the domain, TLS/e-mail and monitoring tooling, and the Hetzner server-backup price
(UNVERIFIED). Railway's figure assumes Pro, because Hobby's 48-hour audit-log retention is too short to
serve as an operational record for a pilot.

---

## 8. Security and privacy risks, per candidate

These are the risks that attach to the *shape* of each option, independent of price. They are recorded
here so the founder decides with them in view.

### 8.1 Hetzner Cloud — self-managed database

- **The database engine is the operator's responsibility.** A missed PostgreSQL security patch, a
  `wal_level` mistake, or an over-permissive `pg_hba.conf` is a pilot incident with no provider
  backstop. There is no second pair of eyes unless the operator has one.
- **Backups are only as good as the off-host copy.** The encrypted `pg_dump -Fc` and the Storage Box
  upload are the operator's script; if the copy silently fails, the operator may believe the pilot is
  recoverable when it is not. The T-26 backup script and the T-31 restore drill exist precisely for this.
  The provider's own server-side backups do not close this gap: they are copies of the same disk, they
  are deleted when the server is deleted, and they are not location-bound — an off-host copy is still
  required (VERIFIED, S15).
- **One operator, one host.** A single VM hosting both the API and the database is a single failure
  domain; the pilot can be made available again by restoring, but the recovery path is the operator's.
- **Privacy:** the operator can enforce "PostgreSQL listens on localhost only" because the operator owns
  the host. Nothing in the provider's product forces it — it is a configuration the operator must not get
  wrong.

### 8.2 DigitalOcean — managed database

- **The connection path changes.** A managed database is normally reached over a private VPC network
  rather than over localhost, which affects the `DATABASE_URL` in `apps/backend/.env.example`, the
  least-privilege role setup in `apps/backend/DATABASE.md`, and the "not exposed" assumption in
  `design.md` § 9.1. The design's topology will need an explicit note rather than an assumption.
- **The engine is managed but the data is not.** Backups, patching and failover are the provider's;
  schema, migrations, the retention job, roles, and the restore drill stay with the operator. The
  retention tool (T-24) must be able to connect and delete in batches — this needs confirming against
  the managed service's connection and privilege model.
- **Privacy:** the provider can read the data by design. That is true of every managed service, but it
  is a fact that must be stated plainly in the pilot's disclosure material rather than left implicit.
- **Egress and the TCP path:** the managed database is reachable from the Droplet over the VPC; the
  firewall rules must reflect that rather than "block everything".

### 8.3 Railway — container platform

- **The requirements' control surface is different.** SR-6.1, SR-7.1, SR-7.2, SR-9.1 and SR-9.2 assume
  an operator-owned proxy with an editable configuration. On a container platform, TLS is automatic and
  the header/logging controls are edge behaviours. The evidence that those requirements hold would have
  to be produced differently (measurement, not configuration review).
- **The rate-limiting assumption needs re-establishment.** SR-7.1/SR-7.2 depend on the proxy
  overwriting `X-Forwarded-For` so that `request.client.host` is the true client. On a platform where
  the edge terminates the connection, the true client address must be *measured* before the per-process
  rate limiter can be trusted — and if it cannot be trusted, SR-7.3 ("documented as unsupported")
  applies.
- **Flood defence is platform-provided, not operator-configured.** The edge WAF's "Under Attack Mode"
  is an on-demand browser check for DDoS and bot floods (VERIFIED, S16). It is not a substitute for a
  user-defined inbound firewall, and there is no equivalent of a rule set that allows port X from
  address Y.
- **Audit-log retention is short on cheap plans.** 48 hours on Hobby is not an operational record;
  Pro (30 days) or Enterprise (18 months) are materially different products, with Enterprise being
  custom-priced — a cost-ceiling input.
- **Data export and deletion on cancellation are the operator's problem** unless the provider's process
  is confirmed. For a service whose subject matter is incident reports, the ability to export on
  request and to prove deletion is a privacy requirement, not a convenience.
- **Container model:** the "one Uvicorn worker" rule (SR-11.2) and the "single worker" runbook note
  become platform replica settings. Replica count is a platform control with a plan limit (Hobby 6,
  Pro 42), so a misconfiguration is one click away from violating SR-11.2 — and the rate limiter is
  per-process, so replicas multiply the buckets.
- **Privacy:** the platform's acceptable-use policy and the fact that services run in shared
  infrastructure are facts the pilot's disclosure material would have to reflect.

### 8.4 Risks common to all three

- **No African region** (§ C1). The residency question is a founder-and-legal decision and is not
  settled here.
- **Provider staff can access the data** in every case, managed or not. The pilot's disclosure
  material must not overstate isolation.
- **The admin key is a single shared secret** (SR-1.3, D-J) regardless of provider, and is the largest
  single compromise path in the design.
- **The retention tool stays inert** until D-A is decided. No provider choice changes that: the tool
  ships without a period and deletes nothing until `SAFESIGNAL_REPORT_RETENTION_DAYS` is set by an
  approved decision.

---

## 9. Unverified claims register

Everything in this document that a reader might otherwise take as fact but that this task did not
establish. **None of these may be treated as satisfied, and none may be reported as verified in
`docs/PILOT_READINESS.md` (T-33) until they are checked.**

| # | Unverified item | Candidate(s) | Where to check |
|---|---|---|---|
| U-1 | PostgreSQL major version offered | DigitalOcean, Railway | Provider documentation / console at provisioning time; then verify M.4's test suite against it (T-05, T-31) |
| U-2 | PostgreSQL version and packaging of a self-managed install | Hetzner | The chosen Debian/Ubuntu package source; then T-05/T-31 against it |
| U-3 | Price of automatic cloud-server backups | Hetzner | The price box on `hetzner.com/cloud` (the provider's own documentation points there) |
| U-4 | ~~Price of a primary IPv4 address~~ — **RESOLVED 21 Oct 2026**: **€0.50 / $0.60 per month**, excl. VAT (S14). No longer unverified. | Hetzner | — |
| U-5 | ~~Singapore (AP) server prices~~ — **RESOLVED 21 Oct 2026**: CPX02 €7.99 … CPX62 €172.49 (see § 7.1; the Singapore matrix was read directly from the price page). The **US-West** matrix publishes a different plan set (CPX11/CPX21/CPX31/CPX41/CPX51), which is now recorded in § 7.1. | Hetzner | — |
| U-6 | Provider-side account action audit log | Hetzner, DigitalOcean | Provider documentation / sales enquiry |
| U-7 | Managed-database export procedure, cost and latency | DigitalOcean | Provider documentation / support |
| U-8 | Managed Databases SLA terms | DigitalOcean | `digitalocean.com/sla/databases` (cited, not read in this task) |
| U-9 | Pricing of Railway volume backups and point-in-time recovery | Railway | Railway pricing / console |
| U-10 | Railway data-deletion and export-on-cancellation process | Railway | Railway documentation / support |
| U-11 | Railway acceptable-use policy as applied to a safety-reporting service | Railway | Railway trust-and-safety policy |
| U-12 | Whether a managed PostgreSQL can run `apps/backend/migrations/001_init.sql` and the retention tool unchanged | DigitalOcean, Railway | The T-05 CI run against the target version, plus a staging rehearsal of `retention.py --dry-run` |
| U-13 | Whether the managed service permits the least-privilege role split in `apps/backend/DATABASE.md` (owner / `safesignal_app`) | DigitalOcean, Railway | Staging rehearsal of `migrate.py` with `DATABASE_MIGRATE_URL` |
| U-14 | Currency conversion, VAT treatment and any withholding for the operator's jurisdiction | All | Founder and accountant; the totals in § 7.3 are not comparable without it |
| U-15 | The pilot's actual size, and therefore the true cost | All | D-K (founder) — the reference profile in § 7.3 is an assumption |

---

## 10. Founder decision record (D-E) — **PARTIALLY DECIDED**

> **Status: D-E — the application host and the database provider are DECIDED (recorded by the
> founder on 21 October 2026). The deployment inputs that make the decision operable remain OPEN.**
> The comparison in § 2–§ 9 is unchanged and was not the basis of the choice. Nothing in the M.4 work
> provisioned, configured, connected to or changed any infrastructure: no server was reached, no
> database was contacted, no DNS or firewall rule was touched, and no production deployment is
> authorised.

### The recorded decision (founder, 21 October 2026)

Each row below is a **statement by the founder**, recorded here as given. M.4 has not verified any of
them, because verifying them would mean accessing the infrastructure, which is out of scope.

| Item | Recorded | State |
|---|---|---|
| Application host | **Contabo Cloud VPS 4** — purchased | Recorded by the founder; not independently verified |
| Domain | **zindika.app**, connected to the VPS | Recorded by the founder; not independently verified |
| Host firewall | Configured | Recorded by the founder. **The rules have not been independently audited** |
| Database provider | **Neon PostgreSQL** (managed) | Recorded by the founder; not independently verified |
| Neon project | **`agent-gate`**, **Frankfurt** region | Recorded by the founder; not independently verified |
| SafeSignal's intended use of that existing project | **Not yet confirmed** | **OPEN** — the founder has not confirmed what SafeSignal's use of `agent-gate` is |
| VPS region | — | **UNVERIFIED** |
| PostgreSQL server version | — | **UNVERIFIED** — the version Neon serves is unknown, so the C2 constraint in § 5 is still open |
| Recovery procedures | — | **UNVERIFIED** — backup, restore and failover have not been tested for this pair, and the backup story depends on D-B |
| Deployment readiness | — | **UNVERIFIED** — nothing has been deployed; T-25, T-26 and T-27 are still to be run against a real server |
| Contabo automatic VPS backups | **Not enabled** | Recorded by the founder — an accepted gap for now, and the reason the off-host copy in § 7.2 matters |

**What this decision does not settle.** It names the host and the database. It does not resolve the
residency position (F-1), the cost ceiling (F-2), the PostgreSQL version (C2), the recovery and
backup story (OR-2.3, which depends on D-B), the named operator (F-6, D-K), or the audit of the
firewall rules. It also does not make the deployment ready: T-25 (retention scheduling),
T-26 (deployment templates) and T-27 (the runbook) have not been run against this pair, and T-31
(physical-device and server verification) has not been performed.

**A note on ordering.** OR-8.2 asks for the provider to be chosen *before* any server is provisioned.
The VPS was purchased before this comparison was completed, so for this decision that ordering could
not be met. It is recorded here as a fact rather than presented as compliance, and it is a reminder
that the criteria in § 2 still have to be satisfied by the chosen pair — the comparison stands as the
list of things to verify, not as a discarded exercise.

### 10.1 Decision inputs still open

**Owner:** founder.
**Needed by:** before T-26's templates are applied to a server, and before T-27's runbook is written
against a real topology.
**Blocks:** OR-8.1, OR-8.2 and all of Group G (T-25, T-26, T-27), and the T-33 readiness checklist.
**Partially discharged on 21 October 2026** by the recorded decision above; the items in § 10.1 below
are what is still outstanding.

| # | Input | Why it is needed | Status |
|---|---|---|---|
| F-1 | Data-residency position: may incident data be stored outside Kenya, and in which region group? | C1; affects the candidate set and the DPA position (D-05 in the research record). The database is now in Frankfurt — whether that is acceptable for incident data is still unanswered | **OPEN** |
| F-2 | Cost ceiling for the pilot, in a stated currency, including tax treatment | C6; makes the § 7.3 estimates comparable | **OPEN** |
| F-3 | Whether a provider-managed PostgreSQL is required, or self-managed is acceptable | C2; changes who carries the engine risk and the whole cost/ops shape | **ANSWERED IN PRACTICE** — a managed PostgreSQL (Neon) is now in use; the formal confirmation and the operating model (backups, failover, roles) are still to be recorded |
| F-4 | Confirmation of the § 2 weights | § 2, § 5.1 | **OPEN** — the decision was not made from the weighted scores, so the weights are still only a proposal |
| F-5 | Whether the T-25/T-26 deployment baseline (systemd + operator-owned reverse proxy) may be re-specified | C4, C6, C7; the Railway column in § 6 assumes it may | **OPEN** — depends on what the VPS actually runs |
| F-6 | Named operator for the pilot host and for the database engine, if self-managed | § 6, § 8.1 | **OPEN** — related to D-K |
| F-7 | Confirmation of the pilot profile that the cost model should be run against | § 7.3 | **OPEN** — related to D-K |

### 10.2 Decision worksheet

| Field | Value |
|---|---|
| Chosen provider and model | **Contabo Cloud VPS 4** (application host) and **Neon PostgreSQL** (managed database) — recorded 21 October 2026 |
| Chosen region(s) | **Neon: Frankfurt (recorded). VPS region: unverified** |
| PostgreSQL model and version | **Managed** (Neon). **Version unverified** — C2 stays open until it is known and T-31 has run |
| Date of decision | 21 October 2026 |
| Decided by (name and role) | The founder |
| Reasons | Not recorded as a scoring outcome. The selection uses infrastructure that already existed: a purchased VPS and an existing Neon project. The rationale for choosing it over the § 4 candidates was **not** recorded and is **OPEN** |
| Cost ceiling applied (F-2) | *— open —* |
| Residency position applied (F-1) | *— open —* (the database region is Frankfurt; whether incident data may sit there is undecided) |
| Weighted total, with the weights from § 2 confirmed (F-4) | *— not computed; the decision was not taken from the § 5.1 scores —* |
| Evidence checked before deciding (U-1 … U-15) | *— not recorded for this decision; the unverified register in § 9 still applies to the chosen pair —* |
| Signature / date | *— not signed —* |

### 10.3 What a decision must not do

- It must not be made from a scoring total alone. Two criteria are unscored and one (C2) is open for
  every candidate.
- It must not be made before the U-1 … U-15 items that bear on the chosen candidate are checked.
- It must not be recorded anywhere other than § 10.2 of this file and the D-E row of the M.4 decision
  tables, so that there is exactly one record of the choice.
- It must not precede T-05 (so that the PostgreSQL version is known) and T-31 (so that the version is
  *verified* against M.4's tests). If the pilot schedule cannot wait for those, that is a scheduling
  decision for the founder, and it must be recorded as an accepted deviation — not left implicit.
- **It must not be read as a verification.** Naming the host and the database verifies nothing: the
  VPS region, the PostgreSQL server version, the recovery story, the firewall rules, the residency
  position and the deployment readiness all remain open, as listed above. The pilot is not ready
  because a provider is named; it is ready when T-25, T-26, T-27 and T-31 have been run against the
  real pair and D-A, D-B, D-C, D-D, D-J and D-K are decided.

---

## 11. Decision triggers and dependencies

### 11.1 What would force the choice to be revisited

| Trigger | Why it matters |
|---|---|
| The residency position (F-1) rules out the chosen region group | C1 fails outright for that candidate |
| The pilot size (D-K) grows beyond the reference profile | Changes the cost model, and possibly the managed-vs-self-managed answer |
| The operator named in F-6 is unavailable | A self-managed database needs a named maintainer; a platform that does not need one becomes materially different |
| T-05 or T-31 shows the candidate's PostgreSQL version is incompatible with `apps/backend/migrations/001_init.sql` or the retention tool | C2 fails for that candidate |
| A cost change moves the candidate outside the ceiling (F-2) | C6 fails |
| A provider changes its firewall, backup, export or log-retention model | Changes the score in § 5.1 and the operational duties in § 6 |
| A security or privacy incident on the pilot host | § 6 of `requirements.md` (OR-7.1) incident-response path |
| The legal review (D-A, D-B, D-C, D-D) imposes a condition on storage location or deletion | C1, C3 and the backup design change |

### 11.2 Dependencies of the decision

```
D-E (hosting provider — FOUNDER) — host and database recorded 21 Oct 2026;
      the operational inputs below are still open
 ├── gates → T-25 (retention scheduling, host-specific)      [T-24 may ship inert regardless]
 ├── gates → T-26 (deployment templates applied to a server)
 │             └── needs T-23 (variable names) first
 ├── gates → T-27 (runbook written against a real topology)
 │             └── needs T-23, T-24, T-25, T-26
 ├── gates → T-33 (pilot-readiness checklist: "the hosting is chosen")
 └── informs → T-31 (device + server verification evidence)

Still open under D-E, now that the pair is named:
  VPS region · PostgreSQL server version (C2) · recovery and backup story (D-B)
  firewall-rule audit · residency position (F-1) · cost ceiling (F-2)
  named operator (F-6, D-K) · intended use of the `agent-gate` Neon project

Independent of D-E (may proceed in parallel):
T-05 PostgreSQL in CI  → T-31 version verification → closes the C2 constraint
D-A / D-B retention + backup periods → gate T-24's activation and T-26's backup script
D-K pilot scope        → sets the profile the cost model runs against
```

---

## 12. Sources

All sources are public provider pages, consulted **21 October 2026**. Prices are as published on that
date; they change without notice and must be re-checked at decision time.

| Ref | Source | Used for |
|---|---|---|
| S1 | `https://www.hetzner.com/cloud/` and `https://www.hetzner.com/cloud/regular-performance/` | Server plan names, vCPU/RAM/disk, EU (`eu-central`), Singapore (`ap-southeast`) and US (`us-west`) prices, traffic allowances, product lines, firewall statement, 99.9% uptime SLA, 24/7 support, locations (DE/FI/US/SG), ISO/IEC 27001 statement for DE and FI data centres |
| S2 | `https://www.hetzner.com/storage/storage-box/` | Storage Box plan names, capacities and prices (off-host backup target) |
| S3 | `https://www.digitalocean.com/pricing/droplets` | Droplet plans and prices, per-second billing, backup and snapshot pricing, included transfer, region list, "unmanaged Droplet" statement, firewall/VPC statements |
| S4 | `https://www.digitalocean.com/pricing/managed-databases` | Managed PostgreSQL node sizes, prices, storage rate, editions |
| S5 | `https://www.digitalocean.com/pricing` and `https://www.digitalocean.com/pricing/databases` | Product price summary: Backups, Spaces, Volumes, VPC, Uptime, Load Balancer, support, egress overage, "free daily backups" for managed databases, free cloud firewalls |
| S6 | `https://railway.com/pricing` | Plan fees, included credits, resource rates, egress and object-storage rates, per-service limits, replica limits, log-history retention, Enterprise features |
| S7 | `https://docs.railway.com/enterprise/audit-logs.md` | Workspace audit-log content and retention by plan; GraphQL export |
| S8 | `https://docs.railway.com/deployments/regions.md` | Railway regions and region identifiers |
| S9 | `https://docs.railway.com/databases/postgresql.md`, `https://docs.railway.com/volumes/backups.md`, `https://docs.railway.com/cron-jobs.md` | Railway PostgreSQL deployment model, support scope, backups and PITR, cron jobs |
| S10 | `https://docs.digitalocean.com/products/databases/postgresql/details/availability/index.html.md` and `https://docs.digitalocean.com/products/databases/postgresql/details/index.html.md` | Managed PostgreSQL regional availability table; product documentation index |
| S11 | `https://docs.hetzner.com/cloud/general/locations` | Hetzner location names and identifiers |
| S12 | `https://docs.digitalocean.com/llms.txt` (629 entries) | Searched for an account audit-log product: **no entry found** (see U-6) |
| S13 | `https://www.hetzner.com/cloud/` product navigation (Cloud / Storage / Managed) | Absence of a managed PostgreSQL product in the Hetzner catalogue (see C2) |
| S14 | `https://docs.hetzner.com/cloud/servers/primary-ips/overview/` | Primary IPv4 price (€0.50 / $0.60 per month, excl. VAT); one primary IPv4 and one primary IPv6 per server |
| S15 | `https://docs.hetzner.com/cloud/servers/backups-snapshots/faq/` and `.../overview/` | Backup and snapshot semantics (daily automatic backups, 7 slots, deleted with the server; snapshots protectable; not location-bound); price box location |
| S16 | `https://docs.railway.com/networking/waf.md` | Railway edge WAF and "Under Attack Mode" |

Repository references used throughout: `design.md` § 9.1–9.4, `requirements.md` § 7 (OR-8), `tasks.md`
(T-03, T-05, T-23 … T-27, T-31, T-33), `docs/RETENTION.md` (D-A … D-D, undecided), `docs/CHECKLIST.md`
§ 4, § 10, `docs/research/M4_SCOPE_PROPOSAL.md` § 7 (D-05),
`apps/backend/DATABASE.md`, `apps/backend/.env.example`, `apps/backend/migrations/001_init.sql`.

---

## 13. Self-check against the T-03 acceptance criteria

| T-03 acceptance criterion | Result |
|---|---|
| Two or more candidates compared against **every** criterion | **Met** — three candidates (§ 4) scored against all eight criteria of `design.md` § 9.4 (§ 5), each with a score, the evidence behind it, and a marker where the criterion could not be scored (F) or could not be verified (U). |
| The chosen provider is named, with the reasons, before any server is provisioned | **Partially met.** The host and the database provider are named and recorded (§ 10) — the founder chose a Contabo Cloud VPS 4 and Neon PostgreSQL on 21 October 2026. The **reasons were not recorded as a scoring outcome**, and the "before any server is provisioned" ordering could not be met because the VPS was already purchased. The operational inputs behind the decision remain open (§ 10.1). |
| The PostgreSQL version offered is one M.4 has been verified against (T-05, T-31) | **NOT YET MET — blocked by T-05 and T-31.** The Neon server version is unverified, so the constraint recorded in § 2.1 and C2 is still open; T-05 has run the suite against PostgreSQL 18, but T-31 has not verified the version actually served. The verification itself belongs to T-31, not to T-03. |

**T-03 content requirements**

| Required content | Where |
|---|---|
| The criteria from design § 9.4 | § 2 (all eight, with why-it-matters and proposed weights) |
| At least two candidates, each scored against the criteria | § 4, § 5 (three candidates × eight criteria) |
| The cost estimate for the pilot's expected load | § 7.2 (cost model), § 7.3 (worked estimates on a stated reference profile, with assumptions and the unverified items listed) |
| The decision, the date, the reasons, and what would trigger a change | § 10 (recorded decision, date, open inputs), § 10.2 (worksheet), § 11.1 (triggers) — the reasons for the choice were not recorded and remain open |
| An explicit statement that the provider was not chosen by the code or by this specification | § 1 (quoted statement) |
| Operational responsibilities | § 6 |
| Security and privacy risks | § 8 |
| Scoring methodology | § 3 |
| Unverified claims | § 9 |
| Decision triggers and dependencies | § 11 |

**Verification status**

- **Automated verification:** none — T-03 is a document, and `tasks.md` states this explicitly. No code
  was changed by this task and no test was added or run against it.
- **Manual verification outstanding:** the founder's reading of the comparison; the reasons for the
  recorded selection; the resolution of the U-1 … U-15 items and the "not yet established" list in
  § 10 that bear on the chosen pair; and the confirmation of the § 2 weights.
