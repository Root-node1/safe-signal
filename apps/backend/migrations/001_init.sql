-- Values mirror Literal types in schemas.py (tests/test_db_config.py guards against drift).
CREATE TABLE reports (
    id               uuid PRIMARY KEY,
    code             text NOT NULL,
    incident         text NOT NULL CHECK (incident IN
        ('harassment','threats','touching','followed','dangerous-driving','unsure')),
    urgency          text NOT NULL CHECK (urgency IN ('high','medium','low')),
    route            text NOT NULL DEFAULT '' CHECK (char_length(route) <= 120),
    area             text NOT NULL DEFAULT '' CHECK (char_length(area) <= 120),
    vehicle          text NOT NULL DEFAULT '' CHECK (char_length(vehicle) <= 20),
    sacco            text NOT NULL DEFAULT '' CHECK (char_length(sacco) <= 80),
    support          text NOT NULL CHECK (support IN
        ('private','trusted-contact','check-in','support')),
    consent_to_share boolean NOT NULL DEFAULT false,
    status           text NOT NULL DEFAULT 'Received' CHECK (status IN
        ('Received','Reviewing','Assigned','Contacted','Referred','Action taken','Closed')),
    created_at       timestamptz NOT NULL DEFAULT now(),
    acknowledged_at  timestamptz,
    CONSTRAINT reports_code_key UNIQUE (code)
);
CREATE INDEX reports_created_at_idx ON reports (created_at DESC);

CREATE TABLE idempotency_keys (
    key          text PRIMARY KEY CHECK (key ~ '^[A-Za-z0-9_-]{16,64}$'),
    payload_hash text NOT NULL,
    report_id    uuid NOT NULL REFERENCES reports (id) ON DELETE CASCADE,
    created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idempotency_keys_report_idx ON idempotency_keys (report_id);
