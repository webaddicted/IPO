-- ============================================================================
-- Seed data — mirrors the screenshots (UHM Vacation SME IPO + a mainline open
-- IPO + an upcoming + a listed one) so the app has realistic content to render
-- before the live scraper is wired up.
-- Safe to re-run: uses ON CONFLICT (source_slug) upserts.
-- ============================================================================

-- ---- IPO 1: UHM Vacation (SME, closed/awaiting listing) --------------------
insert into ipos (
  source_slug, company_name, ipo_type, status,
  offer_price_min, offer_price_max, issue_price, face_value, lot_size, min_investment,
  open_date, close_date, allotment_date, listing_date,
  listing_at, issue_type, sale_type,
  total_issue_size_shares, total_issue_size_amount, market_maker_shares,
  latest_gmp, latest_gmp_percent, latest_subscription,
  registrar, source_url
) values (
  'uhm-vacation', 'UHM Vacation', 'sme', 'closed',
  157, 166, 166, 10, 800, 132800,
  '2026-06-04', '2026-06-08', '2026-06-09', '2026-06-11',
  'BSE SME', 'Bookbuilding IPO', 'Fresh capital cum OFS',
  2168800, 36000000, 110400,
  0, 0.00, 2.36,
  'Bigshare Services Pvt Ltd', 'https://www.chittorgarh.com/ipo/uhm-vacation-ipo/'
)
on conflict (source_slug) do update set
  status = excluded.status, latest_gmp = excluded.latest_gmp,
  latest_subscription = excluded.latest_subscription, updated_at = now();

-- ---- IPO 2: open mainline --------------------------------------------------
insert into ipos (
  source_slug, company_name, ipo_type, status,
  offer_price_min, offer_price_max, issue_price, face_value, lot_size, min_investment,
  open_date, close_date, allotment_date, listing_date,
  listing_at, issue_type, sale_type,
  total_issue_size_shares, total_issue_size_amount,
  latest_gmp, latest_gmp_percent, latest_subscription,
  registrar, source_url
) values (
  'orbit-mobility', 'Orbit Mobility', 'mainline', 'open',
  130, 138, null, 2, 100, 13800,
  '2026-06-23', '2026-06-25', '2026-06-26', '2026-06-30',
  'NSE, BSE', 'Bookbuilding IPO', 'Fresh capital cum OFS',
  18500000, 2553000000,
  80, 57.97, 12.4,
  'Link Intime India Pvt Ltd', 'https://www.chittorgarh.com/ipo/orbit-mobility-ipo/'
)
on conflict (source_slug) do update set
  status = excluded.status, latest_gmp = excluded.latest_gmp, updated_at = now();

-- ---- IPO 3: upcoming -------------------------------------------------------
insert into ipos (
  source_slug, company_name, ipo_type, status,
  offer_price_min, offer_price_max, face_value, lot_size, min_investment,
  open_date, close_date, listing_date, listing_at, issue_type,
  total_issue_size_amount, latest_gmp, latest_gmp_percent,
  registrar, source_url
) values (
  'vedant-greens', 'Vedant Greens', 'mainline', 'upcoming',
  220, 232, 5, 61, 14152,
  '2026-06-28', '2026-07-01', '2026-07-04', 'NSE, BSE', 'Bookbuilding IPO',
  1200000000, 45, 19.40,
  'KFin Technologies', 'https://www.chittorgarh.com/ipo/vedant-greens-ipo/'
)
on conflict (source_slug) do update set status = excluded.status, updated_at = now();

-- ---- IPO 4: listed ---------------------------------------------------------
insert into ipos (
  source_slug, company_name, ipo_type, status,
  issue_price, face_value, lot_size,
  open_date, close_date, listing_date, listing_at, issue_type,
  total_issue_size_amount, latest_subscription,
  registrar, source_url
) values (
  'silverline-tech', 'Silverline Tech', 'mainline', 'listed',
  410, 10, 36,
  '2026-05-20', '2026-05-22', '2026-05-27', 'NSE, BSE', 'Bookbuilding IPO',
  8900000000, 48.6,
  'Link Intime India Pvt Ltd', 'https://www.chittorgarh.com/ipo/silverline-tech-ipo/'
)
on conflict (source_slug) do update set status = excluded.status, updated_at = now();

