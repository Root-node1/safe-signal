# Development checklist

Legend: `[x]` done with repository or test evidence; `[ ]` not done or unverified. Notes say what kind of verification exists: implemented (code present), automated (tests pass), device (run on a real device or browser), production (verified on a server). Update this file as work lands.

## 1. Repository and development environment
- [x] Monorepo with `apps/frontend`, `apps/backend`, `apps/mobile`
- [x] `.gitignore` covers `.env`, `venv`, `node_modules`, `__pycache__`, `*.pyc`, signing keys (Flutter `android/.gitignore`)
- [x] Env templates for frontend and backend
- [x] Pushed to `Root-node1/safe-signal` (`main` in sync at last check)
- [x] Flutter 3.47.7, Dart 3.13.5, JDK 21, Android SDK API 36 installed in WSL2
- [ ] Contributor guide (branching, commit style)

## 2. React frontend
- [x] Reporting journey: landing, incident type, details, review and submit, confirmation (implemented; no automated or browser test)
- [x] Lint and production build pass
- [x] Quick Exit via Escape and button (implemented; not browser-tested)
- [x] Focus moved to the new heading and scroll reset on screen change (implemented; not browser-tested)
- [x] Retry-safe submission with stable idempotency key (implemented; API behaviour tested in backend)
- [ ] Browser verification at 320, 375, 768, 1024, 1440 px
- [ ] Screen-reader and keyboard pass on the web app (device verification)
- [ ] Automated frontend tests
- [ ] Update "temporary storage" copy once PostgreSQL is live
- [ ] Real admin UI (current `/#admin` is mock data only)

## 3. FastAPI backend
- [x] `POST /api/reports`, admin list and status update, assistant chat, readiness (implemented)
- [x] Idempotent submission with conflict detection (automated)
- [x] Report and admin rate limiting (automated)
- [x] Fail-closed admin authorisation (automated)
- [x] Generic 503 on database failure (automated)
- [x] Backend suite: 56 pass without database; 64 pass, 0 skipped with test database
- [x] Ruff clean (`ruff check .`)
- [ ] Proxy-aware client identity configured and tested
- [ ] Pagination for admin list
- [ ] Remove or replace legacy `/analyze` stub
- [ ] Production CORS origin configuration

## 4. PostgreSQL
- [x] Schema and versioned migration (`001_init.sql`), explicit `migrate.py` (automated, local PG 18)
- [x] Transactional idempotency and code-collision retry (automated, local PG 18)
- [x] Persistence across pool reinitialisation (automated, local PG 18)
- [x] Production refuses to start without `DATABASE_URL` (automated)
- [ ] Tests in CI with a PostgreSQL service container (CI currently skips them)
- [ ] Verified on PostgreSQL 16 or the chosen server version
- [ ] Least-privilege roles created on the server (production verification)
- [ ] Backup and restore tested (production verification)
- [ ] Retention, deletion and idempotency-key expiry policy decided and implemented

## 5. Security and privacy
- [x] Controls listed in [SECURITY.md](SECURITY.md) implemented
- [ ] Reverse proxy and TLS
- [ ] Rate limiting that survives restarts or multiple workers
- [ ] Dependency and secret scanning
- [ ] Data Protection Act review for real reports
- [ ] Independent security review
- [ ] Published vulnerability contact

## 6. Assistant
- [x] Server-side OpenRouter integration with redaction, bounds, error mapping (automated with mocked provider)
- [x] Web modal with fallback guidance, reset, labelling, focus trap (implemented; not browser-tested)
- [ ] Model id `google/gemma-4-31b-it:free` confirmed against OpenRouter (unverified)
- [ ] One approved live request to verify credentials and model (no live call made so far)
- [ ] Review assistant answers for safety wording

