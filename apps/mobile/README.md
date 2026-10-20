# SafeSignal mobile (Flutter, Android)

Early foundation only: a branded welcome screen. **The app is not connected to the backend**,
has no reporting, and makes no network requests. The release manifest declares no permissions; Flutter's default debug and profile manifests add `INTERNET` for tooling (hot reload), so debug APKs do list it.

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
