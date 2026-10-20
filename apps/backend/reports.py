import os
import re
import secrets

from fastapi import APIRouter, Depends, Header, HTTPException, Request

import ratelimit
import store
from schemas import ReportIn, ReportOut, StatusIn

router = APIRouter(prefix="/api/reports", tags=["reports"])


def require_admin(request: Request, x_admin_key: str | None = Header(default=None)) -> None:
    # Fail closed: if SAFESIGNAL_ADMIN_KEY is unset, empty or whitespace, nobody is authorised.
    # Same 401 for every failure so responses don't reveal whether a key is configured.
    expected = (os.getenv("SAFESIGNAL_ADMIN_KEY") or "").strip()
    given = (x_admin_key or "").encode()
    # Each attempt takes a slot up front (atomic, so concurrent guesses can't overshoot);
    # a correct key gives it back. Only failures count towards the lockout.
    who = ratelimit.client_id(request)
    limit, window = ratelimit.admin_limits()
    try:
        ratelimit.admin_limiter.acquire(who, limit, window)
    except ratelimit.RateLimited as e:
        raise ratelimit.too_many(e.retry_after, "Too many attempts") from None
    if not expected or not secrets.compare_digest(given, expected.encode()):
        raise HTTPException(status_code=401, detail="Not authorised")
    ratelimit.admin_limiter.release(who)


_KEY_RE = re.compile(r"^[A-Za-z0-9_-]{16,64}$")


@router.post("", response_model=ReportOut, status_code=201)
def create_report(
    request: Request, data: ReportIn, idempotency_key: str | None = Header(default=None)
) -> ReportOut:
    # Public: no account needed.
    # Optional Idempotency-Key: a retry with the same key and payload returns the original
    # report. Requests without a key stay non-idempotent (older clients). Keys only last as
    # long as the in-memory store: they do not survive a server restart.
    if idempotency_key is not None and not _KEY_RE.fullmatch(idempotency_key):
        raise HTTPException(status_code=422, detail="Invalid Idempotency-Key")
    who = ratelimit.client_id(request)
    limit, window = ratelimit.report_limits()
    try:
        return store.create(
            data,
            idempotency_key,
            admit=lambda: ratelimit.report_limiter.acquire(who, limit, window),
        )
    except ratelimit.RateLimited as e:
        raise ratelimit.too_many(e.retry_after) from None
    except store.KeyConflict:
        raise HTTPException(
            status_code=409, detail="Idempotency-Key already used for a different report"
        ) from None


@router.get("", response_model=list[ReportOut], dependencies=[Depends(require_admin)])
def list_reports() -> list[ReportOut]:
    return store.list_all()


@router.patch(
    "/{report_id}/status",
    response_model=ReportOut,
    dependencies=[Depends(require_admin)],
)
def update_status(report_id: str, body: StatusIn) -> ReportOut:
    updated = store.set_status(report_id, body.status)
    if updated is None:
        raise HTTPException(status_code=404, detail="Report not found")
    return updated
