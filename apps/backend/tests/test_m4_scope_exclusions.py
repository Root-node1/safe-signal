"""M.4 scope audit: automated re-checks for the exclusions in requirements.md § 7.

Why this file exists
--------------------
`docs/M4_SCOPE_CHECKLIST.md` records, by hand, how each exclusion (XR-1 … XR-16) and
each privacy requirement was checked against the repository. A hand-written checklist
goes stale the moment the code changes. The checks below are the machine-checkable part
of that audit: they repeat the same searches and fail if the repository drifts away
from the state the checklist documents.

Scope
-----
* Pure file and dependency inspection: no database, no network, no running server.
* The HTTP checks use the backend's own TestClient and are skipped when the backend
  dependencies are not installed.
* Nothing here changes application behaviour. The file only reads.

Run
---
    pytest -q tests/test_m4_scope_exclusions.py
"""

import json
import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[3]
BACKEND = ROOT / "apps" / "backend"
FRONTEND = ROOT / "apps" / "frontend"
MOBILE = ROOT / "apps" / "mobile"
DOCS = ROOT / "docs"

SKIP_DIRS = {
    ".git",
    ".dart_tool",
    "build",
    "dist",
    "node_modules",
    "venv",
    "__pycache__",
    ".pytest_cache",
    ".ruff_cache",
}

# The dependency sets M.4 was approved against. A new entry means a new dependency.
FRONTEND_DEPS = {"@tailwindcss/vite", "react", "react-dom", "tailwindcss"}
MOBILE_DEPS = {"flutter", "flutter_localizations", "http", "intl"}
BACKEND_RUNTIME_DEPS = {"fastapi", "pydantic", "starlette", "uvicorn", "psycopg"}
BACKEND_DEV_DEPS = {"httpx", "pytest", "ruff"}

# The reports table exactly as documented in docs/PRIVACY.md § 6.
REPORT_COLUMNS = {
    "id",
    "code",
    "incident",
    "urgency",
    "route",
    "area",
    "vehicle",
    "sacco",
    "support",
    "consent_to_share",
    "status",
    "created_at",
    "acknowledged_at",
}
IDEMPOTENCY_COLUMNS = {"key", "payload_hash", "report_id", "created_at"}

# Words that must never reach a log line: report content or identifiers.
FORBIDDEN_LOG_WORDS = (
    "route",
    "area",
    "vehicle",
    "sacco",
    "message",
    "content",
    "payload",
    "code",
    "key",
    "phone",
)


# --------------------------------------------------------------------------- helpers


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


SELF = Path(__file__).resolve()


def source_files(root: Path, suffixes: tuple[str, ...]) -> list[Path]:
    out: list[Path] = []
    for path in sorted(root.rglob("*")):
        if not path.is_file() or path.suffix not in suffixes:
            continue
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        if path.resolve() == SELF:  # this file names the things it looks for
            continue
        out.append(path)
    return out


def grep(root: Path, suffixes: tuple[str, ...], pattern: str) -> list[tuple[Path, int, str]]:
    """Return (file, line number, line) for every match of `pattern`."""
    hits: list[tuple[Path, int, str]] = []
    for path in source_files(root, suffixes):
        for number, line in enumerate(read(path).splitlines(), start=1):
            if re.search(pattern, line, re.IGNORECASE):
                hits.append((path, number, line))
    return hits


def table_columns(sql: str, table: str) -> set[str]:
    match = re.search(rf"CREATE TABLE {table}\s*\((.*?)\n\);", sql, re.IGNORECASE | re.DOTALL)
    assert match, f"table {table} not found in the schema"
    columns: set[str] = set()
    for line in match.group(1).splitlines():
        column = re.match(
            r"^([a-z_][a-z0-9_]*)\s+(text|uuid|timestamptz|boolean|bigint|integer|int)\b",
            line.strip(),
            re.IGNORECASE,
        )
        if column:
            columns.add(column.group(1).lower())
    return columns


def table_names(sql: str) -> set[str]:
    return {name.lower() for name in re.findall(r"CREATE TABLE\s+(\w+)", sql, re.IGNORECASE)}


def pubspec_dependencies(text: str) -> set[str]:
    names: set[str] = set()
    in_block = False
    for raw in text.splitlines():
        line = raw.split("#")[0].rstrip()
        if not line.strip():
            continue
        if not line.startswith((" ", "\t")):
            in_block = line.strip() == "dependencies:"
            continue
        if in_block:
            key = re.match(r"^ {2}([A-Za-z_][A-Za-z0-9_]*):", raw)
            if key:
                names.add(key.group(1))
    return names


