# Oriel: one container that builds the web app and serves it together with the API.
# Works on Render, Railway, Fly.io, Google Cloud Run, Hugging Face Spaces (Docker) or any Docker host.

# ---- 1) build the frontend (needs ../data for the shared JSON)
FROM node:22-slim AS web
WORKDIR /app
COPY data ./data
COPY frontend/package.json frontend/package-lock.json ./frontend/
RUN cd frontend && npm ci --no-audit --no-fund
COPY frontend ./frontend
RUN cd frontend && npm run build

# ---- 2) the Python server
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
WORKDIR /app
COPY backend/requirements.txt backend/requirements.txt
RUN pip install -r backend/requirements.txt
COPY backend ./backend
COPY data ./data
COPY scripts ./scripts
COPY eval/print ./eval/print
COPY frontend/public ./frontend/public
COPY --from=web /app/frontend/dist ./frontend/dist

# Keys are NOT in the image: set GEMINI_API_KEY and ANUVAAD_CONFIG_JSON (or a secret file) on the host.
EXPOSE 8000
CMD ["sh", "-c", "uvicorn backend.app.main:app --host 0.0.0.0 --port ${PORT:-8000} --proxy-headers --forwarded-allow-ips='*'"]
