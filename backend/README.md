# IPO Tracker — Spring Boot Backend

Java 17 + Spring Boot 3.3 service that **scrapes** Indian IPO data (JSoup) and
**serves** it as a REST API. It writes to the same Supabase PostgreSQL database
the Flutter app reads from directly for realtime.

## Run

```bash
cd backend

# Provide Supabase credentials (Project Settings → Database)
export SUPABASE_DB_URL="jdbc:postgresql://aws-1-ap-northeast-2.pooler.supabase.com:6543/postgres?sslmode=require"
export SUPABASE_DB_USER="postgres.ddtztnkkhlldxrumajxb"
export SUPABASE_DB_PASSWORD="your-db-password"   # from Supabase → Database settings
export CORS_ORIGINS="*"                        # tighten for production

# Local Homebrew Postgres instead: export SPRING_PROFILES_ACTIVE=local

./mvnw spring-boot:run                # or: mvn spring-boot:run
```

> The app uses `spring.jpa.hibernate.ddl-auto=validate` — apply
> `supabase/migrations/0001_init.sql` **before** first run, or startup fails.

To run without scraping (API only, e.g. against seeded data): `export SCRAPER_ENABLED=false`.

## REST API

| Method | Path | Notes |
|--------|------|-------|
| GET | `/health` | Liveness |
| GET | `/api/v1/ipos/current?type=mainline\|sme` | Upcoming + open + closed |
| GET | `/api/v1/ipos/listed?type=mainline\|sme` | Already listed |
| GET | `/api/v1/ipos/{id}` | Full detail aggregate (all tabs) |
| GET | `/api/v1/ipos/{id}/gmp` | GMP time series |
| GET | `/api/v1/ipos/{id}/subscription` | Overall + day-wise |
| POST | `/api/v1/admin/scrape/list` | Trigger list scrape now |
| POST | `/api/v1/admin/scrape/gmp` | Trigger GMP scrape now |
| POST | `/api/v1/admin/scrape/detail/{slug}` | Re-scrape one IPO's detail page |

## Scheduler

| Job | Cadence |
|-----|---------|
| `refreshIpoList` | every `scraper.list-fixed-rate-ms` (default 1h) |
| `refreshGmp` | every 30 min, 09–16h, Mon–Fri, `Asia/Kolkata` |

## Layout

```
src/main/java/com/ipotracker/
├── IpoTrackerApplication.java
├── config/WebConfig.java            # CORS
├── controller/                      # REST + error handling + health
├── dto/Dtos.java                    # response records
├── model/                           # JPA entities + enums
├── repository/Repositories.java     # Spring Data interfaces
├── scheduler/IpoScheduler.java
└── service/                         # IpoService (read), IpoScraperService,
                                     # GmpScraperService, ParseUtil
```

## Scraping approach (JSON API, not HTML)

chittorgarh.com is a **Next.js single-page app** — its list pages contain no
server-rendered `<table>`, so HTML/CSS scraping does not work. The React client
reads a JSON report API, which `IpoScraperService` targets directly (verified
against live responses):

```
GET https://webnodejs.chittorgarh.com/cloud/report/data-read/
    {reportId}/{page}/{month}/{year}/{financialYear}/{sort}/{parameter}
```

- **reportId `82`** = the "IPO in India" report.
- **`{parameter}`** is the string code `mainboard` / `sme` / `all` (it is *not*
  a numeric id — that returns `"No params data found."`).
- Field mapping uses the clean `~`-prefixed columns (`~IPO`, `~URLRewrite_Folder_Name`,
  `~Issue_Open_Date`, `~IssueCloseDate`, `~ListingDate`, `~compare_image`) plus
  `Issue Price (Rs.)` and `Total Issue Amount …(Rs.cr.)` (crore → absolute INR).
- Report params are discoverable via `…/cloud/report/info-read/{reportId}`.

### ⚠️ Notes
- Review chittorgarh.com's Terms of Service before running in production.
- `scraper.polite-delay-ms` (default 2.5s) spaces out requests — keep it.
- **Detail enrichment** (GMP, subscription, lot size, financials) lives on
  per-IPO pages that are *also* SPA-backed JSON reports; `scrapeDetail` is a
  stub hook awaiting that report id. `GmpScraperService` still attempts HTML and
  will simply find nothing on the SPA — consider `investorgain.com` for GMP.
- `IpoScraperServiceTest` covers URL building, id extraction, and IST date
  parsing against the real JSON shape.
