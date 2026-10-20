import io
import json
import urllib.error

import pytest
from fastapi.testclient import TestClient

import assistant
from main import app

client = TestClient(app)
KEY = "sk-or-test-SECRET123"


@pytest.fixture(autouse=True)
def _reset(monkeypatch):
    assistant._hits.clear()
    monkeypatch.setenv("OPENROUTER_API_KEY", KEY)


class FakeResp(io.BytesIO):
    def __enter__(self):
        return self

    def __exit__(self, *a):
        pass


def patch_urlopen(monkeypatch, result):
    seen = {}

    def fake(req, timeout=None):
        seen["body"] = json.loads(req.data)
        if isinstance(result, Exception):
            raise result
        return FakeResp(json.dumps(result).encode() if not isinstance(result, bytes) else result)

    monkeypatch.setattr(assistant.urllib.request, "urlopen", fake)
    return seen


def ask(msg="How do I report an incident?"):
    return client.post("/api/assistant/chat", json={"message": msg})


def http_err(code):
    return urllib.error.HTTPError("u", code, "x " + KEY, {}, io.BytesIO(b"secret " + KEY.encode()))


def test_success_and_redaction(monkeypatch):
    seen = patch_urlopen(monkeypatch, {"choices": [{"message": {"content": "Tap Report."}}]})
    r = ask("my number 0712 345 678 plate KCA 123A at -1.28334, 36.81667")
    assert r.status_code == 200 and r.json()["source"] == "ai"
    sent = seen["body"]["messages"][-1]["content"]
    assert "0712" not in sent and "KCA" not in sent and "36.81667" not in sent
    assert seen["body"]["model"] == "google/gemma-4-31b-it:free"
    assert seen["body"]["max_tokens"] == assistant.MAX_OUTPUT_TOKENS


def test_missing_key(monkeypatch):
    monkeypatch.delenv("OPENROUTER_API_KEY")
    assert ask().status_code == 503


@pytest.mark.parametrize("code", [401, 402, 404, 429, 500, 503])
def test_provider_http_errors_sanitized(monkeypatch, code):
    patch_urlopen(monkeypatch, http_err(code))
    r = ask()
    assert r.status_code == 503
    assert r.json() == {"detail": "assistant_unavailable"}
    assert KEY not in r.text


@pytest.mark.parametrize(
    "exc", [TimeoutError(), urllib.error.URLError("down " + KEY)]
)
def test_timeout_and_outage(monkeypatch, exc):
    patch_urlopen(monkeypatch, exc)
    r = ask()
    assert r.status_code == 503 and KEY not in r.text


@pytest.mark.parametrize("payload", [{}, {"choices": []}, {"choices": [{"message": {"content": ""}}]}, b"not json"])
def test_malformed(monkeypatch, payload):
    patch_urlopen(monkeypatch, payload)
    assert ask().status_code == 503


def test_emergency_skips_provider(monkeypatch):
    patch_urlopen(monkeypatch, AssertionError("must not call"))
    r = ask("help me, I am being attacked")
    assert r.json()["source"] == "emergency" and "999" in r.json()["reply"]


def test_validation_and_throttle(monkeypatch):
    assert client.post("/api/assistant/chat", json={"message": "x" * 501}).status_code == 422
    patch_urlopen(monkeypatch, {"choices": [{"message": {"content": "ok"}}]})
    codes = [ask().status_code for _ in range(assistant.RATE_LIMIT + 1)]
    assert codes[-1] == 429
