# 🇮🇳 IPO Tracker — Full Stack

Indian IPO tracker (MainLine + SME): offer price, lot size, GMP, subscription,
financials, KPIs, reservation, important dates and company info — across a
listing screen and a 12-tab detail screen.

```
┌────────────────────────────────────────────────────────────────┐
│  chittorgarh.com                                                 │
│        │ JSoup scrape (hourly list, 30-min GMP)                  │
│        ▼                                                         │
│  Spring Boot backend  ──writes──►  Supabase (PostgreSQL + RLS)   │
│        │ REST /api/v1                       ▲                    │
│        │ (detail aggregate)                 │ realtime reads     │
│        ▼                                     │ (anon key)         │
│  ┌──────────────────────────────────────────┴───────────────┐   │
│  │  Flutter app (GetX)                                       │   │
│  │   • list  ← Supabase realtime stream                      │   │
│  │   • detail ← Spring API  (falls back to Supabase)           │   │
│  └───────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

| Layer | Tech | Folder |
|-------|------|--------|
| Database | Supabase / PostgreSQL | [`supabase/`](supabase/) |
| Backend API + scraper | Java 17, Spring Boot 3.3, JSoup | [`backend/`](backend/) |
| Mobile app | Flutter, GetX | [`lib/`](lib/) |

## Quick start

### 1. Database
Apply `supabase/migrations/` in order in the Supabase SQL Editor (latest: `0003_rebuild_schema.sql`).
See [`supabase/README.md`](supabase/README.md). Then run the backend scraper to populate data.

### 2. Backend
```bash
cd backend
export SUPABASE_DB_URL="jdbc:postgresql://db.YOUR_PROJECT.supabase.co:5432/postgres"
export SUPABASE_DB_PASSWORD="..."
./run.sh
```
See [`backend/README.md`](backend/README.md).

### 3. Flutter app
```bash
flutter pub get

flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081
```

Optional Supabase fallback (when API is down):
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=eyJ... \
  --dart-define=API_BASE_URL=http://10.0.2.2:8081
```

> **Live data requires the backend** on port 8081 (scraper fills the database).

## Flutter architecture (clean / GetX)

```
lib/
├── config/        app_config.dart          # dart-define runtime config
├── constants/     strings, api paths, routes
├── extension/     string_extension.dart
├── theme/         colors, text styles, ThemeData
├── utils/         date / number / json helpers
├── model/bean/    ipo_model, ipo_detail_model (+ sub-beans)
├── services/      api_service, supabase_service, ipo_repository
├── sp/            SharedPreferences (watchlist)
├── controllers/   HomeController, DetailController (GetX)
├── bindings/      AppBinding, DetailBinding (DI)
├── widgets/       ipo_card, status_badge, info_table, gmp_chart
└── screens/       home_screen, ipo_detail_screen
```

**Data policy** (`IpoRepository`): lists and detail read from the FastAPI backend;
Supabase is an optional fallback when the API is unreachable.

## Status

| | |
|--|--|
| Supabase schema | ✅ |
| Spring backend (compiles, 34 classes) | ✅ |
| Flutter app (`flutter analyze`: 0 issues, 8 tests pass) | ✅ |

## ⚠️ Notes
- Scraping selectors in `IpoScraperService` are **best-effort** and need tuning
  against the live chittorgarh markup; review their ToS before production use.
- The `service_role`/DB password stays server-side only — never ship it in the app.
- "Check Allotment Status" and "Offers" are wired as UI placeholders.
# IPO
