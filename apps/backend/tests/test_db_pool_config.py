"""Tests for db._pool_config(): production vs development settings and Neon readiness.

These exercise the configuration logic without opening a real database connection.
"""

import db


def test_dev_config_no_sslmode():
    config = db._pool_config()
    assert config["timeout"] == 5
    assert config["kwargs"] == {"connect_timeout": 5}
    assert "sslmode" not in config["kwargs"]
    assert "max_lifetime" not in config


def test_production_config_enforces_ssl_and_longer_timeout(monkeypatch):
    monkeypatch.setenv("SAFESIGNAL_ENV", "production")
    config = db._pool_config()
    assert config["timeout"] == 15
    assert config["max_lifetime"] == 1800
    assert config["kwargs"]["sslmode"] == "require"
    assert config["kwargs"]["connect_timeout"] == 15


def test_production_config_pool_size_from_env(monkeypatch):
    monkeypatch.setenv("SAFESIGNAL_ENV", "production")
    monkeypatch.setenv("SAFESIGNAL_DB_POOL_MAX", "10")
    config = db._pool_config()
    assert config["max_size"] == 10
    assert config["min_size"] == 1


def test_pool_size_clamped_to_range(monkeypatch):
    monkeypatch.delenv("SAFESIGNAL_ENV", raising=False)
    monkeypatch.setenv("SAFESIGNAL_DB_POOL_MAX", "100")
    config = db._pool_config()
    assert config["max_size"] == 20

    monkeypatch.setenv("SAFESIGNAL_DB_POOL_MAX", "0")
    config = db._pool_config()
    assert config["max_size"] == 1

    monkeypatch.setenv("SAFESIGNAL_DB_POOL_MAX", "-5")
    config = db._pool_config()
    assert config["max_size"] == 1


def test_pool_size_falls_back_on_invalid(monkeypatch):
    monkeypatch.setenv("SAFESIGNAL_DB_POOL_MAX", "not-a-number")
    config = db._pool_config()
    assert config["max_size"] == 5


def test_production_config_does_not_exceed_max(monkeypatch):
    monkeypatch.setenv("SAFESIGNAL_ENV", "production")
    monkeypatch.setenv("SAFESIGNAL_DB_POOL_MAX", "9999")
    config = db._pool_config()
    assert config["max_size"] <= 20