-- ============================================================================
-- Child rows for UHM Vacation
-- ============================================================================
do $$
declare v uuid;
begin
  select id into v from ipos where source_slug = 'uhm-vacation';

  -- GMP history
  delete from gmp_data where ipo_id = v;
  insert into gmp_data (ipo_id, gmp_price, gmp_percent, estimated_listing_price, recorded_at) values
    (v, 0,  0.00, 166, now() - interval '3 day'),
    (v, 0,  0.00, 166, now() - interval '2 day'),
    (v, 0,  0.00, 166, now() - interval '1 day');

  -- Subscription overall + day-wise
  delete from subscription_data where ipo_id = v;
  insert into subscription_data (ipo_id, bucket, total_subscription, qib_subscription, nii_subscription, retail_subscription) values
    (v, 'overall', 2.36, 1.10, 3.40, 2.58),
    (v, 'day1', 0.42, 0.00, 0.55, 0.71),
    (v, 'day2', 1.18, 0.30, 1.90, 1.44),
    (v, 'day3', 2.36, 1.10, 3.40, 2.58);

  -- Financials
  delete from financial_data where ipo_id = v;
  insert into financial_data (ipo_id, period, revenue, profit_after_tax, total_assets, net_worth) values
    (v, 'FY2025', 4820.00, 612.00, 7340.00, 3180.00),
    (v, 'FY2024', 3960.00, 488.00, 6010.00, 2570.00),
    (v, 'FY2023', 3110.00, 301.00, 4880.00, 2080.00);

  -- KPIs
  delete from kpi_data where ipo_id = v;
  insert into kpi_data (ipo_id, metric, value, unit) values
    (v, 'ROE', 19.25, '%'),
    (v, 'ROCE', 22.40, '%'),
    (v, 'EPS', 6.81, 'INR'),
    (v, 'PE_POST', 24.40, 'x'),
    (v, 'RONW', 19.25, '%'),
    (v, 'DEBT_EQUITY', 0.42, 'x');

  -- Reservation
  delete from ipo_reservation where ipo_id = v;
  insert into ipo_reservation (ipo_id, category, shares_offered, percent_of_total) values
    (v, 'Market Maker', 110400, 5.09),
    (v, 'QIB',          1029200, 47.45),
    (v, 'NII',          309200, 14.26),
    (v, 'Retail',       720000, 33.20);

  -- Lot size tiers
  delete from lot_size_tier where ipo_id = v;
  insert into lot_size_tier (ipo_id, applicant, lots, shares, amount) values
    (v, 'Retail (Min)',  1, 800,  132800),
    (v, 'Retail (Max)',  1, 800,  132800),
    (v, 'HNI (Min)',     2, 1600, 265600);

  -- Important dates
  delete from important_dates where ipo_id = v;
  insert into important_dates (ipo_id, event, event_date, sort_order) values
    (v, 'IPO Open',           '2026-06-04', 1),
    (v, 'IPO Close',          '2026-06-08', 2),
    (v, 'Allotment',          '2026-06-09', 3),
    (v, 'Refund Initiation',  '2026-06-10', 4),
    (v, 'Demat Transfer',     '2026-06-10', 5),
    (v, 'Listing',            '2026-06-11', 6);

  -- Company info
  delete from company_info where ipo_id = v;
  insert into company_info (ipo_id, description, promoters, lead_managers, objectives, website_url) values
    (v,
     'UHM Vacation operates resorts and vacation-ownership properties across India, offering membership-based holiday packages and hospitality services.',
     'Mr. U. H. Mehta, Mrs. R. Mehta',
     'Beeline Capital Advisors Pvt Ltd',
     E'1. Funding capital expenditure for new resort properties\n2. Working capital requirements\n3. General corporate purposes',
     'https://www.uhmvacation.example');
end $$;
