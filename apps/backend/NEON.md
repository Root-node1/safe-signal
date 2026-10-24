# Neon PostgreSQL provisioning for SafeSignal

This guide provisions a Neon PostgreSQL database for SafeSignal production use
on a Contabo VPS. No credentials are included here — fill them from your
Neon project settings and store them in `/etc/safesignal/backend.env` on the server.

## 1. Create a Neon project

1. Sign in to <https://console.neon.tech>.
2. Click **New Project**. Use the **Frankfurt** region (`agent-gate`, as recorded in
   `docs/deploy/HOSTING_COMPARISON.md` § 10).
3. Choose **PostgreSQL 17** or later (Neon's GA version; SafeSignal's test suite
   targets PostgreSQL 16/18 — Neon's Postgres 17 is wire-compatible with psycopg3).

## 2. Connection string

In the Neon dashboard, open your project and go to **Connection string**. It looks like:

```
postgresql://<username>:<password>@<endpoint>.aws.neon.tech/<dbname>?sslmode=require
```

Copy three values (never commit them):

| Variable                     | Source                                |
|---|---|
| `DATABASE_URL`               | The default connection string above   |
| `DATABASE_MIGRATE_URL`       | A second connection string for the `safesignal_owner` role (if using role split) |

Neon **always requires TLS**, so the `?sslmode=require` parameter is mandatory.
`db.py` enforces `sslmode=require` when `SAFESIGNAL_ENV=production`.

## 3. Apply the schema

On the Contabo VPS, after pulling the code and before starting the service:

```bash
cd /opt/safesignal
export $(cat /etc/safesignal/backend.env)
python migrate.py
```

`migrate.py` is idempotent: it records applied migrations in
`schema_migrations` and skips already-applied ones. It holds a PostgreSQL
advisory lock so two instances cannot run concurrently.

## 4. Role split (recommended for production)

The migration runs as the project owner by default (`DATABASE_URL`). For a
least-privilege split, create a dedicated app role in Neon SQL:

```sql
-- Run in the Neon SQL editor as the project owner:
CREATE ROLE safesignal_app NOSUPERUSER NOCREATEDB NOCREATEROLE LOGIN PASSWORD '<random>';
GRANT CONNECT ON DATABASE <dbname> TO safesignal_app;
GRANT USAGE ON SCHEMA public TO safesignal_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON reports, idempotency_keys TO safesignal_app;
GRANT USAGE ON SEQUENCE reports_id_seq TO safesignal_app;
```

Then use:
* `DATABASE_MIGRATE_URL` = the owner connection string (for migrations only)
* `DATABASE_URL` = the `safesignal_app` connection string (for the running app)

If you skip the role split, use the same connection string for both.

## 5. Serverless compute note

Neon's serverless compute can suspend when idle. The backend's connection pool
(`psycopg_pool`) has `max_lifetime=1800` (30 min) in production to recycle
connections before the compute suspends. If you see intermittent 503s after a
period of inactivity, that is the compute resuming — the pool reconnects
automatically. No action is needed.

## 6. Backups

Neon provides automatic daily backups, point-in-time recovery, and storage-level
encryption at rest. For an **off-host application-level backup**, use
`apps/backend/deploy/backup-postgres.sh.example` in nightly cron, encrypting
with `age` and copying to an external object store. This is separate from and
in addition to Neon's built-in backups.

## 7. Connection limits

Neon imposes connection limits (20–100 depending on plan). The backend pool
defaults to 5 connections (`SAFESIGNAL_DB_POOL_MAX`, max 20). For the pilot this
is sufficient; monitor `pg_stat_activity` in the Neon SQL editor if you see
connection errors.

## 8. Verify

After migration and service start:

```bash
curl https://app.zindika.app/health/ready
# Expected: {"status":"ok","storage":"postgres"}
```

If the database is unreachable, `/health/ready` returns 503. No DSN or host
details appear in the response or the server logs.
