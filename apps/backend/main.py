import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel

import db


@asynccontextmanager
async def lifespan(_app: FastAPI):
    db.init()  # raises in production when DATABASE_URL is missing
    yield
    db.close()


app = FastAPI(lifespan=lifespan)


@app.exception_handler(db.DatabaseUnavailable)
async def _db_unavailable(_request, _exc):
    return JSONResponse(status_code=503, content={"detail": "Service temporarily unavailable"})


def _cors_origins() -> list[str]:
    """Production CORS origins from SAFESIGNAL_CORS_ORIGINS (comma-separated).

    Defaults to the local dev origin. An empty value means "no browser origins"
    — useful when the public API is meant for native apps only.
    """
    raw = os.getenv("SAFESIGNAL_CORS_ORIGINS", "http://localhost:5173").strip()
    if not raw:
        return []
    return [o.strip() for o in raw.split(",") if o.strip()]


app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins(),
    allow_methods=["GET", "POST", "PATCH"],
    allow_headers=["Content-Type", "X-Admin-Key", "Idempotency-Key"],
)


@app.middleware("http")
async def _security_headers(request, call_next):
    response = await call_next(request)
    response.headers.setdefault("X-Content-Type-Options", "nosniff")
    response.headers.setdefault("X-Frame-Options", "DENY")
    response.headers.setdefault("Referrer-Policy", "strict-origin-when-cross-origin")
    response.headers.setdefault("X-XSS-Protection", "0")
    if os.getenv("SAFESIGNAL_ENV", "").strip().lower() == "production":
        response.headers.setdefault(
            "Strict-Transport-Security",
            "max-age=31536000; includeSubDomains",
        )
        response.headers.setdefault(
            "Content-Security-Policy",
            "default-src 'none'; frame-ancestors 'none'",
        )
    return response


@app.get("/health/live")
def live():
    return {"status": "ok"}


@app.get("/health/ready")
def ready():
    if db.enabled():
        db.ping()  # DatabaseUnavailable -> 503
    return {"status": "ok", "storage": "postgres" if db.enabled() else "memory"}


class Report(BaseModel):
    text: str


@app.get("/")
def root():
    return {"message": "SafeSignal API running"}


@app.post("/analyze")
async def analyze(report: Report):
    return JSONResponse(
        status_code=410,
        content={"detail": "This prototype endpoint has been removed. Use POST /api/assistant/chat."},
    )


# --- SafeSignal reports API ---
from assistant import router as assistant_router
from reports import router as reports_router

app.include_router(reports_router)
app.include_router(assistant_router)