## 7. Flutter Android
- [x] Project `apps/mobile`, id `com.safesignal.app`, Material 3 theme with SafeSignal palette
- [x] Welcome screen with honest status
- [x] M.1 offline reporting UI: home, report (incident type, timing, optional route/plate/SACCO/place), review, confirmation stating the report was NOT submitted (automated widget tests; not yet device-tested)
- [x] M.1 constraints: no permissions, no storage, no logging of details, no network calls
- [x] `flutter analyze`: no issues; `flutter test`: 2 pass
- [x] Debug APK build succeeded (first build about 34 minutes; 144 MiB (150 MB); `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`; package `com.safesignal.app`, label SafeSignal, verified with aapt2; not installed or run anywhere)
- [x] Debug APK rebuilt with M.1.5 (support step and Quick Exit): succeeded in about 36 s, 165 MB (157 MiB), same path, `com.safesignal.app`; not installed or run on a device yet
- [x] Debug APK (M.1.5) installed and launched on a physical Android phone (developer-confirmed)
- [x] Developer-confirmed device checks (8 of 8): reporting flow, navigation, support selection, review, Quick Exit, larger text, rotation, keyboard behaviour, TalkBack where available. This is manual developer testing, not a formal accessibility or security audit
- [ ] Broader device coverage (more phones and Android versions) and formal accessibility review
- [x] M.1.5 support-option step with the four API values (two unavailable, as on the web); selection kept on back navigation and shown on review (automated)
- [x] M.1.5 Quick Exit button on report, options, review and confirmation screens: clears the in-memory draft and calls the Android close request (automated with a mocked platform channel; real Android behaviour not device-tested; does not clear recents, screenshots or system traces)
- [ ] Swahili copy (not decided)
- [ ] M.2: API client with idempotency keys, internet permission in release manifest, real submission and error states (pending)
- [ ] API client with idempotency (not connected to backend)
- [ ] Assistant screen
- [ ] Android internet permission in release manifest (needed when networking is added)
- [ ] Release signing key held outside Git; signed release build

## 8. Automated testing
- [x] Backend unit and API tests
- [x] PostgreSQL integration tests (run locally only)
- [x] Flutter widget tests (14: navigation, validation, back-navigation data retention, review accuracy, confirmation wording, draft cleared on Done, 2x text scale)
- [ ] Frontend tests
- [ ] End-to-end test of the report journey
- [ ] Load test of report and assistant endpoints

## 9. CI/CD
- [x] GitHub Actions: frontend lint and build; backend ruff and pytest
- [ ] CI for Flutter analyze and test
- [ ] CI PostgreSQL service
- [ ] Automated deployment (not started)

## 10. VPS deployment
- [ ] Server provisioned and hardened
- [ ] PostgreSQL installed, roles and backups configured
- [ ] Backend as a service, single worker, readiness monitored
- [ ] Reverse proxy, TLS, trusted forwarded headers
- [ ] Production environment variables set (admin key, database, OpenRouter)
- [ ] Web build served with `VITE_PROTOTYPE=false`

## 11. Documentation
- [x] README, ARCHITECTURE, DEVELOPMENT, API, SECURITY, ROADMAP, CHECKLIST
- [x] DATABASE.md and mobile README
- [ ] `Doc.md` concept paper reconciled with the current system
- [ ] `apps/frontend/README.md` replaced (still the Vite template)
- [ ] Privacy notice for users

## 12. MVP release readiness
- [ ] Web verified in browsers and with assistive technology
- [ ] Persistent storage verified on the target server
- [ ] Admin access path decided (real authentication)
- [ ] Android APK verified on devices
- [ ] Retention and legal review complete
- [ ] Pilot plan and safeguards agreed

## Next priorities
1. M.2A: connect the Flutter app to the backend (see Flutter section; pending).
2. Run the manual browser and accessibility pass on the web app.
3. Add a PostgreSQL service to CI so the integration tests run on every push.
4. Decide admin authentication and the retention policy.
5. Build the Flutter reporting journey, then connect it to the API.
