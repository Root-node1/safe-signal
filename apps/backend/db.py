"""PostgreSQL connection pool (optional). No DATABASE_URL => in-memory mode (development only).

Credentials are never logged. SAFESIGNAL_ENV=production requires DATABASE_URL and never falls
back to memory. Migrations are NOT run here; use `python migrate.py`.

Neon serverless notes
---------------------
* Neon requires TLS, so ``sslmode=require`` is enforced in production (it is the safe
  default for any managed cloud PostgreSQL too).
* Serverless compute can suspend when idle; pooled connections may go stale. A modest
  ``max_lifetime`` recycles them before that happens.
* Connection establishment can take longer than a local database when the compute wakes
  up, so the connect timeout and pool wait timeout are extended for production.
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


def _pool_config() -> dict:
    """Build the ``ConnectionPool`` keyword arguments from the environment.

    Centralised here so it can be unit-tested without opening a real pool.
    """
    try:
        max_size = max(1, min(int(os.getenv("SAFESIGNAL_DB_POOL_MAX", "5")), 20))
    except ValueError:
        max_size = 5
    production = os.getenv("SAFESIGNAL_ENV", "").strip().lower() == "production"
    if production:
        return {
            "min_size": 1,
            "max_size": max_size,
            "timeout": 15,
            "max_lifetime": 1800,
            "open": False,
            "kwargs": {"connect_timeout": 15, "sslmode": "require"},
        }
    return {
        "min_size": 1,
        "max_size": max_size,
        "timeout": 5,
        "open": False,
        "kwargs": {"connect_timeout": 5},
    }


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

    pool = ConnectionPool(url, name="safesignal", **_pool_config())
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
