"""PostgreSQL implementation behind store.py. All SQL is parameterised; report content is never logged."""
import secrets
import uuid

import psycopg.errors

import db
from schemas import ReportIn, ReportOut

_COLS = (
    "{p}id, {p}code, {p}incident, {p}urgency, {p}route, {p}area, {p}vehicle, {p}sacco, "
    "{p}support, {p}consent_to_share, {p}status, "
    "(extract(epoch from {p}created_at) * 1000)::bigint, "
    "(extract(epoch from {p}acknowledged_at) * 1000)::bigint"
)
COLS = _COLS.format(p="")
RCOLS = _COLS.format(p="r.")


class _Retry(Exception):
    pass


def _report(r) -> ReportOut:
    return ReportOut(
        id=r[0].hex, code=r[1], incident=r[2], urgency=r[3], route=r[4], area=r[5],
        vehicle=r[6], sacco=r[7], support=r[8], consent_to_share=r[9], status=r[10],
        created_at=r[11], acknowledged_at=r[12],
    )  # fmt: skip


def _lookup(conn, key: str):
    return conn.execute(
        f"SELECT k.payload_hash, {RCOLS} FROM idempotency_keys k "
        "JOIN reports r ON r.id = k.report_id WHERE k.key = %s",
        (key,),
    ).fetchone()


def _resolve(row, fingerprint: str) -> ReportOut:
    from store import KeyConflict

    if not secrets.compare_digest(row[0], fingerprint):
        raise KeyConflict
    return _report(row[1:])


def _attempt(report: ReportOut, key, fingerprint, admit) -> ReportOut:
    with db.connection() as conn:
        if key and (row := _lookup(conn, key)):
            return _resolve(row, fingerprint)  # replay: no allowance used
        conn.execute(
            "INSERT INTO reports (id, code, incident, urgency, route, area, vehicle, sacco, "
            "support, consent_to_share, status, created_at) VALUES "
            "(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s, to_timestamp(%s::double precision / 1000))",
            (uuid.UUID(report.id), report.code, report.incident, report.urgency, report.route,
             report.area, report.vehicle, report.sacco, report.support,
             report.consent_to_share, report.status, report.created_at),
        )  # fmt: skip
        if key:
            won = conn.execute(
                "INSERT INTO idempotency_keys (key, payload_hash, report_id) VALUES (%s,%s,%s) "
                "ON CONFLICT (key) DO NOTHING RETURNING key",
                (key, fingerprint, uuid.UUID(report.id)),
            ).fetchone()
            if won is None:
                # A concurrent request with this key committed first: discard ours, return theirs.
                conn.rollback()
                row = _lookup(conn, key)
                if row is None:
                    raise _Retry
                return _resolve(row, fingerprint)
        if admit:
            admit()  # raises RateLimited -> whole transaction rolls back, nothing stored
        return report  # commit happens when the connection block exits


def create(data: ReportIn, key, fingerprint, build, admit) -> ReportOut:
    for _ in range(5):
        report = build(data)  # fresh id and reference code each attempt
        try:
            return _attempt(report, key, fingerprint, admit)
        except _Retry:
            continue
        except psycopg.errors.UniqueViolation as e:
            if e.diag.constraint_name != "reports_code_key":
                raise
    raise db.DatabaseUnavailable


def list_all() -> list[ReportOut]:
    with db.connection() as conn:
        rows = conn.execute(f"SELECT {COLS} FROM reports ORDER BY created_at DESC").fetchall()
    return [_report(r) for r in rows]


def set_status(report_id: str, status: str) -> ReportOut | None:
    try:
        rid = uuid.UUID(report_id)
    except ValueError:
        return None
    with db.connection() as conn:
        row = conn.execute(
            "UPDATE reports SET status = %s, acknowledged_at = COALESCE(acknowledged_at, "
            "CASE WHEN %s <> 'Received' THEN now() END) WHERE id = %s "
            f"RETURNING {COLS}",
            (status, status, rid),
        ).fetchone()
    return _report(row) if row else None
