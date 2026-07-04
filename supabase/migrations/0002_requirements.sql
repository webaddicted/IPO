-- ============================================================================
-- Requirements gap columns (listed price, company profile, financials, GMP, sub)
-- ============================================================================

alter table ipos
  add column if not exists listed_price numeric(12,2),
  add column if not exists estimated_listing_price numeric(12,2);

alter table company_info
  add column if not exists industry varchar(255),
  add column if not exists business_segment text,
  add column if not exists product_details text,
  add column if not exists manufacturing_location text,
  add column if not exists customer_segment text,
  add column if not exists export_info text;

alter table financial_data
  add column if not exists ebitda numeric(16,2),
  add column if not exists profit_before_tax numeric(16,2),
  add column if not exists reserves_and_surplus numeric(16,2);

alter table subscription_data
  add column if not exists market_maker_subscription numeric(10,2),
  add column if not exists subscription_date date;

alter table gmp_data
  add column if not exists issue_price numeric(12,2);
