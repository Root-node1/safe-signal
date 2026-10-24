# SafeSignal database (PostgreSQL)

Storage is selected by `DATABASE_URL`. Unset = in-memory (development/tests only).
`SAFESIGNAL_ENV=production` refuses to start without it, enforces `sslmode=require`,
and never falls back to memory. Migrations are never run automatically.

## Neon PostgreSQL (production)

Neon is the chosen production database. See [NEON.md](NEON.md) for provisioning steps.

* Neon **requires TLS**: `db.py` sets `sslmode=require` when `SAFESIGNAL_ENV=production`.
* Neon **serverless compute** can suspend when idle; the pool recycles connections
  (`max_lifetime=1800`) and the connect timeout is extended (15s) to ride out a compute wake-up.
* Pool size defaults to 5 (`SAFESIGNAL_DB_POOL_MAX`, max 20); Neon imposes its own
  connection limit, so keep the pool small.
* `GET /health/ready` returns 200 (and pings the DB) or 503.


## Environment
| Variable | Purpose |
|---|---|
| `DATABASE_URL` | Runtime connection (least-privilege role); requires `?sslmode=require` for Neon |
| `DATABASE_MIGRATE_URL` | Optional: schema-owner role used only by `migrate.py` |
| `SAFESIGNAL_ENV=production` | Require DATABASE_URL; enforce sslmode=require; enable HSTS/CSP |
| `SAFESIGNAL_DB_POOL_MAX` | Pool size, default 5 (max 20) |
| `SAFESIGNAL_CORS_ORIGINS` | Comma-separated browser origins; empty = none (native apps only) |
| `TEST_DATABASE_URL` | Dedicated test DB; its name must end in `_test` |

## One-time setup (as postgres superuser; choose real passwords)
```sql
CREATE ROLE safesignal_owner LOGIN PASSWORD '...';
CREATE ROLE safesignal_app   LOGIN PASSWORD '...';
CREATE DATABASE safesignal OWNER safesignal_owner;
-- after the first migration, as safesignal_owner:
GRANT SELECT, INSERT, UPDATE ON reports TO safesignal_app;
GRANT SELECT, INSERT         ON idempotency_keys TO safesignal_app;
```
Listen on localhost/socket only; do not expose port 5432.

## Migrate (BACK UP FIRST)
```
pg_dump -Fc safesignal > safesignal-$(date +%F).dump   # required before every migration
DATABASE_MIGRATE_URL=... python migrate.py
```
Each file runs in one transaction and is recorded in `schema_migrations`; an advisory lock
prevents concurrent runs. There is no automatic rollback: restore the dump instead.

## Backup / restore
Nightly encrypted `pg_dump -Fc`, copied off the VPS. Test a restore (`pg_restore -d new_db file`)
before launch. Reports contain route/vehicle/SACCO text, so treat dumps as sensitive.

## Startup checks
`GET /health/live` returns 200 (process alive). `GET /health/ready` returns 200 (and pings the DB) or 503.
Run **one** Uvicorn worker: rate limits are per-process. Behind a proxy see the note in `ratelimit.py`.

## Rate limit vs transactions
The limiter is in memory and is charged inside the DB transaction, after the report and key rows
are inserted and only for new reports; a rejection rolls everything back and charges nothing.
Remaining case: if the limiter charges and the final COMMIT then fails (e.g. DB drops), one
allowance is consumed without a stored report. The client's retry (same key) is safe.

## Retention
No automatic deletion of reports or idempotency keys yet; policy pending approval.
The decision record is [docs/RETENTION.md](../../docs/RETENTION.md); no period is decided there yet.
Operators can delete one report by code: `DELETE FROM reports WHERE code = 'SS-XXXX-XXXX'`.
