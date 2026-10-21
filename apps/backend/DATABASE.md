# SafeSignal database (PostgreSQL)

Storage is selected by `DATABASE_URL`. Unset = in-memory (development/tests only).
`SAFESIGNAL_ENV=production` refuses to start without it and never falls back to memory.
Migrations are never run automatically.

## Environment
| Variable | Purpose |
|---|---|
| `DATABASE_URL` | Runtime connection (least-privilege role) |
| `DATABASE_MIGRATE_URL` | Optional: schema-owner role used only by `migrate.py` |
| `SAFESIGNAL_ENV=production` | Require DATABASE_URL at startup |
| `SAFESIGNAL_DB_POOL_MAX` | Pool size, default 5 (max 20) |
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
`GET /health/ready` returns 200 (and pings the DB) or 503. Run **one** Uvicorn worker:
rate limits are per-process. Behind a proxy see the note in `ratelimit.py`.

## Rate limit vs transactions
The limiter is in memory and is charged inside the DB transaction, after the report and key rows
are inserted and only for new reports; a rejection rolls everything back and charges nothing.
Remaining case: if the limiter charges and the final COMMIT then fails (e.g. DB drops), one
allowance is consumed without a stored report. The client's retry (same key) is safe.

## Retention
No automatic deletion of reports or idempotency keys yet; policy pending approval.
The decision record is [docs/RETENTION.md](../../docs/RETENTION.md); no period is decided there yet.
Operators can delete one report by code: `DELETE FROM reports WHERE code = 'SS-XXXX-XXXX'`.
