"""Apply migrations/*.sql in order:  python migrate.py

Uses DATABASE_MIGRATE_URL (schema-owner role) if set, else DATABASE_URL. Each file runs in
its own transaction and is recorded in schema_migrations. An advisory lock stops two runs
from overlapping. There is no automatic rollback: take a backup first (see DATABASE.md).
Never prints connection details.
"""
import os
import sys
from pathlib import Path

MIGRATIONS = Path(__file__).parent / "migrations"
LOCK_ID = 727274


def run(url: str) -> list[str]:
    import psycopg

    applied: list[str] = []
    with psycopg.connect(url, autocommit=True, connect_timeout=5) as conn:
        conn.execute("SELECT pg_advisory_lock(%s)", (LOCK_ID,))
        conn.execute(
            "CREATE TABLE IF NOT EXISTS schema_migrations "
            "(version text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())"
        )
        done = {r[0] for r in conn.execute("SELECT version FROM schema_migrations")}
        for path in sorted(MIGRATIONS.glob("*.sql")):
            if path.stem in done:
                continue
            with conn.transaction():
                conn.execute(path.read_text())
                conn.execute("INSERT INTO schema_migrations (version) VALUES (%s)", (path.stem,))
            applied.append(path.stem)
        conn.execute("SELECT pg_advisory_unlock(%s)", (LOCK_ID,))
    return applied


def main() -> int:
    url = (os.getenv("DATABASE_MIGRATE_URL") or os.getenv("DATABASE_URL") or "").strip()
    if not url:
        print("Set DATABASE_MIGRATE_URL or DATABASE_URL.", file=sys.stderr)
        return 2
    try:
        applied = run(url)
    except Exception as e:  # message may contain SQL/host details; show the type only
        print(f"Migration failed ({type(e).__name__}). Nothing from the failing file was applied.", file=sys.stderr)
        return 1
    print("Applied: " + (", ".join(applied) if applied else "nothing (up to date)"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
