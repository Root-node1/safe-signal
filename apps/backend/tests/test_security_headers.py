"""Tests for configurable CORS, security headers, and the health/live + /analyze deprecation."""

import importlib

import pytest
from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def _reimport_app():
    """Re-import main so the CORS/security-header config picks up env changes."""
    import main as main_module
    importlib.reload(main_module)
    return main_module.app


# --- CORS configuration ---

def test_cors_allows_configured_origin(monkeypatch):
    monkeypatch.setenv("SAFESIGNAL_CORS_ORIGINS", "http://localhost:5173")
    c = TestClient(_reimport_app())
    r = c.options(
        "/api/reports",
        headers={"Origin": "http://localhost:5173", "Access-Control-Request-Method": "POST"},
    )
    assert r.status_code == 200
    assert r.headers["access-control-allow-origin"] == "http://localhost:5173"


def test_cors_blocks_unlisted_origin(monkeypatch):
    monkeypatch.setenv("SAFESIGNAL_CORS_ORIGINS", "http://localhost:5173")
    c = TestClient(_reimport_app())
    r = c.options(
        "/api/reports",
        headers={"Origin": "https://evil.example.com", "Access-Control-Request-Method": "POST"},
    )
    assert "access-control-allow-origin" not in r.headers


def test_cors_multiple_origins(monkeypatch):
    monkeypatch.setenv("SAFESIGNAL_CORS_ORIGINS", "https://app.zindika.app,http://localhost:5173")
    c = TestClient(_reimport_app())
    r = c.options(
        "/api/reports",
        headers={"Origin": "https://app.zindika.app", "Access-Control-Request-Method": "POST"},
    )
    assert r.status_code == 200
    assert r.headers["access-control-allow-origin"] == "https://app.zindika.app"


def test_cors_empty_allows_no_browser_origins(monkeypatch):
    monkeypatch.setenv("SAFESIGNAL_CORS_ORIGINS", "")
    c = TestClient(_reimport_app())
    r = c.options(
        "/api/reports",
        headers={"Origin": "http://localhost:5173", "Access-Control-Request-Method": "POST"},
    )
    assert "access-control-allow-origin" not in r.headers


def test_cors_whitespace_pared(monkeypatch):
    monkeypatch.setenv("SAFESIGNAL_CORS_ORIGINS", " https://app.zindika.app , http://localhost:5173 ")
    c = TestClient(_reimport_app())
    r = c.options(
        "/api/reports",
        headers={"Origin": "https://app.zindika.app", "Access-Control-Request-Method": "POST"},
    )
    assert r.headers["access-control-allow-origin"] == "https://app.zindika.app"


# --- Security headers ---

def test_security_headers_present():
    r = client.get("/")
    assert r.headers["x-content-type-options"] == "nosniff"
    assert r.headers["x-frame-options"] == "DENY"
    assert r.headers["referrer-policy"] == "strict-origin-when-cross-origin"


@pytest.mark.parametrize("path", ["/", "/health/live", "/health/ready"])
def test_security_headers_on_all_routes(path):
    r = client.get(path)
    assert r.headers["x-content-type-options"] == "nosniff"
    assert r.headers["x-frame-options"] == "DENY"


def test_hsts_only_in_production(monkeypatch):
    monkeypatch.delenv("SAFESIGNAL_ENV", raising=False)
    r = TestClient(_reimport_app()).get("/")
    assert "strict-transport-security" not in r.headers

    monkeypatch.setenv("SAFESIGNAL_ENV", "production")
    r = TestClient(_reimport_app()).get("/")
    assert "max-age=31536000" in r.headers["strict-transport-security"]


def test_csp_only_in_production(monkeypatch):
    monkeypatch.delenv("SAFESIGNAL_ENV", raising=False)
    r = TestClient(_reimport_app()).get("/")
    assert "content-security-policy" not in r.headers

    monkeypatch.setenv("SAFESIGNAL_ENV", "production")
    r = TestClient(_reimport_app()).get("/")
    assert "default-src" in r.headers["content-security-policy"]


def test_x_xss_protection_set_to_zero():
    r = client.get("/")
    assert r.headers["x-xss-protection"] == "0"


# --- Health and /analyze ---

def test_health_live():
    r = client.get("/health/live")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_analyze_deprecated():
    r = client.post("/analyze", json={"text": "test"})
    assert r.status_code == 410
    assert "removed" in r.json()["detail"].lower()


def test_cors_preflight_allows_methods():
    r = client.options(
        "/api/reports",
        headers={"Origin": "http://localhost:5173", "Access-Control-Request-Method": "PATCH"},
    )
    assert r.status_code == 200
