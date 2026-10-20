"""PostgreSQL integration tests. Run only when TEST_DATABASE_URL points at a database whose
name ends in _test; otherwise they are SKIPPED (not passed)."""
import os
from concurrent.futures import ThreadPoolExecutor

import pytest

pytest.importorskip("psycopg")
pytest.importorskip("psycopg_pool")
import psycopg
from psycopg.conninfo import conninfo_to_dict

URL = os.getenv("TEST_DATABASE_URL", "").strip()
if not URL:
    pytest.skip("TEST_DATABASE_URL not set", allow_module_level=True)
if not (conninfo_to_dict(URL).get("dbname") or "").endswith("_test"):
    pytest.skip("refusing: test database name must end with _test", allow_module_level=True)

from fastapi.testclient import TestClient

import db
import migrate
import ratelimit
import store
from main import app
from schemas import ReportIn

DATA = ReportIn(incident="threats", timing="now", support="private", route="Ruiru to Nairobi")
KEY = "pg-test-key-0123456789abcdef"


@pytest.fixture(autouse=True)
def pg(monkeypatch):
    monkeypatch.delenv("SAFESIGNAL_ENV", raising=False)
    migrate.run(URL)
    with psycopg.connect(URL, autocommit=True) as c:
        c.execute("TRUNCATE reports CASCADE")
    db.init(URL)
    monkeypatch.setenv("SAFESIGNAL_ADMIN_KEY", "k-test")
    yield
    db.close()


def test_create_and_list():
    r = store.create(DATA)
    assert r.code.startswith("SS-") and r.status == "Received" and r.acknowledged_at is None
    assert [x.id for x in store.list_all()] == [r.id]


def test_idempotent_replay_and_conflict():
    a = store.create(DATA, KEY)
    assert store.create(DATA, KEY) == a
    with pytest.raises(store.KeyConflict):
        store.create(DATA.model_copy(update={"incident": "unsure"}), KEY)
    assert len(store.list_all()) == 1


def test_concurrent_same_key_creates_one():
    with ThreadPoolExecutor(16) as ex:
        out = list(ex.map(lambda _: store.create(DATA, KEY), range(16)))
    assert len({r.id for r in out}) == 1 and len(store.list_all()) == 1


def test_replay_costs_no_allowance_and_rejected_stores_nothing():
    hits = []
    store.create(DATA, KEY, admit=lambda: hits.append(1))
    store.create(DATA, KEY, admit=lambda: hits.append(1))
    assert hits == [1]

    def deny():
        raise ratelimit.RateLimited(5)

    with pytest.raises(ratelimit.RateLimited):
        store.create(DATA, "another-key-0123456789abcd", admit=deny)
    assert len(store.list_all()) == 1


def test_reference_code_collision_is_retried(monkeypatch):
    first = store.create(DATA)
    codes = iter([first.code, first.code, "SS-ZZZZ-2222"])
    monkeypatch.setattr(store, "new_code", lambda: next(codes))
    assert store.create(DATA).code == "SS-ZZZZ-2222"


def test_status_update_persists_and_sets_acknowledged():
    r = store.create(DATA)
    u = store.set_status(r.id, "Reviewing")
    assert u.status == "Reviewing" and u.acknowledged_at is not None
    assert store.set_status("not-a-uuid", "Closed") is None
    assert store.set_status("0" * 32, "Closed") is None


def test_persists_across_pool_reinit():
    r = store.create(DATA, KEY)
    db.close()
    db.init(URL)
    assert [x.id for x in store.list_all()] == [r.id]
    assert store.create(DATA, KEY).id == r.id


def test_outage_returns_503_without_leaking():
    db.close()
    db.init("postgresql://nobody:pw@127.0.0.1:1/x_test")
    r = TestClient(app).post(
        "/api/reports", json={"incident": "unsure", "support": "private"}
    )
    assert r.status_code == 503 and "pw" not in r.text and "127.0.0.1" not in r.text