def requirements_names(text: str) -> set[str]:
    names: set[str] = set()
    for raw in text.splitlines():
        line = raw.split("#")[0].strip()
        if not line or line.startswith("-"):
            continue
        names.add(re.split(r"[=<>\[]", line)[0].strip().lower())
    return names


def backend_app():
    pytest.importorskip("fastapi", reason="backend dependencies are not installed")
    from main import app

    return app


def iter_api_routes(app):
    """Yield (path, methods, route) for every route, including included routers."""
    for route in app.routes:
        if getattr(route, "path", None) and getattr(route, "methods", None):
            yield route.path, route.methods, route
            continue
        original = getattr(route, "original_router", None)
        if original is None:
            continue
        prefix = getattr(original, "prefix", "")
        for sub in original.routes:
            path = f"{prefix}{getattr(sub, 'path', '')}"
            yield path, getattr(sub, "methods", set()), sub


def requires_admin(route) -> bool:
    return any(
        getattr(dependency.call, "__name__", "") == "require_admin"
        for dependency in route.dependant.dependencies
    )


def code_only(line: str) -> str:
    """Strip a trailing comment so that a comment cannot look like a log payload."""
    return line.split("#", 1)[0]


# ------------------------------------------------------------------- XR-1 … XR-16


def test_xr1_no_public_report_listing():
    """XR-1: no public report listing. The only GET on /api/reports is admin-gated."""
    app = backend_app()
    listing = [(p, m, r) for p, m, r in iter_api_routes(app) if p.startswith("/api/reports")]
    assert listing, "the reports router disappeared"
    for path, methods, route in listing:
        if "GET" in methods:
            assert requires_admin(route), f"{path} lists reports without an admin gate"


def test_xr1_no_public_report_listing_functionally():
    """XR-1, end to end: an unauthenticated listing is refused."""
    pytest.importorskip("fastapi", reason="backend dependencies are not installed")
    from fastapi.testclient import TestClient

    from main import app

    client = TestClient(app)
    assert client.get("/api/reports").status_code == 401


def test_xr1_no_lookup_by_reference_code():
    """XR-1 / PR-9.1: no route resolves a reference code to a report."""
    app = backend_app()
    for path, _methods, _route in iter_api_routes(app):
        assert "{code}" not in path, f"{path} looks up a report by code"
        assert "lookup" not in path.lower(), f"{path} looks like a lookup route"


def test_xr2_analyze_stub_not_wired_into_a_client():
    """XR-2: the /analyze prototype stub is not called by any client."""
    for root in (FRONTEND / "src", MOBILE / "lib"):
        assert not grep(root, (".ts", ".tsx", ".dart"), r"/analyze"), (
            f"a client calls the /analyze stub: {root}"
        )


def test_xr3_no_push_notification_dependency():
    """XR-3: no push-notification SDK in either client."""
    web = json.loads(read(FRONTEND / "package.json"))
    names = set(web["dependencies"]) | set(web.get("devDependencies", {}))
    assert not names & {"firebase", "firebase_messaging", "@onesignal/react-onesignal"}, names
    mobile = pubspec_dependencies(read(MOBILE / "pubspec.yaml"))
    assert not mobile & {"firebase_messaging", "flutter_local_notifications", "onesignal"}, mobile


def test_xr4_no_background_location_permission():
    """XR-4 / PR-4.3: the Android manifest asks for internet access only."""
    manifest = read(MOBILE / "android/app/src/main/AndroidManifest.xml")
    permissions = set(re.findall(r'uses-permission[^>]*android:name="([^"]+)"', manifest))
    assert permissions == {"android.permission.INTERNET"}, permissions
    assert "service" not in manifest.lower(), "a background service is declared"


def test_xr5_no_mediapipe_or_vision_dependency():
    """XR-5: no MediaPipe or on-device vision dependency."""
    web = json.loads(read(FRONTEND / "package.json"))
    names = set(web["dependencies"]) | set(web.get("devDependencies", {}))
    assert not any("mediapipe" in name.lower() for name in names), names
    mobile = pubspec_dependencies(read(MOBILE / "pubspec.yaml"))
    assert not any("mediapipe" in name.lower() for name in mobile), mobile


