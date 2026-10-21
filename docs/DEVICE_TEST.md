# Android device test against a local backend (M.2B)

Goal: submit synthetic reports from a physical phone to the FastAPI backend running in WSL2, with nothing public and no database involved. Use synthetic data only.

## Results so far
The developer ran 7 of these checks on a Redmi A5 against the in-memory backend and reported all passing: normal submit with reference code, airplane mode, server stopped, retry after restart, Quick Exit, rapid taps, and no report content in the inspected server logs. Not reported: the on-device freeze (timeout) retry, the `adb logcat` and phone-storage checks, TalkBack, and any run against PostgreSQL.

The timeout retry is covered by an automated test with the real client and a real backend process (`SAFESIGNAL_BACKEND_IT=1 flutter test test/integration` from `apps/mobile`): it freezes the server so the client times out, resumes it so the first request is accepted late, then retries unchanged and expects the same key, the original reference code and exactly one stored report.

## Findings for this machine (checked, nothing changed)
- WSL2 uses NAT (no `.wslconfig`; WSL address 192.168.61.12, Windows Wi-Fi 192.168.0.102, network profile "Public"). A phone cannot reach WSL directly; Windows must forward a port.
- Backend storage: leave `DATABASE_URL` unset so the API runs in **in-memory mode**. No database is touched and everything disappears when the server stops. A system PostgreSQL 18 is listening on 127.0.0.1:5432; its contents were not inspected and it must not be used for this test. Never expose 5432.
- The backend does not read `apps/backend/.env` by itself; only variables exported in the shell apply.
- `/health/ready` was checked locally: `{"status":"ok","storage":"memory"}`. Admin routes return 401 without a key.
- Addresses can change (DHCP, WSL restarts). Re-check them before each session.

## 1. Start the backend (WSL terminal A)
```bash
cd ~/safe-signal/apps/backend
export SAFESIGNAL_ADMIN_KEY=$(openssl rand -hex 16)   # lives only in this shell
export SAFESIGNAL_REPORT_RATE_LIMIT=40                # default is 10 per hour per address
env -u DATABASE_URL -u SAFESIGNAL_ENV venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
```
In terminal B check `curl http://127.0.0.1:8000/health/ready` shows `"storage":"memory"`. Stop the server and restart it (or wait) to clear reports and rate limits.

## 2. Let the phone reach it (Windows; needs your confirmation, run as Administrator)
Use a home or trusted Wi-Fi, not a guest or public network (those often isolate devices). Forward only on the Wi-Fi address and allow only the local subnet:
```powershell
netsh interface portproxy add v4tov4 listenaddress=192.168.0.102 listenport=8000 connectaddress=192.168.61.12 connectport=8000
New-NetFirewallRule -DisplayName "SafeSignal dev API (temp)" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow -Profile Public -RemoteAddress 192.168.0.0/24
```
Remove both when finished:
```powershell
netsh interface portproxy delete v4tov4 listenaddress=192.168.0.102 listenport=8000
Remove-NetFirewallRule -DisplayName "SafeSignal dev API (temp)"
```
Alternative with no Windows changes: USB cable, `adb reverse tcp:8000 tcp:8000`, and use `http://127.0.0.1:8000` as the URL.

On the phone's browser open `http://192.168.0.102:8000/health/ready`. You should see the JSON above. If not, fix this before building.

## 3. Build and install the debug APK (WSL)
```bash
cd ~/safe-signal/apps/mobile
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 ANDROID_HOME=$HOME/Android/Sdk
export PATH=$HOME/.local/bin:$HOME/flutter/bin:$PATH
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.0.102:8000
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`. Plain HTTP works only because this is a debug build; TLS verification is untouched and release builds still block cleartext. Do not use this APK or URL for anything but local tests.

## 4. Synthetic data
Route `ZZTEST Route`, plate `KZZ 000Z`, SACCO `ZZTEST Sacco`, place `ZZTEST Stage`. Choose any incident type. Count stored reports (terminal B):
```bash
curl -s -H "X-Admin-Key: $SAFESIGNAL_ADMIN_KEY" http://127.0.0.1:8000/api/reports | python3 -c "import sys,json; r=json.load(sys.stdin); print(len(r), [x['code'] for x in r])"
```
(export the same `SAFESIGNAL_ADMIN_KEY` value in terminal B, or read it with `echo` in terminal A.)

## 5. Checklist (tick as you go)
- [ ] Phone browser reaches `/health/ready` over Wi-Fi.
- [ ] Normal submit: app shows "Report received" and a code. Count is exactly 1 and the code matches.
- [ ] Press Done, reopen the form: all fields empty. Close and reopen the app: still empty.
- [ ] Airplane mode, Submit: "Could not reach SafeSignal"; details still on screen; count unchanged. Turn Wi-Fi back on, Submit: success, count +1.
- [ ] Stop the server (Ctrl+C in terminal A), Submit: same offline message; restart the server and retry: success (the earlier report is gone because storage is in memory, which is expected).
- [ ] Uncertain timeout and key reuse. Find the server PID (`pgrep -f "uvicorn main:app"`), then `kill -STOP <pid>`. On the phone tap Submit. After about 10 seconds the app says the server took too long and your details are still there. Run `kill -CONT <pid>` (the delayed request is now processed). Tap Submit report again. Expect "Report received" and **count increased by exactly 1**, with the code matching the report the server stored. No duplicate.
- [ ] Edit after a failure: repeat the freeze, change the route text, then resume and submit. A new key is used, so this is a different report (count may be +2 if the first was also processed). This is intended.
- [ ] Quick Exit during submission: freeze the server, tap Submit, tap Exit within 10 seconds. The app closes and reopens blank. Resume the server: the request that was already sent is still processed, so the count may rise by 1. Quick Exit cannot retract a request already transmitted, and the app never says it did.
- [ ] Rapid taps: double-tap Submit report quickly. Count rises by 1 only.
- [ ] Rate limit: set `SAFESIGNAL_REPORT_RATE_LIMIT=2`, restart, submit three times: the third shows the "too many reports, wait" message with a time.
- [ ] Logs: on Windows run `adb logcat -d` and search for `ZZTEST` and `KZZ`; nothing should match. The server's terminal shows only lines like `POST /api/reports 201`, never report text.
- [ ] Nothing stored on the phone: `adb shell run-as com.safesignal.app grep -rl ZZTEST .` finds nothing.
- [ ] TalkBack announces the progress state, errors and the new "Report received" heading (optional).

## 6. Clean up
Stop uvicorn, remove the port proxy and firewall rule, and uninstall or replace the test APK. Reports are already gone (in-memory).

## Known limits
- Idempotency protection lasts while the same server process runs.
- A Quick Exit during a request forgets the key; submitting the same text again afterwards makes a new report.
- Rate limits are per client address; behind the Windows port proxy all phone requests look like one address.
