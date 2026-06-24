-- ============================================================================
-- Indian IPO Tracker — Initial schema
-- Postgres / Supabase
-- ============================================================================
-- Run order: this file creates extensions, enums, tables, indexes, triggers,
-- and RLS policies. Idempotent where practical (IF NOT EXISTS).
-- ============================================================================

create extension if not exists "pgcrypto";   -- gen_random_uuid()

-- ----------------------------------------------------------------------------
-- Note on enums: we deliberately use varchar + CHECK rather than native
-- Postgres enum types. Native PG enums require an explicit cast when bound from
-- a JDBC string parameter, which fights with Hibernate's @Enumerated(STRING)
-- mapping in the Spring backend. varchar + CHECK gives the same validation with
-- zero JPA friction.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- 1. MAIN IPO TABLE
-- ----------------------------------------------------------------------------
create table if not exists ipos (
  id                        uuid primary key default gen_random_uuid(),
  -- A stable natural key derived from the source (slug) so the scraper can
  -- upsert without creating duplicates across runs.
  source_slug               text unique not null,
  company_name              varchar(255) not null,
  logo_url                  text,
  ipo_type                  varchar(20) not null default 'mainline'
                              check (ipo_type in ('mainline','sme')),
  status                    varchar(20) not null default 'upcoming'
                              check (status in ('upcoming','open','closed','listed')),

  -- Pricing
  offer_price_min           numeric(12,2),
  offer_price_max           numeric(12,2),
  issue_price               numeric(12,2),
  face_value                numeric(12,2),
  lot_size                  integer,
  min_investment            numeric(14,2),

  -- Dates
  open_date                 date,
  close_date                date,
  allotment_date            date,
  refund_date               date,
  demat_transfer_date       date,
  listing_date              date,

  -- Issue meta
  listing_at                varchar(50),       -- 'BSE', 'NSE', 'BSE SME', 'NSE SME'
  issue_type                varchar(100),      -- 'Bookbuilding IPO', 'Fixed Price'
  sale_type                 varchar(100),      -- 'Fresh capital cum OFS'
  total_issue_size_shares   bigint,
  total_issue_size_amount   numeric(16,2),     -- in INR
  fresh_issue_shares        bigint,
  ofs_shares                bigint,
  market_maker_shares       bigint,

  -- Live headline numbers (denormalised for fast list rendering)
  latest_gmp                numeric(12,2),
  latest_gmp_percent        numeric(7,2),
  latest_subscription       numeric(10,2),

  registrar                 varchar(255),
  source_url                text,
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now()
);

create index if not exists idx_ipos_status      on ipos (status);
create index if not exists idx_ipos_type         on ipos (ipo_type);
create index if not exists idx_ipos_open_date     on ipos (open_date);
create index if not exists idx_ipos_listing_date  on ipos (listing_date);

-- ----------------------------------------------------------------------------
-- 2. GMP TABLE — time series of grey-market premium readings
-- ----------------------------------------------------------------------------
create table if not exists gmp_data (
  id            uuid primary key default gen_random_uuid(),
  ipo_id        uuid not null references ipos(id) on delete cascade,
  gmp_price     numeric(12,2),
  gmp_percent   numeric(7,2),
  estimated_listing_price numeric(12,2),
  recorded_at   timestamptz not null default now()
);
create index if not exists idx_gmp_ipo on gmp_data (ipo_id, recorded_at desc);

-- ----------------------------------------------------------------------------
-- 3. SUBSCRIPTION TABLE — overall + category-wise, with day-wise snapshots
-- ----------------------------------------------------------------------------
create table if not exists subscription_data (
  id                    uuid primary key default gen_random_uuid(),
  ipo_id                uuid not null references ipos(id) on delete cascade,
  -- 'overall' for the headline row, or 'day1' / 'day2' / 'day3' for day-wise.
  bucket                varchar(20) not null default 'overall',
  total_subscription    numeric(10,2),
  qib_subscription      numeric(10,2),
  nii_subscription      numeric(10,2),
  bnii_subscription     numeric(10,2),   -- big NII (>10L)
  snii_subscription     numeric(10,2),   -- small NII (<10L)
  retail_subscription   numeric(10,2),
  employee_subscription numeric(10,2),
  total_applications    bigint,
  recorded_at           timestamptz not null default now(),
  unique (ipo_id, bucket)
);
create index if not exists idx_sub_ipo on subscription_data (ipo_id);