def test_xr6_no_firebase_or_crashlytics():
    """XR-6: no Firebase, Crashlytics or analytics service."""
    web = json.loads(read(FRONTEND / "package.json"))
    names = set(web["dependencies"]) | set(web.get("devDependencies", {}))
    assert not any(name.lower().startswith("firebase") for name in names), names
    mobile = pubspec_dependencies(read(MOBILE / "pubspec.yaml"))
    assert not any("firebase" in name.lower() or "crashlytics" in name.lower() for name in mobile), mobile
    assert not list(MOBILE.rglob("google-services.json"))


def test_xr7_no_account_creation():
    """XR-7: no sign-in, registration or account model anywhere."""
    app = backend_app()
    for path, _methods, _route in iter_api_routes(app):
        lowered = path.lower()
        assert not any(word in lowered for word in ("login", "logout", "signup", "register", "account")), path
    for root, suffixes in ((FRONTEND / "src", (".ts", ".tsx")), (MOBILE / "lib", (".dart",))):
        assert not grep(root, suffixes, r"\b(password|passwd|signIn|sign_in|createAccount)\b")
    schema = read(BACKEND / "schemas.py")
    for field in ("password", "email", "username", "user_name"):
        assert not re.search(rf"\b{field}\s*:", schema), field


def test_xr8_admin_screen_uses_mock_data_only():
    """XR-8 / SR-2.2: the prototype admin screen renders mock data and is gated."""
    screen = read(FRONTEND / "src/screens/AdminScreen.tsx")
    assert "MOCK_REPORTS" in screen
    assert not re.search(r"\bfetch\s*\(|XMLHttpRequest|axios", screen)
    assert not grep(FRONTEND / "src/admin", (".ts", ".tsx"), r"\bfetch\s*\(|axios")
    prototype = read(FRONTEND / "src/lib/prototype.ts")
    assert "VITE_PROTOTYPE" in prototype, "the prototype gate is gone"


def test_xr9_no_dispatch_service():
    """XR-9: nothing in the stack can send an SMS, place a call or dispatch anyone."""
    web = json.loads(read(FRONTEND / "package.json"))
    names = set(web["dependencies"]) | set(web.get("devDependencies", {}))
    assert not names & {"twilio", "@aws-sdk/client-sns"}, names
    mobile = pubspec_dependencies(read(MOBILE / "pubspec.yaml"))
    assert not mobile & {"sms_advanced", "flutter_sms", "url_launcher"}, mobile
    assert not grep(MOBILE / "lib", (".dart",), r"SmsManager|sendTextMessage|twilio")
    assert not grep(MOBILE / "android", (".kt",), r"SmsManager|sendTextMessage")


def test_xr10_no_map_view():
    """XR-10: no map view, map SDK or incident map."""
    web = json.loads(read(FRONTEND / "package.json"))
    names = set(web["dependencies"]) | set(web.get("devDependencies", {}))
    assert not any(
        name.lower().startswith(("mapbox", "leaflet", "react-leaflet", "google-map"))
        or name.lower() in {"react-map-gl", "maplibre-gl"}
        for name in names
    ), names
    mobile = pubspec_dependencies(read(MOBILE / "pubspec.yaml"))
    assert not any(name.lower().startswith("map") or name.lower().startswith("google_maps") for name in mobile), mobile
    assert not grep(FRONTEND / "src", (".ts", ".tsx"), r"<Map|MapContainer|react-leaflet")
    assert not grep(MOBILE / "lib", (".dart",), r"GoogleMap|FlutterMap|MapController")


def test_xr11_no_cloud_messaging():
    """XR-11: no Cloud Messaging or push transport."""
    mobile = pubspec_dependencies(read(MOBILE / "pubspec.yaml"))
    assert not any("messaging" in name.lower() for name in mobile), mobile
    assert not grep(BACKEND, (".py",), r"firebase|fcm|APNs|sendPush|push_notification")


def test_xr12_backend_dependency_list_unchanged():
    """XR-12: the backend dependency list is the approved one."""
    runtime = requirements_names(read(BACKEND / "requirements.txt"))
    assert runtime == BACKEND_RUNTIME_DEPS, runtime
    dev = requirements_names(read(BACKEND / "requirements-dev.txt"))
    assert dev == BACKEND_DEV_DEPS, dev


def test_xr13_no_column_added_to_reports():
    """XR-13 / PR-11.2: no column was added to `reports`."""
    sql = read(BACKEND / "migrations/001_init.sql")
    assert table_columns(sql, "reports") == REPORT_COLUMNS
    assert table_columns(sql, "idempotency_keys") == IDEMPOTENCY_COLUMNS


