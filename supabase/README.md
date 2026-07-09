# Supabase — IPO Tracker Database

PostgreSQL schema for the Indian IPO Tracker.

## Layout

```
supabase/
└── migrations/
    ├── 0003_rebuild_schema.sql   # current schema (ipo_ prefixed tables)
    ├── 0004_enable_realtime.sql
    └── 0005_ipo_table_prefix.sql # rename migration for existing DBs
```

## Tables

| Table | Purpose |
|-------|---------|
| `ipo_ipos` | Master record; denormalised headline GMP/subscription for fast list rendering |
| `ipo_gmp_history` | Time-series of grey-market premium |
| `ipo_subscription_snapshots` | Overall + day-wise category subscription |
| `ipo_financial_periods` | Period-wise restated financials |
| `ipo_kpi_metrics` | ROE / ROCE / EPS / PE etc. |
| `ipo_reservations` | Category-wise share allocation |
| `ipo_lot_size_tiers` | Application bands (IPO Lot Size tab) |
| `ipo_important_dates` | Timeline events |
| `ipo_company_profiles` | Description, promoters, objectives |

## Apply the schema

### Option A — Supabase SQL Editor (quickest)
1. Open your project → **SQL Editor**.
2. Run migrations in order: `0003_rebuild_schema.sql`, then `0004_enable_realtime.sql`.
3. Start the backend scraper (`GET /api/v1/scrape`) to populate live IPO data.

### Option B — psql / CLI
```bash
export DB_URL="postgresql://postgres:[PASSWORD]@db.[PROJECT].supabase.co:5432/postgres"

psql "$DB_URL" -f supabase/migrations/0003_rebuild_schema.sql
psql "$DB_URL" -f supabase/migrations/0004_enable_realtime.sql
```

If upgrading an existing database with unprefixed table names, also run `0005_ipo_table_prefix.sql`.

## Security model (RLS)

- All tables have **Row Level Security enabled** with a single `public_read`
  SELECT policy → the Flutter app (anon key) can read everything in realtime.
- **No write policies exist.** Inserts/updates/deletes are only possible with
  the **service-role key** (or the Postgres role over JDBC), which bypasses RLS.
  The backend owns all writes.

## Keys the apps need

| Key | Used by | Where |
|-----|---------|-------|
| `anon` public key + project URL | Flutter (optional fallback reads) | Project Settings → API |
| `service_role` key **or** Postgres password | Backend (writes via JDBC) | Project Settings → Database / API |

> ⚠️ The `service_role` key bypasses RLS — keep it server-side only, never in the Flutter app.
