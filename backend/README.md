# IPO Tracker — Python FastAPI Backend

Python 3.9+ service that **scrapes** Indian IPO data and **serves** it as a REST API.
It writes to the same Supabase PostgreSQL database the Flutter app reads from.

## Stack

- **FastAPI** + **Uvicorn** — REST API
- **SQLAlchemy** + **psycopg2** — Postgres (Supabase)
- **httpx** + **BeautifulSoup** — JSON/HTML scraping (chittorgarh.com, investorgain.com)
- **APScheduler** — scheduled scraper jobs

## Run

```bash
cd backend
cp .env.example .env   # set SUPABASE_DB_PASSWORD or DATABASE_URL
./run.sh
```

The API listens on **port 8081** by default (`PORT` in `.env`).

Apply [`supabase/migrations/`](../supabase/migrations/) before first run if the schema is empty.

To run API only (no scheduled scraping): `SCRAPER_ENABLED=false` in `.env`.

## REST API

| Method | Path | Notes |
|--------|------|-------|
| GET | `/health` | Liveness |
| GET | `/api/v1/ipos/basic?type=mainline\|sme&status=...` | Optional status filter |
| GET | `/api/v1/ipos/current?type=mainline\|sme` | Upcoming + open + closed |
| GET | `/api/v1/ipos/listed?type=mainline\|sme` | Already listed |
| GET | `/api/v1/ipos/{id}` | Full detail aggregate (all tabs) |
| GET | `/api/v1/ipos/{id}/gmp` | GMP time series |
| GET | `/api/v1/ipos/{id}/subscription` | Overall + day-wise |
| POST | `/api/v1/allotment` | Allotment check (manual registrar fallback) |
| GET | `/api/v1/scrape` | **Scrape now** — fetches all IPO data from chittorgarh.com and stores in Supabase |

## Scheduler (separate app)

The API server and scraper scheduler run as **two processes**:

| Process | Command | Role |
|---------|---------|------|
| API | `./run.sh` | REST endpoints |
| Scheduler | `./run_scheduler.sh` | Auto-scrape on interval |

Scheduler reuses the same `run_scrape` logic as `GET /api/v1/scrape` (list → subscription → details → GMP → Supabase).

Configure interval in `.env`:

```bash
SCRAPER_INTERVAL_MINUTES=60   # 30, 60, or 120
SCHEDULER_RUN_ON_START=false    # true = scrape immediately on startup
```

## Layout

```
app/
├── main.py                 # FastAPI API server
├── scheduler_app.py        # Standalone scheduler entry point
├── config.py               # Settings from .env
├── scheduler.py            # APScheduler job wiring
├── api/routes/             # health, ipos, allotment, scrape
├── db/models.py            # SQLAlchemy ORM
├── schemas/                # Pydantic response models (camelCase JSON)
├── services/               # Read-side + allotment
└── scrapers/               # List, GMP, subscription, detail scrapers
```

## Scraping approach (JSON API, not HTML lists)

chittorgarh.com list pages are SPA-backed. Scrapers target the site's JSON report API:

```
GET https://webnodejs.chittorgarh.com/cloud/report/data-read/
    {reportId}/{page}/{month}/{year}/{financialYear}/{sort}/{parameter}
```

- **reportId `82`** — IPO list (`mainboard` / `sme`)
- **reportId `98`** — subscription (`all`)
- **investorgain report `331`** — GMP (`ipo` / `sme`)
- **detail-read/{id}** — per-IPO enrichment

Review chittorgarh.com Terms of Service before production use. Keep `SCRAPER_POLITE_DELAY_MS` (default 2.5s).

## Tests

```bash
cd backend
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/pytest tests/ -q
```

## Deploy on Render (free API + hourly scraper)

1. Push this repo to GitHub.
2. [Render Dashboard](https://dashboard.render.com) → **New** → **Blueprint**.
3. Connect the repo; blueprint path: **`render.yaml`** (repo root).
4. When prompted, set:
   - `SUPABASE_DB_URL` — Supabase pooler JDBC URL (port 6543)
   - `SUPABASE_DB_USER` — e.g. `postgres.your-project-ref`
   - `SUPABASE_DB_PASSWORD` — database password from Supabase
5. Deploy. You get **`aaipo-api`** (free web service, no payment required).

**Hourly scraper (free, no Render cron):** Render cron jobs require billing (~$1/mo). Use [cron-job.org](https://cron-job.org) instead:

| Setting | Value |
|---------|--------|
| URL | `https://<your-api>.onrender.com/api/v1/scrape` |
| Schedule | Every 1 hour |
| Method | GET |

Also ping `/health` every 10 min on cron-job.org to reduce cold starts (optional).

Trigger a manual scrape: `GET https://<your-api>.onrender.com/api/v1/scrape`

### Flutter client (production)

```bash
flutter run --dart-define=API_BASE_URL=https://aaipo-api.onrender.com
```

### Flutter client (local)

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081
```
