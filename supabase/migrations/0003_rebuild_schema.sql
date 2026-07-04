-- ============================================================================
-- IPO Tracker — Rebuild schema (master ipos + 14 child table groups)
-- WARNING: Drops all existing IPO data. Run only after backup.
-- ============================================================================

drop table if exists company_info cascade;
drop table if exists gmp_data cascade;
drop table if exists subscription_data cascade;
drop table if exists financial_data cascade;
drop table if exists kpi_data cascade;
drop table if exists ipo_reservation cascade;
drop table if exists lot_size_tier cascade;
drop table if exists important_dates cascade;
drop table if exists ipos cascade;

-- Also drop new names if re-running
drop table if exists peer_comparisons cascade;
drop table if exists gmp_history cascade;
drop table if exists subscription_snapshots cascade;
drop table if exists financial_periods cascade;
drop table if exists kpi_metrics cascade;
drop table if exists ipo_reservations cascade;
drop table if exists lot_size_tiers cascade;
drop table if exists anchor_investors cascade;
drop table if exists ipo_reviews cascade;
drop table if exists drhp_milestones cascade;
drop table if exists lead_managers cascade;
drop table if exists ipo_contacts cascade;
drop table if exists company_profiles cascade;

-- ----------------------------------------------------------------------------
-- 1. MASTER
-- ----------------------------------------------------------------------------
create table ipos (
  id                          uuid primary key default gen_random_uuid(),
  source_chittorgarh_id       bigint unique not null,
  source_slug                 text unique not null,
  source_url                  text,
  company_name                varchar(255) not null,
  logo_url                    text,
  ipo_type                    varchar(20) not null default 'mainline'
                                check (ipo_type in ('mainline','sme')),
  status                      varchar(20) not null default 'upcoming'
                                check (status in ('upcoming','open','closed','listed')),

  offer_price_min             numeric(12,2),
  offer_price_max             numeric(12,2),
  issue_price                 numeric(12,2),
  face_value                  numeric(12,2),
  lot_size                    integer,
  min_investment              numeric(14,2),

  open_date                   date,
  close_date                  date,
  allotment_date              date,
  refund_date                 date,
  demat_transfer_date         date,
  listing_date                date,

  listing_at                  varchar(50),
  issue_type                  varchar(100),
  sale_type                   varchar(100),
  total_issue_size_shares     bigint,
  total_issue_size_amount     numeric(16,2),
  fresh_issue_shares          bigint,
  ofs_shares                  bigint,
  market_maker_shares         bigint,
  anchor_shares_offered       bigint,
  anchor_investor_url         text,

  promoter_holding_pre        numeric(7,2),
  promoter_holding_post       numeric(7,2),
  registrar_name              varchar(255),
  nse_symbol                  varchar(50),
  bse_scripcode               varchar(50),
  prospectus_drhp             text,
  prospectus_rhp              text,

  latest_gmp                  numeric(12,2),
  latest_gmp_percent          numeric(7,2),
  estimated_listing_price     numeric(12,2),
  listed_price                numeric(12,2),
  latest_subscription         numeric(10,2),

  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now(),
  last_scraped_at             timestamptz
);

create index idx_ipos_chittorgarh_id on ipos (source_chittorgarh_id);
create index idx_ipos_status on ipos (status);
create index idx_ipos_type on ipos (ipo_type);

-- ----------------------------------------------------------------------------
-- 2. COMPANY PROFILE (1:1)
-- ----------------------------------------------------------------------------
create table company_profiles (
  id              uuid primary key default gen_random_uuid(),
  ipo_id          uuid not null unique references ipos(id) on delete cascade,
  description     text,
  industry        varchar(255),
  promoters       text,
  objectives      text,
  website_url     text,
  address_line1   text,
  address_line2   text,
  address_line3   text,
  city            varchar(100),
  state           varchar(100),
  pin_code        varchar(20),
  phone           varchar(50),
  fax             varchar(50),
  email           varchar(255)
);

-- ----------------------------------------------------------------------------
-- 3. CONTACTS (registrar + company)
-- ----------------------------------------------------------------------------
create table ipo_contacts (
  id            uuid primary key default gen_random_uuid(),
  ipo_id        uuid not null references ipos(id) on delete cascade,
  contact_type  varchar(30) not null,
  name          varchar(255),
  phone         varchar(50),
  fax           varchar(50),
  email         varchar(255),
  website       text,
  address       text
);
create index idx_ipo_contacts_ipo on ipo_contacts (ipo_id);

-- ----------------------------------------------------------------------------
-- 4. LEAD MANAGERS
-- ----------------------------------------------------------------------------
create table lead_managers (
  id          uuid primary key default gen_random_uuid(),
  ipo_id      uuid not null references ipos(id) on delete cascade,
  name        varchar(255) not null,
  address     text,
  website     text,
  email       varchar(255),
  phone       varchar(100),
  is_primary  boolean default false
);
create index idx_lead_managers_ipo on lead_managers (ipo_id);

-- ----------------------------------------------------------------------------
-- 5. IMPORTANT DATES / TIMETABLE
-- ----------------------------------------------------------------------------
create table important_dates (
  id          uuid primary key default gen_random_uuid(),
  ipo_id      uuid not null references ipos(id) on delete cascade,
  event       varchar(100) not null,
  event_date  date,
  sort_order  integer default 0,
  unique (ipo_id, event)
);

-- ----------------------------------------------------------------------------
-- 6. LOT SIZE TIERS
-- ----------------------------------------------------------------------------
create table lot_size_tiers (
  id        uuid primary key default gen_random_uuid(),
  ipo_id    uuid not null references ipos(id) on delete cascade,
  applicant varchar(50) not null,
  lots      integer,
  shares    bigint,
  amount    numeric(14,2),
  unique (ipo_id, applicant)
);

