/// Supabase Postgres table names — all prefixed with `ipo_` for shared-project namespacing.
abstract final class SupabaseTables {
  static const String ipos = 'ipo_ipos';
  static const String companyProfiles = 'ipo_company_profiles';
  static const String ipoContacts = 'ipo_contacts';
  static const String leadManagers = 'ipo_lead_managers';
  static const String importantDates = 'ipo_important_dates';
  static const String lotSizeTiers = 'ipo_lot_size_tiers';
  static const String ipoReservations = 'ipo_reservations';
  static const String anchorInvestors = 'ipo_anchor_investors';
  static const String ipoReviews = 'ipo_reviews';
  static const String drhpMilestones = 'ipo_drhp_milestones';
  static const String financialPeriods = 'ipo_financial_periods';
  static const String kpiMetrics = 'ipo_kpi_metrics';
  static const String subscriptionSnapshots = 'ipo_subscription_snapshots';
  static const String gmpHistory = 'ipo_gmp_history';
  static const String peerComparisons = 'ipo_peer_comparisons';
}
