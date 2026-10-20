from contextlib import asynccontextmanager

from fastapi import FastAPI
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
    return {
        "category": "fare dispute",
        "tags": ["overcharging", "misconduct"],
        "severity": "medium",
        "summary": "Overcharging and rude conductor behavior reported."
    }

# --- SafeSignal reports API ---
from fastapi.middleware.cors import CORSMiddleware

from assistant import router as assistant_router
from reports import router as reports_router

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_methods=["GET", "POST", "PATCH"],
    allow_headers=["Content-Type", "X-Admin-Key", "Idempotency-Key"],
)
app.include_router(reports_router)
app.include_router(assistant_router)
