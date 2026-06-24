# Supabase — IPO Tracker Database

PostgreSQL schema + seed data for the Indian IPO Tracker.

## Layout

```
supabase/
├── migrations/
│   └── 0001_init.sql      # extensions, enums, tables, indexes, triggers, RLS
└── seed/
    └── 0001_seed.sql      # demo IPOs (UHM Vacation + 3 others) with child rows
```

## Tables

| Table | Purpose |
|-------|---------|
| `ipos` | Master record; denormalised headline GMP/subscription for fast list rendering |
| `gmp_data` | Time-series of grey-market premium (Day Wise GMP tab) |
| `subscription_data` | Overall + day-wise category subscription (Subscription / Day Wise Sub tabs) |
| `financial_data` | Period-wise restated financials |
| `kpi_data` | ROE / ROCE / EPS / PE etc. (Key Performance Indicators tab) |
| `ipo_reservation` | Category-wise share allocation |
| `lot_size_tier` | Application bands (IPO Lot Size tab) |
| `important_dates` | Timeline events (IPO Important Dates tab) |
| `company_info` | Description, promoters, lead managers, objectives |

## Apply the schema

### Option A — Supabase SQL Editor (quickest)
1. Open your project → **SQL Editor**.
2. Paste `migrations/0001_init.sql`, run it.
3. Paste `seed/0001_seed.sql`, run it.

### Option B — psql / CLI
```bash
# Connection string from Project Settings → Database
export DB_URL="postgresql://postgres:[PASSWORD]@db.[PROJECT].supabase.co:5432/postgres"

psql "$DB_URL" -f supabase/migrations/0001_init.sql
psql "$DB_URL" -f supabase/seed/0001_seed.sql
```

## Security model (RLS)

- All tables have **Row Level Security enabled** with a single `public_read`
  SELECT policy → the Flutter app (anon key) can read everything in realtime.
- **No write policies exist.** Inserts/updates/deletes are only possible with
  the **service-role key** (or the Postgres role over JDBC), which bypasses RLS.
  The Spring backend owns all writes.

## Keys the apps need

| Key | Used by | Where |
|-----|---------|-------|
| `anon` public key + project URL | Flutter (realtime reads) | Project Settings → API |
| `service_role` key **or** Postgres password | Spring backend (writes via JDBC) | Project Settings → Database / API |

> ⚠️ The `service_role` key bypasses RLS — keep it server-side only, never in the Flutter app.
