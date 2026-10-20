# SafeSignal

SafeSignal is an early-stage (MVP) incident-reporting tool for commuters on Kenyan public transport (matatus and boda-bodas). A commuter can describe what happened, optionally add route, vehicle and operator details, and submit it without an account. A general-guidance assistant explains how reporting works and offers basic safety tips.

Status: prototype under active development. It has not been deployed, security-audited, or tested with real users.

## What it does today

- Web reporting journey: choose an incident type, add optional details, submit, receive a reference code.
- Quick Exit (Escape key or Exit button) that leaves the app for a neutral page.
- FastAPI backend that stores reports in memory (development) or PostgreSQL (persistent), with idempotent submission, rate limiting and a key-protected admin API.
- A guidance assistant, served through the backend (OpenRouter), with redaction of obvious identifiers and fixed emergency wording.
- A Flutter Android app that walks through the reporting steps (with a Quick Exit button) and submits to the same API as the web app when built with an `API_BASE_URL`. It saves nothing on the phone. Submission has been unit-tested with a fake transport but not yet on a device.

## What it does not do

- It does not contact emergency services, police or anyone else. In immediate danger, call 999 or 112.
- It does not verify, corroborate or review reports, and it shows no live alerts, maps or incident counts.
- It cannot tell users whether a route, vehicle or stage is safe.
- The admin screen in the web app shows mock data only; there is no real admin dashboard or sign-in.
- The Flutter app has no assistant, maps, accounts or background sync, and shows no reports to the user beyond a reference code.
- No guarantee of anonymity or confidentiality is made.

## Repository layout

```
apps/frontend   React + Vite + TypeScript + Tailwind CSS v4 web app
apps/backend    FastAPI service, PostgreSQL store, migrations, tests
apps/mobile     Flutter Android app (offline UI only)
docs/           Architecture, development, API, security, roadmap, checklist
```

## Quick start

Backend (Python 3.14 venv in `apps/backend/venv`):
```bash
cd apps/backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements-dev.txt
cp .env.example .env        # then edit; never commit .env
uvicorn main:app --reload   # http://localhost:8000
```

Web:
```bash
cd apps/frontend
npm ci
cp .env.example .env
npm run dev                 # http://localhost:5173
```

`./run.sh` starts both. The backend uses in-memory storage unless `DATABASE_URL` is set. Android setup and APK build: see [apps/mobile/README.md](apps/mobile/README.md). Full instructions: [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## Tests

```bash
cd apps/backend && pytest -q          # 56 pass; PostgreSQL tests skip without TEST_DATABASE_URL
cd apps/frontend && npm run lint && npm run build
cd apps/mobile && flutter analyze && flutter test
```

The last full backend run, with the PostgreSQL integration tests enabled against a local PostgreSQL 18 test database, was 64 passed and 0 skipped. There are no automated frontend tests, and no browser or device testing has been done.

## Security and privacy in brief

Reports can contain sensitive text (route, vehicle plate, SACCO, place). Admin access uses a single shared key and fails closed when unset. Report and admin attempts are rate limited per process. The assistant never receives report data and redacts obvious phone numbers, plates, emails and coordinates. See [docs/SECURITY.md](docs/SECURITY.md) for controls and the work still required.

## Documentation

| Document | Contents |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Components, data flow, idempotency, storage modes |
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | Local setup, commands, troubleshooting |
| [docs/API.md](docs/API.md) | HTTP endpoints as implemented |
| [docs/SECURITY.md](docs/SECURITY.md) | Controls, limits, reporting vulnerabilities |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Planned phases |
| [docs/CHECKLIST.md](docs/CHECKLIST.md) | Progress tracker |
| [apps/backend/DATABASE.md](apps/backend/DATABASE.md) | PostgreSQL setup, migrations, backups |
| [apps/mobile/README.md](apps/mobile/README.md) | Flutter and Android |
| [Doc.md](Doc.md) | Original concept paper; aspirational, not a description of the current system |

## Known limitations

- Production readiness is unverified: no deployment, backup restore test, load test or external review.
- Storage is temporary unless PostgreSQL is configured, and the web UI copy still describes storage as temporary.
- Rate limiting and idempotency keys are per process; run a single worker.
- The assistant's OpenRouter model id could not be confirmed against the public model list and is configurable.
- Data retention and deletion policy is not yet decided.

## License

MIT. See [LICENSE](LICENSE).