def test_xr14_no_staff_or_operator_table():
    """XR-14: no table for staff, operators or admin identities."""
    sql = read(BACKEND / "migrations/001_init.sql")
    assert table_names(sql) == {"reports", "idempotency_keys"}, table_names(sql)


def test_xr15_no_admin_route_exposes_content_to_non_admins():
    """XR-15 / SR-1.2: only POST is public on /api/reports."""
    app = backend_app()
    for path, methods, route in iter_api_routes(app):
        if not path.startswith("/api/reports"):
            continue
        if "POST" in methods:
            continue
        assert requires_admin(route), f"{path} exposes report content without an admin gate"


def test_xr16_no_mobile_assistant_screen():
    """XR-16: the assistant screen is not part of the Android app."""
    assert not list((MOBILE / "lib").rglob("*assistant*"))
    assert not grep(MOBILE / "lib", (".dart",), r"/api/assistant|askAssistant")


# ------------------------------------------------------------------ privacy rules


def test_pr12_no_phone_or_contact_field_reaches_the_server():
    """PR-1.2 / PR-4.2: no phone number, e-mail or name is accepted or stored."""
    schema = read(BACKEND / "schemas.py")
    for field in ("phone", "telephone", "email", "full_name", "id_number"):
        assert not re.search(rf"\b{field}\s*:", schema), field
    sql = read(BACKEND / "migrations/001_init.sql")
    assert "contact_provided" not in table_columns(sql, "reports")
    assert "contact_provided" not in read(BACKEND / "schemas.py").split("class ReportOut")[1]


def test_pr31_no_consent_control_in_either_client():
    """PR-3.1 / PR-3.2: consent is hard-coded false and is never a user control."""
    web = read(FRONTEND / "src/lib/api.ts")
    assert re.search(r"consentToShare:\s*false", web)
    mobile = read(MOBILE / "lib/api/report_api.dart")
    assert re.search(r"'consentToShare':\s*false", mobile)
    # The prototype admin screen shows a consent state for mock data; it is not a
    # user-facing control and it is gated (see the XR-8 check).
    user_screens = [
        path
        for path in source_files(FRONTEND / "src/screens", (".ts", ".tsx"))
        if path.name != "AdminScreen.tsx"
    ]
    for path in user_screens:
        assert not re.search(r"consent", read(path), re.IGNORECASE), path
    assert not grep(MOBILE / "lib/screens", (".dart",), r"consent")


def test_pr41_no_location_capture_in_either_client():
    """PR-4.1: no GPS capture in the web or mobile app."""
    assert not grep(FRONTEND / "src", (".ts", ".tsx"), r"geolocation|navigator\.geo|getCurrentPosition")
    mobile = pubspec_dependencies(read(MOBILE / "pubspec.yaml"))
    assert not any("location" in name.lower() or "geolocator" in name.lower() for name in mobile), mobile
    manifest = read(MOBILE / "android/app/src/main/AndroidManifest.xml")
    assert "ACCESS_FINE_LOCATION" not in manifest
    assert "ACCESS_COARSE_LOCATION" not in manifest


def test_pr42_no_contact_is_ever_populated():
    """PR-4.2: the trusted-contact field exists but is never filled in."""
    for path in source_files(FRONTEND / "src", (".ts", ".tsx")):
        for number, line in enumerate(read(path).splitlines(), start=1):
            if "contact:" not in line:
                continue
            assert "null" in line or "| null" in line or "Contact | null" in line, (
                f"{path}:{number} assigns a contact: {line.strip()}"
            )
    assert not grep(MOBILE / "lib", (".dart",), r"contactProvided:\s*true")


def test_pr61_no_analytics_or_advertising_sdk():
    """PR-6.1: no analytics, advertising or tracking library."""
    web = json.loads(read(FRONTEND / "package.json"))
    names = set(web["dependencies"]) | set(web.get("devDependencies", {}))
    banned = {"google-analytics", "react-ga", "amplitude", "mixpanel", "segment", "sentry"}
    assert not names & banned, names
    mobile = pubspec_dependencies(read(MOBILE / "pubspec.yaml"))
    assert not any(
        name.lower() in {"firebase_analytics", "facebook_sdk", "appsflyer", "adjust", "branch_io"}
        for name in mobile
    ), mobile


