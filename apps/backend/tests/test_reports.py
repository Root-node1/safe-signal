from fastapi.testclient import TestClient

from main import app

client = TestClient(app)

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

    listed = client.get("/api/reports").json()
    assert any(r["id"] == body["id"] for r in listed)


def test_rejects_unknown_incident_type():
    res = client.post("/api/reports", json={**VALID, "incident": "nonsense"})
    assert res.status_code == 422


def test_status_update_sets_acknowledged():
    created = client.post("/api/reports", json=VALID).json()
    res = client.patch(
        f"/api/reports/{created['id']}/status", json={"status": "Reviewing"}
    )
    assert res.status_code == 200
    assert res.json()["status"] == "Reviewing"
    assert res.json()["acknowledgedAt"] is not None


def test_status_update_unknown_report_is_404():
    res = client.patch("/api/reports/does-not-exist/status", json={"status": "Closed"})
    assert res.status_code == 404


def test_admin_key_is_enforced_when_set(monkeypatch):
    monkeypatch.setenv("SAFESIGNAL_ADMIN_KEY", "secret")
    assert client.get("/api/reports").status_code == 401
    assert (
        client.get("/api/reports", headers={"X-Admin-Key": "secret"}).status_code == 200
    )
