# SafeSignal mobile (Flutter, Android)

Offline UI only (M.1 and M.1.5). The app walks through the reporting steps (home, report, support option, review,
confirmation) but **does not submit anything**: it is not connected to the backend, makes no
network requests, stores nothing on the phone and does not log what you type. The confirmation
screen says plainly that the report was not submitted. The release manifest declares no
permissions; Flutter's default debug and profile manifests add `INTERNET` for tooling (hot reload),
so debug APKs do list it. Backend integration (M.2) is pending.

Screens use the same vocabulary as the web app and API (incident types, timing, optional route,
plate, SACCO and place, with the API's length limits). The only required field is what happened.
Details are kept in memory while you move back and forward and are cleared by "Done".

Package ID: `com.safesignal.app` · Display name: SafeSignal

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
`flutter test` runs 14 widget tests covering navigation, required-field validation (incident type and support option), data kept when going back, review accuracy, confirmation wording, unavailable options, helplines, Quick Exit, and 2x text scale. The developer has tested the M.1 and M.1.5 screens on a physical Android phone (manual checks only; not a formal accessibility or security audit).

## Support options
Same four values and wording as the web app and API (`private`, `support`, `trusted-contact`, `check-in`). Only the first two can be chosen; the other two are shown as unavailable and in development. Choosing "Show emergency and support phone numbers" lists the national helplines on the confirmation screen as text to dial yourself (the number list is copied from the web app and must be verified before launch). Choosing "Alert someone I trust" does not and will not send anything automatically.

## Quick Exit
Every reporting screen has an "Exit" button in the top bar. It clears the in-memory draft, returns the app to a blank home screen, and asks Android to close the app (`SystemNavigator.pop`). It does not log or save anything.

Limits: it cannot erase Android's recent-apps preview or screenshots, keyboard suggestions or history, device backups, or anything else outside SafeSignal's memory. Android may keep the app process alive in the background. There is no keyboard shortcut. Tell users to also clear the app from the recents screen if they need to hide that they used it.

## Device testing checklist
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

## Networking (for when the app calls the API)
- `localhost` inside WSL is not the phone's `localhost`.
- Android emulator: the host machine is `10.0.2.2` (not WSL's `localhost`).
- Physical phone: use the Windows/WSL host's LAN IP on the same Wi-Fi, run the backend with
  `--host 0.0.0.0`, allow the port through the Windows firewall, and add that origin to CORS.
  WSL2's own IP changes on restart unless mirrored networking is enabled.
- Never put API keys or secrets in the app; the OpenRouter key stays on the server.

## Signing
Debug builds use the default debug key. No release key exists. Never commit `key.properties`
or `*.jks` (already git-ignored).
