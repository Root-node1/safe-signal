import os
import secrets

from fastapi import APIRouter, Depends, Header, HTTPException

import store
from schemas import ReportIn, ReportOut, StatusIn

router = APIRouter(prefix="/api/reports", tags=["reports"])


def require_admin(x_admin_key: str | None = Header(default=None)) -> None:
    # If SAFESIGNAL_ADMIN_KEY is set, admin routes need it. Unset = open (dev only).
    expected = os.getenv("SAFESIGNAL_ADMIN_KEY")
    if expected and not secrets.compare_digest(x_admin_key or "", expected):
        raise HTTPException(status_code=401, detail="Not authorised")


@router.post("", response_model=ReportOut, status_code=201)
def create_report(data: ReportIn) -> ReportOut:
    # Public: no account needed.
    return store.create(data)


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
