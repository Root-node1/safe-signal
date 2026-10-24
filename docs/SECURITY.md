# Security and privacy

SafeSignal has not been security-audited or penetration-tested. This document describes controls that exist in the code and the work still required. It is not a claim of security.

## Current controls

- **Admin access:** `X-Admin-Key` compared in constant time with `SAFESIGNAL_ADMIN_KEY`. Unset, empty or whitespace key denies everything. All failures return the same 401. Failed attempts are limited per client address (default 5 per 15 minutes).
- **CORS:** browser origins configured via `SAFESIGNAL_CORS_ORIGINS` (comma-separated); defaults to `http://localhost:5173` in development. Methods GET/POST/PATCH; headers `Content-Type`, `X-Admin-Key`, `Idempotency-Key`.
- **Security headers:** `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, `X-XSS-Protection: 0` on all responses; `Strict-Transport-Security` and a restrictive `Content-Security-Policy` are added only when `SAFESIGNAL_ENV=production`.
- **Report rate limiting:** default 10 new reports per hour per client address, enforced atomically with creation.
- **Idempotency:** per-submission random keys; replays cost nothing; conflicting reuse returns 409. Concurrent duplicates cannot create two records (lock in memory mode; unique key plus transaction in PostgreSQL).
- **Input validation:** Pydantic length and enum limits; PostgreSQL CHECK constraints mirror them; all SQL is parameterised.
- **Database:** production connections enforce `sslmode=require`; the connection pool recycles stale connections (`max_lifetime=1800`) for Neon serverless resilience.
- **Assistant:** the OpenRouter key stays on the server; input is length-bounded and redacted (emails, Kenyan phone numbers, plates, coordinates, long digit strings); emergency phrases get fixed text; no raw message logging; no conversation storage; provider errors are returned as a generic code. The configured model is used as is, with no fallback model.
- **Logging:** only error classes and codes; no report content, keys, addresses or connection strings.
- **Secrets:** `.env` files are git-ignored; templates hold placeholders; the mobile app must not embed secrets.
- **Client:** no accounts, no analytics; Quick Exit; phone numbers and GPS are never sent with a report.
- **Android hardening (M.4):** `FLAG_SECURE` is set on the activity window, so screenshots, screen recording and the recent-apps thumbnail cannot capture any screen — including the reference code on the confirmation screen. Use "Copy code" to keep the reference code. Android auto-backup and device-to-device transfer are disabled (`android:allowBackup="false"` with a `data_extraction_rules` file that excludes all app data domains), so a saved pending report is never copied off the device. The release manifest declares only `android.permission.INTERNET` — no location, background, notification or storage permission.

## Privacy considerations
Reports may reveal where and when someone was harmed, vehicle plates, SACCO names and free-text locations. Treat the database and backups as sensitive. The product does not guarantee anonymity or confidentiality, and the interface should not suggest otherwise. `consentToShare` is stored but nothing shares data. No retention or deletion policy is implemented; an operator can delete a report by reference code (see DATABASE.md).

## Storage limits
In-memory mode loses all reports and idempotency keys on restart and is for development only. PostgreSQL mode is verified only against a local PostgreSQL 18 test cluster; backups, restore, roles and network exposure are documented but untested on a server.

## Work still required
- Replace the shared admin key with real authentication, per-user identity and audit logging before any admin UI exists.
- Reverse proxy and TLS: deploy behind nginx with TLS (template at `apps/backend/deploy/nginx.conf.example`); configure trusted forwarded headers (proxy must overwrite `X-Forwarded-For`; Uvicorn must trust only that proxy) or all clients share one rate-limit bucket. The application itself ignores forwarding headers.
- Distributed or persistent rate limiting if more than one worker is used.
- Rate limiting for non-report routes; CAPTCHA or abuse controls are absent.
- Security response headers (HSTS, CSP, X-Content-Type-Options, X-Frame-Options) are implemented in code but only take effect when `SAFESIGNAL_ENV=production`; CORS origin is configurable via `SAFESIGNAL_CORS_ORIGINS` — both must be verified in the deployed reverse proxy layer.
- Dependency and secret scanning in CI; secret rotation for `SAFESIGNAL_ADMIN_KEY`, `DATABASE_URL`, `OPENROUTER_API_KEY`.
- Least-privilege database roles, encrypted off-server backups, restore test, retention policy, deletion procedure.
- Legal review under Kenya's Data Protection Act before collecting real reports.
- Independent security review.

## Reporting a vulnerability
No security contact has been established. Until one is published here, report issues privately to the repository owner through GitHub (for example a private security advisory if enabled) rather than a public issue. Do not include real incident data.