def test_pr62_no_report_content_in_logs():
    """PR-6.2 / SR-5.1: no report content, key or identifier reaches a log line."""
    pattern = re.compile(
        r"(log|logger|logging)\.(debug|info|warning|warn|error|exception|critical)\(", re.IGNORECASE
    )
    for path in source_files(BACKEND, (".py",)):
        if path.parent.name == "tests":
            continue
        for number, line in enumerate(read(path).splitlines(), start=1):
            if not pattern.search(line):
                continue
            lowered = code_only(line).lower()
            for word in FORBIDDEN_LOG_WORDS:
                assert word not in lowered, f"{path}:{number} logs {word!r}: {line.strip()}"
    assert not grep(FRONTEND / "src", (".ts", ".tsx"), r"console\.(log|debug|info|warn|error)")
    assert not grep(MOBILE / "lib", (".dart",), r"\bprint\s*\(|\bdebugPrint\s*\(|dart:developer")


def test_pr101_clipboard_is_written_and_never_read():
    """PR-10.1 / PR-10.2: the reference code is copied out; the clipboard is never read."""
    assert grep(MOBILE / "lib", (".dart",), r"Clipboard\.setData")
    assert not grep(MOBILE / "lib", (".dart",), r"Clipboard\.getData")
    assert not grep(MOBILE / "lib", (".dart",), r"Clipboard\.clearData")


def test_rr52_no_routine_deletion_of_keys():
    """RR-5.2: no scheduled or routine deletion of idempotency keys exists."""
    for path in source_files(BACKEND, (".py",)):
        if path.parent.name == "tests":
            continue
        lowered = read(path).lower()
        assert "delete from idempotency_keys" not in lowered, path
    assert not grep(BACKEND, (".py",), r"\b(cron|celery|apscheduler)\b")
    assert not grep(MOBILE / "lib", (".dart",), r"\b(cron|scheduleJob|Timer\.periodic)\b")


def test_fr61_web_storage_holds_only_the_theme_choice():
    """FR-6.1: the only browser storage key is the theme preference."""
    offenders = []
    for path in source_files(FRONTEND / "src", (".ts", ".tsx")):
        if path.name.endswith((".test.ts", ".test.tsx")):
            continue  # test code exercises the key; it is not application behaviour
        for number, line in enumerate(read(path).splitlines(), start=1):
            stripped = line.strip()
            if stripped.startswith(("//", "*", "/*")):
                continue  # a comment is not a write
            if re.search(r"localStorage|sessionStorage|indexedDB|document\.cookie|caches\.", line):
                offenders.append(f"{path}:{number}")
    assert all("theme.ts" in offender for offender in offenders), offenders
    theme = read(FRONTEND / "src/lib/theme.ts")
    assert "safesignal-theme" in theme
    assert not grep(FRONTEND / "src", (".ts", ".tsx"), r"sessionStorage|indexedDB|document\.cookie")


def test_no_compiled_in_retention_period():
    """FR-8.1 / FR-8.2: no retention period is compiled into the code or the templates."""
    hits = grep(
        ROOT / "apps",
        (".py", ".ts", ".tsx", ".dart", ".example", ".yaml", ".yml"),
        r"SAFESIGNAL_REPORT_RETENTION_DAYS",
    )
    assert not hits, hits
    for path in source_files(ROOT / "apps", (".env.example",)):
        assert "RETENTION" not in read(path).upper(), path


def test_pr93_privacy_notice_keeps_the_pending_placeholders():
    """PR-9.3: the privacy notice still carries the marked retention placeholders."""
    notice = read(DOCS / "PRIVACY.md")
    assert "[RETENTION PERIOD — pending D-A]" in notice
    assert "[BACKUP RETENTION PERIOD — pending D-B]" in notice


def test_checklist_citations_resolve():
    """Every `path:line` citation in the scope checklist points at a real line."""
    checklist = DOCS / "M4_SCOPE_CHECKLIST.md"
    assert checklist.exists(), "docs/M4_SCOPE_CHECKLIST.md is missing"
    text = read(checklist)
    pattern = re.compile(r"`([A-Za-z0-9_./-]+\.(?:py|ts|tsx|dart|sql|md|json|yaml|yml|arb|xml)):(\d+)")
    seen = 0
    for match in pattern.finditer(text):
        relative, line = match.group(1), int(match.group(2))
        target = ROOT / relative
        assert target.exists(), f"{relative} does not exist"
        lines = read(target).splitlines()
        assert 1 <= line <= len(lines), f"{relative}:{line} is out of range (file has {len(lines)})"
        assert lines[line - 1].strip(), f"{relative}:{line} is a blank line"
        seen += 1
    assert seen >= 40, f"only {seen} citations found; the checklist should cite the code"


