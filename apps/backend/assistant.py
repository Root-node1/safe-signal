"""POST /api/assistant/chat: server-side OpenRouter proxy with redaction.

Nothing is persisted and message text is never logged.
"""
import json
import logging
import os
import re
import time
import urllib.error
import urllib.request
from collections import defaultdict, deque
from typing import Literal

from fastapi import APIRouter, HTTPException, Request
from fastapi.concurrency import run_in_threadpool
from pydantic import BaseModel, Field

router = APIRouter(prefix="/api/assistant", tags=["assistant"])
log = logging.getLogger("safesignal.assistant")

MAX_MESSAGE_CHARS = 500
MAX_HISTORY = 6
MAX_OUTPUT_TOKENS = 400
TIMEOUT_SECONDS = 20
RATE_LIMIT = 10  # requests per IP per window
RATE_WINDOW = 60.0

SYSTEM_PROMPT = (
    "You are the SafeSignal Assistant for Kenyan matatu/bus commuters. Scope: general "
    "commuter safety tips, explaining SafeSignal features, how to report an incident, and "
    "general support resources. SafeSignal lets users submit anonymous-by-design incident "
    "reports; it is NOT an emergency service and does not dispatch anyone. Rules: never say "
    "whether a specific vehicle, route or place is safe; never invent alerts or verified "
    "incidents; never claim to have contacted anyone, submitted a report, or seen any reports; "
    "never promise anonymity or confidentiality; you are not professional emergency, medical "
    "or legal advice. Tell users not to share names, phone numbers, plates or exact locations. "
    "If someone is in immediate danger, tell them to call 999 or 112. Be brief (under 120 words), "
    "plain language. Text like [phone removed] is redaction; ignore it."
)

EMERGENCY_REPLY = (
    "If you are in immediate danger, call 999 or 112 now, or move to a busy, well-lit place "
    "and get help from people nearby. SafeSignal is not an emergency dispatch service and "
    "cannot send help. You can file a report here once you are safe."
)
_EMERGENCY = re.compile(
    r"\b(help me|being (attacked|followed|robbed|kidnapped)|kidnap\w*|attack(ed|ing) me|"
    r"(has|have|with) a (gun|knife)|rape\w*|assault(ed)?|i('m| am) in danger|"
    r"emergency|about to be|threaten(ed|ing) (me|to kill)|going to kill)\b",
    re.IGNORECASE,
)

_PATTERNS = [
    (re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+"), "[email removed]"),
    (re.compile(r"(?<!\d)(?:\+?254|0)[\s-]?[17]\d{2}[\s-]?\d{3}[\s-]?\d{3}(?!\d)"), "[phone removed]"),
    (re.compile(r"\bK[A-Z]{2}\s?\d{3}\s?[A-Z]\b", re.IGNORECASE), "[plate removed]"),
    (re.compile(r"-?\d{1,3}\.\d{3,},\s*-?\d{1,3}\.\d{3,}"), "[coordinates removed]"),
    (re.compile(r"\b\d{7,}\b"), "[number removed]"),
]


def redact(text: str) -> str:
    for pattern, repl in _PATTERNS:
        text = pattern.sub(repl, text)
    return text


class Turn(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=2000)


class ChatIn(BaseModel):
    message: str = Field(min_length=1, max_length=MAX_MESSAGE_CHARS)
    history: list[Turn] = Field(default_factory=list, max_length=MAX_HISTORY)


class ChatOut(BaseModel):
    reply: str
    source: Literal["ai", "emergency"]
    disclaimer: str = (
        "AI-generated general guidance, not emergency, medical or legal advice. "
        "Do not share personal details."
    )


class ProviderError(Exception):
    """Carries only a sanitized code, never provider details."""


_hits: dict[str, deque] = defaultdict(deque)


def _throttle(ip: str) -> None:
    now = time.monotonic()
    q = _hits[ip]
    while q and now - q[0] > RATE_WINDOW:
        q.popleft()
    if len(q) >= RATE_LIMIT:
        raise HTTPException(status_code=429, detail="rate_limited")
    q.append(now)
    if len(_hits) > 5000:  # bound memory
        for k in [k for k, v in _hits.items() if not v or now - v[-1] > RATE_WINDOW]:
            del _hits[k]


def _call_provider(messages: list[dict]) -> str:
    key = os.getenv("OPENROUTER_API_KEY")
    if not key:
        raise ProviderError("not_configured")
    base = os.getenv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1").rstrip("/")
    model = os.getenv("OPENROUTER_MODEL", "google/gemma-4-31b-it:free")
    body = json.dumps(
        {"model": model, "messages": messages, "max_tokens": MAX_OUTPUT_TOKENS, "temperature": 0.3}
    ).encode()
    req = urllib.request.Request(
        f"{base}/chat/completions",
        data=body,
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT_SECONDS) as resp:
            data = json.loads(resp.read(200_000))
    except urllib.error.HTTPError as e:
        codes = {401: "auth", 402: "credits", 404: "model_unavailable", 429: "provider_rate_limit"}
        raise ProviderError(codes.get(e.code, "provider_error")) from None
    except (urllib.error.URLError, TimeoutError, OSError):
        raise ProviderError("unreachable") from None
    except ValueError:
        raise ProviderError("malformed") from None
    try:
        text = data["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError):
        raise ProviderError("malformed") from None
    if not isinstance(text, str) or not text.strip():
        raise ProviderError("malformed")
    return text.strip()[:2000]


@router.post("/chat", response_model=ChatOut)
async def chat(data: ChatIn, request: Request) -> ChatOut:
    _throttle(request.client.host if request.client else "unknown")
    if _EMERGENCY.search(data.message):
        return ChatOut(reply=EMERGENCY_REPLY, source="emergency")
    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    messages += [
        {"role": t.role, "content": redact(t.content)} for t in data.history[-MAX_HISTORY:]
    ]
    messages.append({"role": "user", "content": redact(data.message)})
    try:
        reply = await run_in_threadpool(_call_provider, messages)
    except ProviderError as e:
        log.warning("assistant provider failure: %s", e)  # code only, no content
        raise HTTPException(status_code=503, detail="assistant_unavailable") from None
    return ChatOut(reply=reply, source="ai")