-- ----------------------------------------------------------------------------
-- 4. FINANCIAL TABLE — period-wise restated financials
-- ----------------------------------------------------------------------------
create table if not exists financial_data (
  id                uuid primary key default gen_random_uuid(),
  ipo_id            uuid not null references ipos(id) on delete cascade,
  period            varchar(20),       -- 'FY2024', 'FY2023', 'Sep 2024'
  revenue           numeric(16,2),     -- in INR (typically lakhs/crore — store raw)
  profit_after_tax  numeric(16,2),
  total_assets      numeric(16,2),
  net_worth         numeric(16,2),
  total_borrowing   numeric(16,2),
  unique (ipo_id, period)
);
create index if not exists idx_fin_ipo on financial_data (ipo_id);

-- ----------------------------------------------------------------------------
-- 5. KEY PERFORMANCE INDICATORS (KPI) — snapshot ratios shown on detail page
-- ----------------------------------------------------------------------------
create table if not exists kpi_data (
  id          uuid primary key default gen_random_uuid(),
  ipo_id      uuid not null references ipos(id) on delete cascade,
  metric      varchar(50) not null,   -- 'ROE', 'ROCE', 'EPS', 'PE_PRE', 'PE_POST', 'RONW', 'DEBT_EQUITY'
  value       numeric(14,4),
  unit        varchar(20),            -- '%', 'x', 'INR'
  unique (ipo_id, metric)
);
create index if not exists idx_kpi_ipo on kpi_data (ipo_id);

-- ----------------------------------------------------------------------------
-- 6. IPO RESERVATION — category-wise share allocation
-- ----------------------------------------------------------------------------
create table if not exists ipo_reservation (
  id               uuid primary key default gen_random_uuid(),
  ipo_id           uuid not null references ipos(id) on delete cascade,
  category         varchar(100) not null,  -- 'QIB', 'NII', 'Retail', 'Employee', 'Market Maker'
  shares_offered   bigint,
  percent_of_total numeric(7,2),
  unique (ipo_id, category)
);
create index if not exists idx_resv_ipo on ipo_reservation (ipo_id);

-- ----------------------------------------------------------------------------
-- 7. LOT SIZE TIERS — application bands shown in "IPO Lot Size" tab
-- ----------------------------------------------------------------------------
create table if not exists lot_size_tier (
  id          uuid primary key default gen_random_uuid(),
  ipo_id      uuid not null references ipos(id) on delete cascade,
  applicant   varchar(50) not null,   -- 'Retail (Min)', 'Retail (Max)', 'S-HNI (Min)', 'B-HNI (Min)'
  lots        integer,
  shares      bigint,
  amount      numeric(14,2),
  unique (ipo_id, applicant)
);
create index if not exists idx_lot_ipo on lot_size_tier (ipo_id);

-- ----------------------------------------------------------------------------
-- 8. IMPORTANT DATES — timeline rows for the "IPO Important Dates" tab
-- ----------------------------------------------------------------------------
create table if not exists important_dates (
  id          uuid primary key default gen_random_uuid(),
  ipo_id      uuid not null references ipos(id) on delete cascade,
  event       varchar(100) not null,  -- 'IPO Open', 'IPO Close', 'Allotment', 'Refund', 'Listing'
  event_date  date,
  sort_order  integer default 0,
  unique (ipo_id, event)
);
create index if not exists idx_dates_ipo on important_dates (ipo_id);

-- ----------------------------------------------------------------------------
-- 9. COMPANY INFO + OBJECTIVES
-- ----------------------------------------------------------------------------
create table if not exists company_info (
  id            uuid primary key default gen_random_uuid(),
  ipo_id        uuid not null unique references ipos(id) on delete cascade,
  description   text,
  promoters     text,
  lead_managers text,
  objectives    text,
  website_url   text
);

-- ----------------------------------------------------------------------------
-- updated_at trigger for ipos
-- ----------------------------------------------------------------------------
create or replace function set_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_ipos_updated_at on ipos;
create trigger trg_ipos_updated_at
  before update on ipos
  for each row execute function set_updated_at();

-- ----------------------------------------------------------------------------
-- Row Level Security — public read, writes only via service-role key (backend)
-- ----------------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array[
    'ipos','gmp_data','subscription_data','financial_data','kpi_data',
    'ipo_reservation','lot_size_tier','important_dates','company_info'
  ] loop
    execute format('alter table %I enable row level security;', t);
    execute format('drop policy if exists "public_read" on %I;', t);
    execute format('create policy "public_read" on %I for select using (true);', t);
  end loop;
end $$;
-- NOTE: No INSERT/UPDATE/DELETE policies are created, so anon/auth roles cannot
-- write. The Spring backend connects with the service-role key (or the Postgres
-- superuser via JDBC), which bypasses RLS.
