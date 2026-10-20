# Development guide

## Prerequisites
- Python 3.14 (CI uses 3.14), Node.js 22, git.
- Optional: PostgreSQL (16 or later) for persistence tests.
- Mobile: Flutter 3.47.x (Dart 3.13.x), JDK 21, Android SDK API 36. See [apps/mobile/README.md](../apps/mobile/README.md).

## WSL2 notes
- Keep the repo, Flutter and the Android SDK on the Linux filesystem (`~`), not `/mnt/c`.
- `localhost` in WSL is not a phone's or emulator's `localhost`; see the networking section of the mobile README.
- WSL2 cannot see USB phones without `usbipd-win`; use Windows `adb` to install APKs.

## Environment files
Copy the templates and fill them in locally; never commit real `.env` files.
```bash
cp apps/backend/.env.example apps/backend/.env
cp apps/frontend/.env.example apps/frontend/.env
```
Backend variables of note: `SAFESIGNAL_ADMIN_KEY` (admin routes are denied while it is empty), `OPENROUTER_API_KEY`/`OPENROUTER_BASE_URL`/`OPENROUTER_MODEL`, `DATABASE_URL`, `SAFESIGNAL_ENV`, and the rate-limit settings documented in the template.

## Backend
```bash
cd apps/backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements-dev.txt
uvicorn main:app --reload --port 8000
pytest -q
ruff check .
```
Interactive API docs are served by FastAPI at `/docs` while running locally.

## PostgreSQL (optional)
Create a database and roles per [DATABASE.md](../apps/backend/DATABASE.md), then `python migrate.py`. Integration tests run only when `TEST_DATABASE_URL` points at a database whose name ends in `_test`; otherwise that test module is skipped.

## Frontend
```bash
cd apps/frontend
npm ci
npm run dev       # http://localhost:5173
npm run lint
npm run build
```
Without `VITE_API_URL` the client calls `http://localhost:8000`. The backend CORS allow-list only contains `http://localhost:5173`.

## Flutter
```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug    # apps/mobile/build/app/outputs/flutter-apk/app-debug.apk
```
The first build downloads Gradle and Android components and can take many minutes.

## Common problems
- Flutter reports "Missing unzip": install `unzip` (or place it on PATH) and rerun.
- `flutter doctor` warns about Chrome or Linux desktop: not needed for Android builds.
- Admin routes return 401 or 429: set `SAFESIGNAL_ADMIN_KEY` and send `X-Admin-Key`; five failures lock the client out for 15 minutes.
- Assistant returns 503: the OpenRouter key or model is unset or rejected; the web UI then shows built-in guidance.
- Database requests return 503: check `DATABASE_URL` and that PostgreSQL is reachable; `/health/ready` reports it.
