import pytest
from fastapi.testclient import TestClient

from main import app

client = TestClient(app)
ADMIN = {"X-Admin-Key": "test-admin-key"}


@pytest.fixture(autouse=True)
def _admin_env(monkeypatch):
    monkeypatch.setenv("SAFESIGNAL_ADMIN_FAIL_LIMIT", "1000")  # lockout is tested in test_ratelimit
    monkeypatch.setenv("SAFESIGNAL_ADMIN_KEY", "test-admin-key")

VALID = {
    "incident": "threats",
    "timing": "now",
    "route": "Ruiru to Nairobi",
    "support": "private",
}


def test_create_then_list_report():
    res = client.post("/api/reports", json=VALID)
    assert res.status_code == 201
    body = res.json()
    assert body["code"].startswith("SS-")
    assert body["urgency"] == "high"
    assert body["status"] == "Received"
    assert body["acknowledgedAt"] is None

    listed = client.get("/api/reports", headers=ADMIN).json()
    assert any(r["id"] == body["id"] for r in listed)


def test_rejects_unknown_incident_type():
    res = client.post("/api/reports", json={**VALID, "incident": "nonsense"})
    assert res.status_code == 422


def test_status_update_sets_acknowledged():
    created = client.post("/api/reports", json=VALID).json()
    res = client.patch(
        f"/api/reports/{created['id']}/status", json={"status": "Reviewing"}, headers=ADMIN
    )
    assert res.status_code == 200
    assert res.json()["status"] == "Reviewing"
    assert res.json()["acknowledgedAt"] is not None


def test_status_update_unknown_report_is_404():
    res = client.patch("/api/reports/does-not-exist/status", json={"status": "Closed"}, headers=ADMIN)
    assert res.status_code == 404


ADMIN_CALLS = [
    ("get", "/api/reports", None),
    ("patch", "/api/reports/some-id/status", {"status": "Closed"}),
]


def call(method, path, body, headers=None):
    return getattr(client, method)(path, headers=headers or {}, **({"json": body} if body else {}))


@pytest.mark.parametrize("value", [None, "", "   "])
def test_unconfigured_key_denies_everything(monkeypatch, value):
    if value is None:
        monkeypatch.delenv("SAFESIGNAL_ADMIN_KEY")
    else:
        monkeypatch.setenv("SAFESIGNAL_ADMIN_KEY", value)
    for method, path, body in ADMIN_CALLS:
        for hdr in ({}, {"X-Admin-Key": ""}, {"X-Admin-Key": " "}, {"X-Admin-Key": "anything"}):
            assert call(method, path, body, hdr).status_code == 401


@pytest.mark.parametrize("method,path,body", ADMIN_CALLS)
def test_missing_or_wrong_credential_denied(method, path, body):
    assert call(method, path, body).status_code == 401
    assert call(method, path, body, {"X-Admin-Key": "wrong"}).status_code == 401
    assert call(method, path, body, {"X-Admin-Key": "wrong-é".encode("latin-1")}).status_code == 401


def test_correct_credential_allowed():
    assert client.get("/api/reports", headers=ADMIN).status_code == 200


def test_every_admin_route_is_protected():
    from main import app as _app
    from reports import require_admin

    for route in _app.routes:
        path = getattr(route, "path", "")
        methods = getattr(route, "methods", set())
        if path.startswith("/api/reports") and methods - {"POST", "HEAD", "OPTIONS"}:
            assert any(d.call is require_admin for d in route.dependant.dependencies), path


def test_public_submission_needs_no_key(monkeypatch):
    monkeypatch.delenv("SAFESIGNAL_ADMIN_KEY")
    assert client.post("/api/reports", json=VALID).status_code == 201
