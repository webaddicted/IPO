#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "Missing backend/.env — copy from .env.example and set SUPABASE_DB_PASSWORD"
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

if [[ -z "${SUPABASE_DB_PASSWORD:-}" && -z "${DATABASE_URL:-}" ]]; then
  echo "Set SUPABASE_DB_PASSWORD or DATABASE_URL in .env"
  exit 1
fi

if [[ ! -d .venv ]]; then
  python3 -m venv .venv
  .venv/bin/pip install -r requirements.txt
fi

echo "Starting FastAPI on port ${PORT:-8081}"
exec .venv/bin/uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8081}"
