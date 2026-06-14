# ─── Hamsa To Go — Backend (FastAPI) ─────────────────────────
# Build:  docker build -t hamsa-backend ./backend
# Run:    docker run -p 8080:8080 --env-file backend/.env hamsa-backend
#
# On Cloud Run, credentials come from the runtime service account
# (Application Default Credentials) — no key file is baked in.

FROM python:3.12-slim

# Don't write .pyc files; flush logs straight to the container output.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install dependencies first for better layer caching.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code.
COPY . .

# Cloud Run (and most hosts) inject the port via $PORT; default to 8080.
ENV PORT=8080
EXPOSE 8080

CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT}"]
