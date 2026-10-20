"""In-memory sliding-window limiter for the prototype.

State is per process and resets on restart. Client identity is the direct connection
address (request.client.host). X-Forwarded-For and similar headers are NOT read here, so a
client cannot spoof its way around a limit. Production behind a reverse proxy: the proxy
must overwrite (not append to) X-Forwarded-For, and uvicorn must only trust that proxy
(--proxy-headers --forwarded-allow-ips=<proxy ip>); then request.client.host is the real
client. Without that, every request appears to come from the proxy and shares one bucket.
Neither addresses nor request contents are logged.
"""
import os
import threading
import time
from collections import defaultdict, deque

from fastapi import HTTPException, Request


class RateLimited(Exception):
    def __init__(self, retry_after: int):
        self.retry_after = retry_after


def env_int(name: str, default: int) -> int:
    try:
        v = int(os.getenv(name, ""))
        return v if v > 0 else default
    except ValueError:
        return default


def client_id(request: Request) -> str:
    return request.client.host if request.client else "unknown"


def too_many(retry_after: int, detail: str = "Too many requests") -> HTTPException:
    return HTTPException(
        status_code=429, detail=detail, headers={"Retry-After": str(max(1, retry_after))}
    )


class Limiter:
    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._hits: dict[str, deque] = defaultdict(deque)
        self.clock = time.monotonic

    def acquire(self, key: str, limit: int, window: float) -> None:
        """Atomically record one hit, or raise RateLimited if the window is full."""
        now = self.clock()
        with self._lock:
            q = self._hits[key]
            while q and now - q[0] >= window:
                q.popleft()
            if len(q) >= limit:
                raise RateLimited(int(window - (now - q[0])) + 1)
            q.append(now)
            if len(self._hits) > 5000:  # bound memory
                for k in [k for k, v in self._hits.items() if not v or now - v[-1] >= window]:
                    del self._hits[k]

    def release(self, key: str) -> None:
        """Undo the most recent hit (e.g. after a successful admin login)."""
        with self._lock:
            q = self._hits.get(key)
            if q:
                q.pop()

    def clear(self) -> None:
        with self._lock:
            self._hits.clear()


report_limiter = Limiter()
admin_limiter = Limiter()


def report_limits() -> tuple[int, int]:
    return env_int("SAFESIGNAL_REPORT_RATE_LIMIT", 10), env_int("SAFESIGNAL_REPORT_RATE_WINDOW", 3600)


def admin_limits() -> tuple[int, int]:
    return env_int("SAFESIGNAL_ADMIN_FAIL_LIMIT", 5), env_int("SAFESIGNAL_ADMIN_FAIL_WINDOW", 900)
