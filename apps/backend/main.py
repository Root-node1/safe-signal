from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

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

from reports import router as reports_router

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_methods=["GET", "POST", "PATCH"],
    allow_headers=["Content-Type", "X-Admin-Key"],
)
app.include_router(reports_router)
