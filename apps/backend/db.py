"""PostgreSQL connection pool (optional). No DATABASE_URL => in-memory mode (development only).

Credentials are never logged. SAFESIGNAL_ENV=production requires DATABASE_URL and never falls
back to memory. Migrations are NOT run here; use `python migrate.py`.
"""
import logging
import os
from contextlib import contextmanager

log = logging.getLogger("safesignal.db")
_pool = None


class DatabaseUnavailable(Exception):
    """Generic database failure; carries no connection details."""


def enabled() -> bool:
    return _pool is not None


def init(url: str | None = None) -> None:
    global _pool
    url = (url or os.getenv("DATABASE_URL") or "").strip()
    production = os.getenv("SAFESIGNAL_ENV", "").strip().lower() == "production"
    if not url:
        if production:
            raise RuntimeError("DATABASE_URL is required when SAFESIGNAL_ENV=production")
        return
    if _pool is not None:
        return
    from psycopg_pool import ConnectionPool

    try:
        max_size = max(1, min(int(os.getenv("SAFESIGNAL_DB_POOL_MAX", "5")), 20))
    except ValueError:
        max_size = 5
    pool = ConnectionPool(
        url,
        min_size=1,
        max_size=max_size,
        timeout=5,
        open=False,
        kwargs={"connect_timeout": 5},
        name="safesignal",
    )
    pool.open(wait=False)  # an unreachable database makes requests fail with 503, not startup
    _pool = pool


def close() -> None:
    global _pool
    pool, _pool = _pool, None
    if pool is not None:
        pool.close()


@contextmanager
def connection():
    """Pooled connection in a transaction: commit on success, rollback on any exception."""
    import psycopg
    from psycopg_pool import PoolClosed, PoolTimeout

    if _pool is None:
        raise DatabaseUnavailable
    try:
        with _pool.connection() as conn:
            yield conn
    except (PoolTimeout, PoolClosed, psycopg.OperationalError, psycopg.InterfaceError) as e:
        log.warning("database unavailable (%s)", type(e).__name__)  # class only
        raise DatabaseUnavailable from None


def ping() -> None:
    with connection() as conn:
        conn.execute("SELECT 1")
