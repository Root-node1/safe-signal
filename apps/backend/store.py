import secrets
import threading
import time
import uuid

from schemas import ReportIn, ReportOut, Status, Urgency

# No 0/O/1/I/L so the code is easy to read out or write down.
ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"

_lock = threading.Lock()
_reports: list[ReportOut] = []  # In memory only. Resets on restart.


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


def create(data: ReportIn) -> ReportOut:
    report = ReportOut(
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
    with _lock:
        _reports.append(report)
    return report


def list_all() -> list[ReportOut]:
    with _lock:
        return sorted(_reports, key=lambda r: r.created_at, reverse=True)


def set_status(report_id: str, status: Status) -> ReportOut | None:
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
