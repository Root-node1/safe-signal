FROM python:3.14-slim AS runtime

WORKDIR /app

RUN addgroup --system safesignal && adduser --system --ingroup safesignal safesignal

COPY --chown=safesignal:safesignal apps/backend/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=safesignal:safesignal apps/backend/ /app/

USER safesignal

EXPOSE 8000

# db.init() runs in the lifespan and raises if DATABASE_URL is missing in production.
# Uvicorn binds to 127.0.0.1:8000; nginx (or a container proxy) terminates TLS.
CMD ["uvicorn", "main:app", "--host", "127.0.0.1", "--port", "8000", "--workers", "1"]
