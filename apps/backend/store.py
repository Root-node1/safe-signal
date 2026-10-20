import hashlib
import secrets
import threading
import time
import uuid
from collections.abc import Callable

import db
from schemas import ReportIn, ReportOut, Status, Urgency

# No 0/O/1/I/L so the code is easy to read out or write down.
ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"

_lock = threading.Lock()
_reports: list[ReportOut] = []  # In memory only. Resets on restart.
# Idempotency-Key -> (payload fingerprint, original result). Same lifetime as _reports.
_by_key: dict[str, tuple[str, ReportOut]] = {}


class KeyConflict(Exception):
    """Same idempotency key reused with a different payload."""


def reset() -> None:
    with _lock:
        _reports.clear()
        _by_key.clear()


def new_code() -> str:
    chars = "".join(secrets.choice(ALPHABET) for _ in range(8))
    return f"SS-{chars[:4]}-{chars[4:]}"


def urgency_for(incident: str, timing: str) -> Urgency:
    base = {"threats": 0, "touching": 0, "followed": 0, "harassment": 1}.get(incident, 2)
    if timing == "now":
        base = max(0, base - 1)
    return ("high", "medium", "low")[base]


def now_ms() -> int:
    return int(time.time() * 1000)


def _build(data: ReportIn) -> ReportOut:
    return ReportOut(
        id=uuid.uuid4().hex,
        code=new_code(),
        incident=data.incident,
        urgency=urgency_for(data.incident, data.timing),
        route=data.route.strip(),
        area=data.area.strip(),
        vehicle=data.vehicle.strip().upper(),
        sacco=data.sacco.strip(),
        support=data.support,
        consent_to_share=data.consent_to_share,
        status="Received",
        created_at=now_ms(),
        acknowledged_at=None,
    )


def create(
    data: ReportIn, key: str | None = None, admit: Callable[[], None] | None = None
) -> ReportOut:
    """Create a report. With a key, a matching retry returns the original result.

    The check and the insert happen under one lock, so concurrent same-key
    requests cannot create duplicates. Without a key, behaviour is unchanged.
    `admit` (rate limit) runs only when a new report would be created, inside the same lock,
    so replays cost no allowance and concurrent requests cannot slip past the limit.
    """
    fingerprint = hashlib.sha256(data.model_dump_json().encode()).hexdigest() if key else ""
    if db.enabled():
        import store_pg

        return store_pg.create(data, key, fingerprint, _build, admit)
    with _lock:
        if key and key in _by_key:
            stored_fp, original = _by_key[key]
            if not secrets.compare_digest(stored_fp, fingerprint):
                raise KeyConflict
            return original
        if admit:
            admit()
        report = _build(data)
        _reports.append(report)
        if key:
            _by_key[key] = (fingerprint, report)
        return report


def list_all() -> list[ReportOut]:
    if db.enabled():
        import store_pg

        return store_pg.list_all()
    with _lock:
        return sorted(_reports, key=lambda r: r.created_at, reverse=True)


def set_status(report_id: str, status: Status) -> ReportOut | None:
    if db.enabled():
        import store_pg

        return store_pg.set_status(report_id, status)
    with _lock:
        for i, r in enumerate(_reports):
            if r.id == report_id:
                ack = r.acknowledged_at
                if ack is None and status != "Received":
                    ack = now_ms()
                updated = r.model_copy(update={"status": status, "acknowledged_at": ack})
                _reports[i] = updated
                return updated
    return None
