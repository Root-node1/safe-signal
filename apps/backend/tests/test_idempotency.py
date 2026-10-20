from concurrent.futures import ThreadPoolExecutor

import pytest
from fastapi.testclient import TestClient

import store
from main import app

client = TestClient(app)
KEY = "0b9f2c1e-7a54-4c1d-9e0a-3f6d8b2a1c77"
BODY = {"incident": "threats", "timing": "now", "support": "private"}


@pytest.fixture(autouse=True)
def _clean():
    store.reset()


def post(body=BODY, key=KEY):
    headers = {"Idempotency-Key": key} if key is not None else {}
    return client.post("/api/reports", json=body, headers=headers)


def test_first_submission_creates_one():
    assert post().status_code == 201
    assert len(store.list_all()) == 1


def test_same_key_same_payload_returns_original():
    a, b = post(), post()
    assert a.status_code == b.status_code == 201
    assert a.json() == b.json()
    assert len(store.list_all()) == 1


def test_same_key_different_payload_conflicts():
    post()
    r = post({**BODY, "incident": "harassment"})
    assert r.status_code == 409
    assert len(store.list_all()) == 1
    assert "harassment" not in r.text


def test_concurrent_same_key_creates_one():
    with ThreadPoolExecutor(8) as ex:
        results = list(ex.map(lambda _: post(), range(16)))
    assert {r.status_code for r in results} == {201}
    assert len({r.json()["code"] for r in results}) == 1
    assert len(store.list_all()) == 1


@pytest.mark.parametrize("bad", ["short", "x" * 65, "has space in it 123456", "bad/chars/1234567890"])
def test_invalid_key_rejected(bad):
    assert post(key=bad).status_code == 422
    assert store.list_all() == []


def test_no_key_is_not_idempotent():
    post(key=None)
    post(key=None)
    assert len(store.list_all()) == 2


def test_reset_clears_keys_with_reports():
    first = post().json()
    store.reset()
    second = post().json()
    assert second["code"] != first["code"] or second["id"] != first["id"]
    assert len(store.list_all()) == 1
