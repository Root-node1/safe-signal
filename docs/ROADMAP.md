# Roadmap

Phases are ordered by dependency, not dates. They are plans, not commitments. Progress is tracked in [CHECKLIST.md](CHECKLIST.md).

1. **Web runtime and accessibility verification.** Manual browser pass at 320-1440 px, keyboard and screen-reader checks, Quick Exit and assistant focus behaviour, retry-after-timeout scenarios, reduced motion. Update storage copy once PostgreSQL is live.
2. **PostgreSQL production configuration.** Roles, `DATABASE_URL`, migration run, backup and restore test, CI service container for the integration tests.
3. **Flutter reporting journey (done: M.1 and M.1.5; offline, developer-tested on one phone).** Native screens mirroring the web flow (incident type, details, next step, confirmation), Quick Exit equivalent, offline and failure states.
4. **Flutter backend integration (done for local testing: M.2A/M.2B; in-memory backend, one phone).** API client with idempotency keys, timeouts and retries, Android internet permission, base URL configuration per build.
5. **Flutter assistant integration.** Backend assistant with fallback guidance and clear AI labelling.
6. **Android device testing (started: one phone, 7 manual checks for submission and 8 for UI; more devices, PostgreSQL storage and formal accessibility review outstanding).** Physical devices and several screen sizes, text scaling, TalkBack, low connectivity.
7. **Release APK signing.** Signing key held outside Git, versioning, signed release build.
8. **Deployment and operational hardening.** VPS, reverse proxy and TLS, single worker, systemd, monitoring, log hygiene, CORS and header review.
9. **Privacy and data retention.** Decide and implement retention, deletion and key expiry; privacy notice; legal review.
10. **Pilot testing.** Limited, supervised pilot with explicit safeguards, after the items above.

Not planned until justified by evidence: public maps or alerts, report corroboration, analytics, push notifications, accounts.
