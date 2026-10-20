"""Runs without PostgreSQL: startup rules, error mapping, and schema/migration drift checks."""
import re
from pathlib import Path
from typing import get_args

import pytest
from fastapi.testclient import TestClient

import db
import schemas
import store
from main import app

SQL = (Path(__file__).parent.parent / "migrations" / "001_init.sql").read_text()


def test_production_requires_database_url(monkeypatch):
    monkeypatch.setenv("SAFESIGNAL_ENV", "production")
    monkeypatch.delenv("DATABASE_URL", raising=False)
    with pytest.raises(RuntimeError):
        db.init()
    monkeypatch.setenv("DATABASE_URL", "   ")
    with pytest.raises(RuntimeError):
        db.init()
    assert not db.enabled()  # never silently memory-backed AND started


def test_development_without_url_uses_memory(monkeypatch):
    monkeypatch.delenv("SAFESIGNAL_ENV", raising=False)
    monkeypatch.delenv("DATABASE_URL", raising=False)
    db.init()
    assert not db.enabled()
    r = TestClient(app).get("/health/ready")
    assert r.status_code == 200 and r.json()["storage"] == "memory"


def test_database_outage_maps_to_generic_503(monkeypatch):
    def boom():
        raise db.DatabaseUnavailable

    monkeypatch.setattr(store, "list_all", boom)
    monkeypatch.setenv("SAFESIGNAL_ADMIN_KEY", "k-test")
    r = TestClient(app).get("/api/reports", headers={"X-Admin-Key": "k-test"})
    assert r.status_code == 503 and r.json() == {"detail": "Service temporarily unavailable"}


@pytest.mark.parametrize(
    "literal",
    [schemas.IncidentType, schemas.NextStep, schemas.Status, schemas.Urgency],
)
def test_sql_constraints_match_schema_literals(literal):
    for value in get_args(literal):
        assert f"'{value}'" in SQL, value


def test_sql_has_no_extra_enum_values():
    allowed = set()
    for lit in (schemas.IncidentType, schemas.NextStep, schemas.Status, schemas.Urgency):
        allowed |= set(get_args(lit))
    in_lists = re.findall(r"IN\s*\(([^)]*)\)", SQL)
    for lst in in_lists:
        for v in re.findall(r"'([^']*)'", lst):
            assert v in allowed, v
