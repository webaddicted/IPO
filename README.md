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
│  │   • detail ← Spring API  (falls back to Supabase, mock)   │   │
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
Apply `supabase/migrations/0001_init.sql` then `supabase/seed/0001_seed.sql`
in the Supabase SQL Editor. See [`supabase/README.md`](supabase/README.md).

### 2. Backend (optional for a demo — the app has mock data)
```bash
cd backend
export SUPABASE_DB_URL="jdbc:postgresql://db.YOUR_PROJECT.supabase.co:5432/postgres"
export SUPABASE_DB_PASSWORD="..."
mvn spring-boot:run
```
See [`backend/README.md`](backend/README.md).

### 3. Flutter app
```bash
flutter pub get

# Zero-config demo (uses bundled mock data):
flutter run

# Wired to live data:
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=API_BASE_URL=http://10.0.2.2:8081
```

> **The app runs with no backend at all** — when Supabase keys are absent it
> serves bundled sample data (`lib/services/mock_data.dart`), so you can see the
> full UI immediately.

## Flutter architecture (clean / GetX)

```
lib/
├── config/        app_config.dart          # dart-define runtime config
├── constants/     strings, api paths, routes
├── extension/     string_extension.dart
├── theme/         colors, text styles, ThemeData
├── utils/         date / number / json helpers
├── model/bean/    ipo_model, ipo_detail_model (+ sub-beans)
├── services/      api_service, supabase_service, ipo_repository, mock_data
├── sp/            SharedPreferences (watchlist)
├── controllers/   HomeController, DetailController (GetX)
├── bindings/      AppBinding, DetailBinding (DI)
├── widgets/       ipo_card, status_badge, info_table, gmp_chart
└── screens/       home_screen, ipo_detail_screen
```

**Data policy** (`IpoRepository`): lists prefer Supabase realtime → API → mock;
detail prefers the Spring API aggregate → Supabase → mock. Every path degrades
gracefully.

## Status

| | |
|--|--|
| Supabase schema + seed | ✅ |
| Spring backend (compiles, 34 classes) | ✅ |
| Flutter app (`flutter analyze`: 0 issues, 8 tests pass) | ✅ |

## ⚠️ Notes
- Scraping selectors in `IpoScraperService` are **best-effort** and need tuning
  against the live chittorgarh markup; review their ToS before production use.
- The `service_role`/DB password stays server-side only — never ship it in the app.
- "Check Allotment Status" and "Offers" are wired as UI placeholders.
# IPO