# Each citation in the approved documents, with the text that must appear on one of
# the lines it points at. A citation that points at the wrong line fails here.
CITATION_EXPECTATIONS = [
    ("apps/backend/store.py", 80, 91, "in _by_key"),
    ("apps/backend/store_pg.py", 50, 51, "replay"),
    ("apps/backend/migrations/001_init.sql", 26, 26, "ON DELETE CASCADE"),
    ("apps/backend/DATABASE.md", 51, 51, "DELETE FROM reports"),
    ("apps/backend/migrations/001_init.sql", 14, 14, "consent_to_share"),
    ("apps/frontend/src/lib/api.ts", 34, 34, "consentToShare: false"),
    ("apps/mobile/lib/api/report_api.dart", 73, 73, "'consentToShare': false"),
    ("apps/backend/migrations/001_init.sql", 17, 17, "created_at"),
    ("apps/backend/migrations/001_init.sql", 21, 21, "reports_created_at_idx"),
    ("apps/backend/migrations/001_init.sql", 27, 27, "created_at"),
    ("apps/backend/migrations/001_init.sql", 16, 16, "Closed"),
    ("apps/backend/store.py", 80, 84, "return original"),
    ("apps/backend/store_pg.py", 40, 45, "_resolve"),
    ("apps/backend/reports.py", 55, 58, "409"),
    ("apps/backend/store.py", 80, 86, "admit()"),
    ("apps/backend/store_pg.py", 73, 74, "admit()"),
    ("apps/backend/DATABASE.md", 50, 50, "No automatic deletion"),
    ("apps/backend/DATABASE.md", 36, 37, "pg_dump"),
    ("docs/SECURITY.md", 20, 20, "loses all reports"),
    ("docs/SECURITY.md", 7, 7, "SAFESIGNAL_ADMIN_KEY"),
    ("docs/PRIVACY.md", 265, 267, "pending D-A"),
    ("docs/PRIVACY.md", 291, 293, "pending D-B"),
    ("docs/PRIVACY.md", 296, 297, "deleted report can still exist in a backup"),
]


def resolved_citations(text: str) -> list[tuple[str, int, int]]:
    """Every `path:line` citation in the document, with shorthand paths resolved.

    A bare `:42` inside a code span continues the path of the previous citation.
    Fenced code blocks are removed first: their backticks would unbalance the
    inline-span pairing.
    """
    text = re.sub(r"```.*?```", " ", text, flags=re.DOTALL)
    resolved: list[tuple[str, int, int]] = []
    last_path: str | None = None
    for span in re.findall(r"`([^`]+)`", text):
        for match in re.finditer(
            r"(?:([A-Za-z0-9_./-]+\.(?:py|ts|tsx|dart|sql|md|json|yaml|yml|arb|xml)))?"
            r":(\d+)(?:-(\d+))?",
            span,
        ):
            if match.group(1):
                last_path = match.group(1)
            if last_path is None:
                continue
            first = int(match.group(2))
            resolved.append((last_path, first, int(match.group(3) or first)))
    return resolved


@pytest.mark.xfail(
    reason=(
        "C-7: three citations in docs/RETENTION.md point at the wrong line "
        "(DATABASE.md:51, PRIVACY.md:291-293, PRIVACY.md:296-297). "
        "See docs/M4_SCOPE_CHECKLIST.md section 6. Remove this marker once they are fixed."
    ),
    strict=True,
)
def test_approved_document_citations_point_at_the_right_line():
    """Citations in the approved documents must point at the text they claim."""
    approved = "\n".join(read(DOCS / name) for name in ("PRIVACY.md", "RETENTION.md"))
    cited = resolved_citations(approved)
    problems: list[str] = []
    for relative, first, last, needle in CITATION_EXPECTATIONS:
        if (relative, first, last) not in cited:
            problems.append(f"{relative}:{first}-{last} is no longer cited; update this table")
            continue
        target = ROOT / relative
        assert target.exists(), f"{relative} does not exist"
        lines = read(target).splitlines()
        assert 1 <= first <= last <= len(lines), f"{relative}:{first}-{last} is out of range"
        window = "\n".join(lines[first - 1 : last])
        if needle.lower() not in window.lower():
            problems.append(f"{relative}:{first}-{last} does not contain {needle!r}")
    assert not problems, problems
