from concurrent.futures import ThreadPoolExecutor

import pytest
from fastapi.testclient import TestClient

import ratelimit
import store
from main import app

client = TestClient(app)
BODY = {"incident": "threats", "timing": "now", "support": "private"}
ADMIN = {"X-Admin-Key": "test-admin-key"}


def key(n):
    return f"key-{n:04d}-abcdefghijklmnop"


@pytest.fixture(autouse=True)
def _clean(monkeypatch):
    store.reset()
    ratelimit.report_limiter.clear()
    ratelimit.admin_limiter.clear()
    monkeypatch.setenv("SAFESIGNAL_ADMIN_KEY", "test-admin-key")
    monkeypatch.setenv("SAFESIGNAL_REPORT_RATE_LIMIT", "3")
    monkeypatch.setenv("SAFESIGNAL_ADMIN_FAIL_LIMIT", "3")
    monkeypatch.setattr(ratelimit.report_limiter, "clock", lambda: clock[0])
    monkeypatch.setattr(ratelimit.admin_limiter, "clock", lambda: clock[0])
    clock[0] = 1000.0


clock = [1000.0]


def post(n, body=BODY, headers=None):
    return client.post("/api/reports", json=body, headers={"Idempotency-Key": key(n), **(headers or {})})


def test_allowed_then_429_with_retry_after():
    assert [post(i).status_code for i in range(3)] == [201] * 3
    r = post(3)
    assert r.status_code == 429
    assert int(r.headers["retry-after"]) >= 1
    assert len(store.list_all()) == 3


def test_window_expiry():
    for i in range(3):
        post(i)
    assert post(9).status_code == 429
    clock[0] += 3601
    assert post(10).status_code == 201


def test_idempotent_replay_free_when_full():
    for i in range(3):
        post(i)
    assert post(1).status_code == 201  # same key + payload, limit full
    assert len(store.list_all()) == 3


def test_conflict_still_409_when_full():
    for i in range(3):
        post(i)
    assert post(1, {**BODY, "incident": "harassment"}).status_code == 409


def test_concurrent_cannot_bypass_limit():
    with ThreadPoolExecutor(10) as ex:
        codes = list(ex.map(lambda i: post(i).status_code, range(20)))
    assert sorted(set(codes)) == [201, 429]
    assert codes.count(201) == 3 and len(store.list_all()) == 3


def test_spoofed_forwarding_headers_ignored():
    for i in range(3):
        post(i)
    r = post(7, headers={"X-Forwarded-For": "203.0.113.9", "X-Real-IP": "203.0.113.10"})
    assert r.status_code == 429


def test_admin_lockout_after_failures():
    for _ in range(3):
        assert client.get("/api/reports", headers={"X-Admin-Key": "bad"}).status_code == 401
    r = client.get("/api/reports", headers={"X-Admin-Key": "bad"})
    assert r.status_code == 429 and int(r.headers["retry-after"]) >= 1
    assert client.get("/api/reports", headers=ADMIN).status_code == 429  # locked out
    assert "test-admin-key" not in r.text
    clock[0] += 901
    assert client.get("/api/reports", headers=ADMIN).status_code == 200


def test_admin_success_does_not_consume_allowance():
    for _ in range(10):
        assert client.get("/api/reports", headers=ADMIN).status_code == 200
    assert client.get("/api/reports", headers={"X-Admin-Key": "bad"}).status_code == 401


def test_unconfigured_key_failures_also_limited(monkeypatch):
    monkeypatch.setenv("SAFESIGNAL_ADMIN_KEY", "")
    codes = [client.get("/api/reports").status_code for _ in range(4)]
    assert codes == [401, 401, 401, 429]


def test_unrelated_endpoints_unaffected():
    for i in range(5):
        post(i)
    assert client.get("/").status_code == 200
    pre = client.options(
        "/api/reports",
        headers={"Origin": "http://localhost:5173", "Access-Control-Request-Method": "POST"},
    )
    assert pre.status_code == 200