-- ----------------------------------------------------------------------------
-- 7. RESERVATIONS
-- ----------------------------------------------------------------------------
create table ipo_reservations (
  id                  uuid primary key default gen_random_uuid(),
  ipo_id              uuid not null references ipos(id) on delete cascade,
  category            varchar(100) not null,
  shares_offered      bigint,
  percent_of_net_issue numeric(7,2),
  percent_of_total    numeric(7,2),
  max_allottees       integer,
  unique (ipo_id, category)
);

-- ----------------------------------------------------------------------------
-- 8. ANCHOR INVESTORS
-- ----------------------------------------------------------------------------
create table anchor_investors (
  id                uuid primary key default gen_random_uuid(),
  ipo_id            uuid not null references ipos(id) on delete cascade,
  entity_name       varchar(500),
  fund_house        varchar(255),
  shares_allotted   bigint,
  amount_cr         numeric(14,4),
  percent_allocated numeric(7,2),
  percent_of_issue  numeric(7,2),
  sort_order        integer default 0
);
create index idx_anchor_investors_ipo on anchor_investors (ipo_id);

-- ----------------------------------------------------------------------------
-- 9. IPO REVIEW (1:1)
-- ----------------------------------------------------------------------------
create table ipo_reviews (
  id                uuid primary key default gen_random_uuid(),
  ipo_id            uuid not null unique references ipos(id) on delete cascade,
  conclusion        text,
  recommendation    varchar(50),
  review_conclusion varchar(100),
  cm_rating         numeric(6,2),
  reviewed_at       timestamptz
);

-- ----------------------------------------------------------------------------
-- 10. DRHP MILESTONES
-- ----------------------------------------------------------------------------
create table drhp_milestones (
  id              uuid primary key default gen_random_uuid(),
  ipo_id          uuid not null references ipos(id) on delete cascade,
  milestone_code  integer,
  description     varchar(255),
  milestone_date  date,
  unique (ipo_id, milestone_code)
);

-- ----------------------------------------------------------------------------
-- 11. FINANCIAL PERIODS
-- ----------------------------------------------------------------------------
create table financial_periods (
  id                uuid primary key default gen_random_uuid(),
  ipo_id            uuid not null references ipos(id) on delete cascade,
  period            varchar(20),
  total_assets      numeric(16,2),
  revenue           numeric(16,2),
  ebitda            numeric(16,2),
  profit_before_tax numeric(16,2),
  profit_after_tax  numeric(16,2),
  net_worth         numeric(16,2),
  reserves_surplus  numeric(16,2),
  total_borrowing   numeric(16,2),
  unique (ipo_id, period)
);

-- ----------------------------------------------------------------------------
-- 12. KPI METRICS
-- ----------------------------------------------------------------------------
create table kpi_metrics (
  id      uuid primary key default gen_random_uuid(),
  ipo_id  uuid not null references ipos(id) on delete cascade,
  metric  varchar(50) not null,
  value   numeric(14,4),
  unit    varchar(20),
  unique (ipo_id, metric)
);

-- ----------------------------------------------------------------------------
-- 13. SUBSCRIPTION SNAPSHOTS
-- ----------------------------------------------------------------------------
create table subscription_snapshots (
  id                      uuid primary key default gen_random_uuid(),
  ipo_id                  uuid not null references ipos(id) on delete cascade,
  bucket                  varchar(20) not null default 'overall',
  subscription_date       date,
  total_subscription      numeric(10,2),
  qib_subscription        numeric(10,2),
  nii_subscription        numeric(10,2),
  bnii_subscription       numeric(10,2),
  snii_subscription       numeric(10,2),
  retail_subscription     numeric(10,2),
  employee_subscription   numeric(10,2),
  market_maker_subscription numeric(10,2),
  total_applications      bigint,
  recorded_at             timestamptz not null default now(),
  unique (ipo_id, bucket, subscription_date)
);

-- ----------------------------------------------------------------------------
-- 14. GMP HISTORY
-- ----------------------------------------------------------------------------
create table gmp_history (
  id                      uuid primary key default gen_random_uuid(),
  ipo_id                  uuid not null references ipos(id) on delete cascade,
  issue_price             numeric(12,2),
  gmp_price               numeric(12,2),
  gmp_percent             numeric(7,2),
  estimated_listing_price numeric(12,2),
  recorded_at             timestamptz not null default now()
);
create index idx_gmp_history_ipo on gmp_history (ipo_id, recorded_at desc);

-- ----------------------------------------------------------------------------
-- 15. PEER COMPARISONS
-- ----------------------------------------------------------------------------
create table peer_comparisons (
  id                uuid primary key default gen_random_uuid(),
  ipo_id            uuid not null references ipos(id) on delete cascade,
  peer_company_name varchar(255) not null,
  eps               numeric(14,4),
  nav               numeric(14,4),
  pe_ratio          numeric(14,4),
  ronw              numeric(14,4),
  pbv               numeric(14,4)
);

-- ----------------------------------------------------------------------------
-- updated_at trigger
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
-- RLS — public read
-- ----------------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array[
    'ipos','company_profiles','ipo_contacts','lead_managers','important_dates',
    'lot_size_tiers','ipo_reservations','anchor_investors','ipo_reviews',
    'drhp_milestones','financial_periods','kpi_metrics','subscription_snapshots',
    'gmp_history','peer_comparisons'
  ] loop
    execute format('alter table %I enable row level security;', t);
    execute format('drop policy if exists "public_read" on %I;', t);
    execute format('create policy "public_read" on %I for select using (true);', t);
  end loop;
end $$;
