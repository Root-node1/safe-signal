# SafeSignal mobile (Flutter, Android)

Native Android client for reporting. It walks through home, report, support option and review,
then submits to the existing FastAPI endpoint `POST /api/reports` (M.2A). Nothing is saved on the
phone and there are no accounts, analytics, maps or background sync. **A report is only shown as
received after the server returns a reference code**; any failure keeps the draft on screen for
a manual retry. Real-device submission testing is still pending (see below).

Package ID: `com.safesignal.app` · Display name: SafeSignal

## Configuration
The server address is set at build time and is never hard-coded:
```bash
flutter run --dart-define=API_BASE_URL=https://api.example.org
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.0.102:8000   # local dev only
```
With no `API_BASE_URL` the app sends nothing and says so on the review screen. Use HTTPS for any real server. Release and profile builds block plain `http://` (Android default); only debug builds allow it, through `android/app/src/debug/AndroidManifest.xml`. The app declares only the `INTERNET` permission, and certificate checks are never disabled. Never put secrets in `--dart-define`: the value is readable inside the APK.

Step-by-step local phone test (WSL2 networking, exact commands, synthetic data, checklist): [docs/DEVICE_TEST.md](../../docs/DEVICE_TEST.md).

## How submission works
- Endpoint: `POST {API_BASE_URL}/api/reports`, contract in [docs/API.md](../../docs/API.md). Body: `incident`, `timing`, `route`, `area`, `vehicle`, `sacco` (trimmed), `support`, `contactProvided: false`, `consentToShare: false`. No contact details or location are collected or sent.
- Header `Idempotency-Key`: a random UUID per logical report. An unchanged retry (including after Back/Forward or a timeout) reuses it; editing any field gets a new one; it is dropped after success, Done, Quick Exit or a 409. Nothing is retried automatically, and Submit is disabled while a request is in flight.
- Outcomes: a 2xx response with a reference code shows "Report received" and clears the draft. 422, 429 (the wait comes from `Retry-After`), 5xx, malformed replies, timeouts and being offline show a message and keep the draft. Timeout is 10 seconds. Request and response bodies are never logged.
- Quick Exit during a request forgets the draft and key and ignores the reply, but it cannot recall a request already sent: the server may still store that report, and the app never says otherwise.
- Duplicate protection lasts while the same server process runs (in-memory mode) or while the stored keys exist (PostgreSQL mode).

## Prerequisites (WSL2 Ubuntu)
- Flutter stable SDK in `~/flutter` (Linux filesystem, not `/mnt/c`).
- JDK 21 (`JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64`).
- Android SDK in `~/Android/Sdk` (command-line tools, `platform-tools`, `platforms;android-36`,
  `build-tools;36.0.0`), licences accepted, `ANDROID_HOME` set.
- `unzip` on PATH (Flutter needs it).

Add to `~/.bashrc`:
```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$HOME/.local/bin:$HOME/flutter/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH
```
Check with `flutter doctor -v`. The Chrome and Linux-desktop warnings can be ignored.

## Tests
`flutter test` runs 33 tests (fake HTTP transport; no live server) covering the request contract, status-code mapping, timeouts and offline, idempotency-key reuse, double taps, draft preservation, plus the 14 UI tests covering navigation, required-field validation (incident type and support option), data kept when going back, review accuracy, confirmation wording, unavailable options, helplines, Quick Exit, and 2x text scale. The developer has tested the M.1 and M.1.5 screens on a physical Android phone (manual checks only; not a formal accessibility or security audit).

## Support options
Same four values and wording as the web app and API (`private`, `support`, `trusted-contact`, `check-in`). Only the first two can be chosen; the other two are shown as unavailable and in development. Choosing "Show emergency and support phone numbers" lists the national helplines on the confirmation screen as text to dial yourself (the number list is copied from the web app and must be verified before launch). Choosing "Alert someone I trust" is not possible yet and would not send anything automatically.

## Quick Exit
Every reporting screen has an "Exit" button in the top bar. It clears the in-memory draft, returns the app to a blank home screen, and asks Android to close the app (`SystemNavigator.pop`). It does not log or save anything.

Limits: it cannot erase Android's recent-apps preview or screenshots, keyboard suggestions or history, device backups, or anything else outside SafeSignal's memory. Android may keep the app process alive in the background. There is no keyboard shortcut. Tell users to also clear the app from the recents screen if they need to hide that they used it.

## Device testing checklist
M.1/M.1.5 UI checks were completed by the developer. **Real-device submission to a backend (M.2A) has not been tested yet**; add: submit with Wi-Fi on, with the server stopped, in airplane mode, and a retry after a timeout (one report only).
Completed once by the developer on one phone (8 of 8 checks passed). Repeat on other devices and Android versions:
Install the debug APK, then check: all steps end to end; Exit from each screen (draft gone when reopened); TalkBack reads the option cards, errors and the Exit button; Android font size at the largest setting; "Remove animations" on; rotate the phone; open the keyboard on the details fields.


## Common commands (from `apps/mobile`)
```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

## Debug APK
Output: `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk` (about 144 MiB, 150 MB; the first build downloads and compiles a lot and took about 34 minutes here, later builds are much faster)

Install on a phone (USB debugging on). WSL2 cannot see USB devices by default, so either
copy the APK to Windows and use Windows `adb install -r app-debug.apk`, or share the phone
into WSL with `usbipd-win`. You can also copy the file to the phone and open it
(allow "install unknown apps").

## Networking
- `localhost` inside WSL is not the phone's `localhost`; an emulator reaches the host at `10.0.2.2`.
- A physical phone needs the Windows machine's LAN address and a port forward into WSL2 (NAT), plus a firewall rule: see [docs/DEVICE_TEST.md](../../docs/DEVICE_TEST.md). CORS does not apply to the native app.
- Run the API on `0.0.0.0` only for local tests, never expose PostgreSQL, and never put API keys in the app.

## Signing
Debug builds use the default debug key. No release key exists. Never commit `key.properties`
or `*.jks` (already git-ignored).
