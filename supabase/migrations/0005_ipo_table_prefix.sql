-- ============================================================================
-- Rename all IPO tables to ipo_ prefix (shared Supabase namespacing)
-- Safe to run on databases created with migration 0003 (unprefixed names).
-- ============================================================================

-- Realtime: remove old publication entry before rename
alter publication supabase_realtime drop table if exists ipos;

-- Master
alter table if exists ipos rename to ipo_ipos;

-- Child tables without existing ipo_ prefix
alter table if exists company_profiles rename to ipo_company_profiles;
alter table if exists lead_managers rename to ipo_lead_managers;
alter table if exists important_dates rename to ipo_important_dates;
alter table if exists lot_size_tiers rename to ipo_lot_size_tiers;
alter table if exists anchor_investors rename to ipo_anchor_investors;
alter table if exists drhp_milestones rename to ipo_drhp_milestones;
alter table if exists financial_periods rename to ipo_financial_periods;
alter table if exists kpi_metrics rename to ipo_kpi_metrics;
alter table if exists subscription_snapshots rename to ipo_subscription_snapshots;
alter table if exists gmp_history rename to ipo_gmp_history;
alter table if exists peer_comparisons rename to ipo_peer_comparisons;

-- ipo_contacts, ipo_reservations, ipo_reviews already have the prefix — no rename

-- Rename indexes (optional clarity; Postgres keeps them working after table rename)
alter index if exists idx_ipos_chittorgarh_id rename to idx_ipo_ipos_chittorgarh_id;
alter index if exists idx_ipos_status rename to idx_ipo_ipos_status;
alter index if exists idx_ipos_type rename to idx_ipo_ipos_type;
alter index if exists idx_lead_managers_ipo rename to idx_ipo_lead_managers_ipo;
alter index if exists idx_gmp_history_ipo rename to idx_ipo_gmp_history_ipo;
alter index if exists idx_anchor_investors_ipo rename to idx_ipo_anchor_investors_ipo;

-- Recreate updated_at trigger on renamed master table
drop trigger if exists trg_ipos_updated_at on ipo_ipos;
drop trigger if exists trg_ipo_ipos_updated_at on ipo_ipos;
create trigger trg_ipo_ipos_updated_at
  before update on ipo_ipos
  for each row execute function set_updated_at();

-- Re-enable realtime on renamed master table
alter publication supabase_realtime add table ipo_ipos;
