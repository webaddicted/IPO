/// User-facing strings, centralised so they can be localised later.
class StringConst {
  const StringConst._();

  static const String appName = 'IPO Tracker';

  // Tabs
  static const String currentIpo = 'Current IPO';
  static const String listedIpo = 'Listed IPO';

  // Bottom nav
  static const String mainlineIpo = 'MainLine IPO';
  static const String smeIpo = 'SME IPO';
  static const String offers = 'Offers';

  // Detail tabs (order matches the design)
  static const List<String> detailTabs = [
    'IPO Details',
    'Subscription',
    'Day Wise Sub',
    'Day Wise GMP',
    'Important Dates',
    'Lot Size',
    'Financials',
    'KPI',
    'Reservation',
    'About Company',
    'Objectives',
    'Disclaimer',
  ];

  // Status labels
  static const String upcoming = 'Upcoming';
  static const String open = 'Open';
  static const String closed = 'Closed';
  static const String listed = 'Listed';

  // Misc
  static const String checkAllotment = 'Check Allotment Status';
  static const String expectedGmp = 'Expected GMP';
  static const String lotSize = 'Lot Size';
  static const String priceRange = 'Price Range';
  static const String subscription = 'Subscription';
  static const String noData = 'No data available';
  static const String disclaimer =
      'IPO data shown here is aggregated from public sources and may be delayed '
      'or inaccurate. Grey Market Premium (GMP) is unofficial and speculative. '
      'This app does not provide investment advice. Always verify with the RHP '
      'and your broker before investing.';
}
