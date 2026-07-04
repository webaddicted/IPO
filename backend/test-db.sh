#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "Create backend/.env from .env.example first"
  exit 1
fi

# shellcheck source=load-env.sh
source ./load-env.sh
load_env .env

if [[ -z "${SUPABASE_DB_PASSWORD:-}" ]]; then
  echo "SUPABASE_DB_PASSWORD is empty in .env"
  exit 1
fi

USER="${SUPABASE_DB_USER:-postgres.zqvlzrrumfewlyqipphz}"
HOST="aws-1-ap-northeast-1.pooler.supabase.com"

try_connect() {
  local port="$1"
  PGPASSWORD="$SUPABASE_DB_PASSWORD" psql \
    "host=${HOST} port=${port} dbname=postgres user=${USER} sslmode=require" \
    -c "SELECT 1 AS ok;" >/dev/null 2>&1
}

echo "Testing session pooler (port 5432) as ${USER}..."
if try_connect 5432; then
  echo "Connection OK (port 5432)."
  if PGPASSWORD="$SUPABASE_DB_PASSWORD" psql \
    "host=${HOST} port=5432 dbname=postgres user=${USER} sslmode=require" \
    -c "SELECT count(*) AS ipo_count FROM ipos;" 2>/dev/null; then
    echo "Schema OK — run: ./run.sh"
    exit 0
  fi
  echo "Connected, but table 'ipos' is missing."
  echo "Apply migrations: supabase/migrations/0001_init.sql and 0002_requirements.sql"
  exit 2
fi

echo "Trying transaction pooler (port 6543)..."
if try_connect 6543; then
  echo "Connection OK (port 6543) — set SUPABASE_DB_URL port to 6543 in .env"
  exit 0
fi

echo ""
echo "FAILED — cannot connect. Check SUPABASE_DB_PASSWORD in .env"
exit 1
