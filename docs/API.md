# API reference (as implemented)

Base URL in development: `http://localhost:8000`. JSON uses camelCase. Interactive docs: `/docs`. This API has not been deployed or load-tested; do not treat any public route as production-ready.

## Endpoints

| Method and path | Auth | Purpose |
|---|---|---|
| `GET /` | none | Returns `{"message": "SafeSignal API running"}` |
| `GET /health/ready` | none | 200 with `{"status":"ok","storage":"memory"\|"postgres"}`; 503 if the database is unreachable |
| `POST /api/reports` | none | Create a report |
| `GET /api/reports` | admin key | List all reports, newest first |
| `PATCH /api/reports/{id}/status` | admin key | Update a report status |
| `POST /api/assistant/chat` | none | Ask the guidance assistant |
| `POST /analyze` | none | Legacy stub returning a fixed response; not real analysis |

## POST /api/reports

Optional header: `Idempotency-Key` (16-64 characters from `A-Za-z0-9_-`, for example a UUID).

Request body:

| Field | Type | Notes |
|---|---|---|
| `incident` | string | `harassment`, `threats`, `touching`, `followed`, `dangerous-driving`, `unsure` (required) |
| `timing` | string | `now` or `after`; default `now`; affects urgency, not stored |
| `route`, `area` | string | up to 120 characters, optional |
| `vehicle` | string | up to 20 characters; stored upper-case |
| `sacco` | string | up to 80 characters |
| `support` | string | `private`, `trusted-contact`, `check-in`, `support` (required) |
| `contactProvided` | boolean | not stored |
| `consentToShare` | boolean | stored; default false |

Response 201: `id` (32-character hex), `code` (`SS-XXXX-XXXX`), `incident`, `urgency` (`high`, `medium`, `low`), `route`, `area`, `vehicle`, `sacco`, `support`, `consentToShare`, `status` (`Received`), `createdAt` (ms since epoch), `acknowledgedAt` (ms or null).

Status codes: 201 created or idempotent replay (same key and payload, original result, no extra rate-limit cost); 409 key reused with a different payload; 422 validation error or malformed key; 429 report rate limit exceeded (`Retry-After` header); 503 database unavailable.

Without a key the request is not idempotent. Default limit: 10 new reports per hour per client address (configurable).

## Admin routes

Send `X-Admin-Key: <value of SAFESIGNAL_ADMIN_KEY>`. If the variable is unset, empty or whitespace, every admin request is denied.

- `GET /api/reports` returns an array of report objects.
- `PATCH /api/reports/{id}/status` with `{"status": "..."}` where status is one of `Received`, `Reviewing`, `Assigned`, `Contacted`, `Referred`, `Action taken`, `Closed`. Sets `acknowledgedAt` the first time the status is not `Received`. 404 if the id does not exist.

Codes: 401 missing or wrong key (identical response when no key is configured); 429 after repeated failures (default 5 per 15 minutes per client address, `Retry-After` set, applies even to a correct key during lockout); 503 database unavailable.

## POST /api/assistant/chat

Request: `{"message": string (1-500 chars), "history": [{"role": "user"|"assistant", "content": string}] (max 6)}`.
Response 200: `{"reply": string, "source": "ai"|"emergency", "disclaimer": string}`. `emergency` replies are fixed text triggered by danger keywords and do not call the provider.

Errors: 422 validation; 429 `{"detail":"rate_limited"}` after 10 requests per minute per client address (no `Retry-After` header); 503 `{"detail":"assistant_unavailable"}` for any provider problem (missing key, authentication, credits, model unavailable, rate limit, timeout, malformed response). Input is redacted before sending; messages are not stored or logged.

## Limitations
- CORS allows only `http://localhost:5173` for GET, POST, PATCH.
- No pagination or filtering on the admin list.
- Admin authentication is one shared static key; there are no users or audit logs.
- Rate limits and, in memory mode, idempotency keys are per process and reset on restart.
- Client identity for limits is the direct connection address; behind a proxy it must be configured (see [SECURITY.md](SECURITY.md)).
