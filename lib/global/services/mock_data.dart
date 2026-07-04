import 'package:untitled_poi/features/home/domain/ipo_model.dart';
import 'package:untitled_poi/features/ipo_detail/domain/ipo_detail_model.dart';

/// Bundled sample data mirroring the Supabase seed, so the app is fully
/// demoable with no backend configured.
class MockData {
  const MockData._();

  static final List<Map<String, dynamic>> _ipos = [
    {
      'id': 'uhm-vacation',
      'company_name': 'UHM Vacation',
      'ipo_type': 'sme',
      'status': 'closed',
      'offer_price_min': 157,
      'offer_price_max': 166,
      'issue_price': 166,
      'face_value': 10,
      'lot_size': 800,
      'min_investment': 132800,
      'open_date': '2026-06-04',
      'close_date': '2026-06-08',
      'listing_date': '2026-06-11',
      'listing_at': 'BSE SME',
      'issue_type': 'Bookbuilding IPO',
      'sale_type': 'Fresh capital cum OFS',
      'total_issue_size_shares': 2168800,
      'total_issue_size_amount': 36000000,
      'market_maker_shares': 110400,
      'latest_gmp': 0,
      'latest_gmp_percent': 0,
      'latest_subscription': 2.36,
      'registrar': 'Bigshare Services Pvt Ltd',
    },
    {
      'id': 'orbit-mobility',
      'company_name': 'Orbit Mobility',
      'ipo_type': 'mainline',
      'status': 'open',
      'offer_price_min': 130,
      'offer_price_max': 138,
      'face_value': 2,
      'lot_size': 100,
      'min_investment': 13800,
      'open_date': '2026-06-23',
      'close_date': '2026-06-25',
      'listing_date': '2026-06-30',
      'listing_at': 'NSE, BSE',
      'issue_type': 'Bookbuilding IPO',
      'total_issue_size_amount': 2553000000,
      'latest_gmp': 80,
      'latest_gmp_percent': 57.97,
      'latest_subscription': 12.4,
      'registrar': 'Link Intime India Pvt Ltd',
    },
    {
      'id': 'vedant-greens',
      'company_name': 'Vedant Greens',
      'ipo_type': 'mainline',
      'status': 'upcoming',
      'offer_price_min': 220,
      'offer_price_max': 232,
      'face_value': 5,
      'lot_size': 61,
      'open_date': '2026-06-28',
      'close_date': '2026-07-01',
      'listing_date': '2026-07-04',
      'listing_at': 'NSE, BSE',
      'latest_gmp': 45,
      'latest_gmp_percent': 19.40,
    },
    {
      'id': 'silverline-tech',
      'company_name': 'Silverline Tech',
      'ipo_type': 'mainline',
      'status': 'listed',
      'issue_price': 410,
      'face_value': 10,
      'lot_size': 36,
      'open_date': '2026-05-20',
      'close_date': '2026-05-22',
      'listing_date': '2026-05-27',
      'listing_at': 'NSE, BSE',
      'latest_subscription': 48.6,
    },
  ];

  static List<IpoModel> ipos({required IpoKind kind, required bool listed}) {
    return _ipos
        .where((m) =>
            ipoKindFrom(m['ipo_type'] as String?) == kind &&
            ((m['status'] == 'listed') == listed))
        .map(IpoModel.fromJson)
        .toList();
  }

  static IpoDetailModel detail(String id) {
    final base = _ipos.firstWhere((m) => m['id'] == id,
        orElse: () => _ipos.first);

    final detail = Map<String, dynamic>.from(base);
    if (id == 'uhm-vacation') {
      detail['gmp'] = [
        {'gmp_price': 0, 'gmp_percent': 0, 'recorded_at': '2026-06-06T10:00:00Z'},
        {'gmp_price': 0, 'gmp_percent': 0, 'recorded_at': '2026-06-07T10:00:00Z'},
        {'gmp_price': 0, 'gmp_percent': 0, 'recorded_at': '2026-06-08T10:00:00Z'},
      ];
      detail['subscriptions'] = [
        {'bucket': 'overall', 'total_subscription': 2.36, 'qib_subscription': 1.10, 'nii_subscription': 3.40, 'retail_subscription': 2.58},
        {'bucket': 'day1', 'total_subscription': 0.42, 'qib_subscription': 0.00, 'nii_subscription': 0.55, 'retail_subscription': 0.71},
        {'bucket': 'day2', 'total_subscription': 1.18, 'qib_subscription': 0.30, 'nii_subscription': 1.90, 'retail_subscription': 1.44},
        {'bucket': 'day3', 'total_subscription': 2.36, 'qib_subscription': 1.10, 'nii_subscription': 3.40, 'retail_subscription': 2.58},
      ];
      detail['financials'] = [
        {'period': 'FY2025', 'revenue': 4820, 'profit_after_tax': 612, 'total_assets': 7340, 'net_worth': 3180},
        {'period': 'FY2024', 'revenue': 3960, 'profit_after_tax': 488, 'total_assets': 6010, 'net_worth': 2570},
        {'period': 'FY2023', 'revenue': 3110, 'profit_after_tax': 301, 'total_assets': 4880, 'net_worth': 2080},
      ];
      detail['kpis'] = [
        {'metric': 'ROE', 'value': 19.25, 'unit': '%'},
        {'metric': 'ROCE', 'value': 22.40, 'unit': '%'},
        {'metric': 'EPS', 'value': 6.81, 'unit': 'INR'},
        {'metric': 'PE_POST', 'value': 24.40, 'unit': 'x'},
        {'metric': 'RONW', 'value': 19.25, 'unit': '%'},
        {'metric': 'DEBT_EQUITY', 'value': 0.42, 'unit': 'x'},
      ];
      detail['reservations'] = [
        {'category': 'Market Maker', 'shares_offered': 110400, 'percent_of_total': 5.09},
        {'category': 'QIB', 'shares_offered': 1029200, 'percent_of_total': 47.45},
        {'category': 'NII', 'shares_offered': 309200, 'percent_of_total': 14.26},
        {'category': 'Retail', 'shares_offered': 720000, 'percent_of_total': 33.20},
      ];
      detail['lotSizes'] = [
        {'applicant': 'Retail (Min)', 'lots': 1, 'shares': 800, 'amount': 132800},
        {'applicant': 'Retail (Max)', 'lots': 1, 'shares': 800, 'amount': 132800},
        {'applicant': 'HNI (Min)', 'lots': 2, 'shares': 1600, 'amount': 265600},
      ];
      detail['importantDates'] = [
        {'event': 'IPO Open', 'event_date': '2026-06-04', 'sort_order': 1},
        {'event': 'IPO Close', 'event_date': '2026-06-08', 'sort_order': 2},
        {'event': 'Allotment', 'event_date': '2026-06-09', 'sort_order': 3},
        {'event': 'Refund Initiation', 'event_date': '2026-06-10', 'sort_order': 4},
        {'event': 'Demat Transfer', 'event_date': '2026-06-10', 'sort_order': 5},
        {'event': 'Listing', 'event_date': '2026-06-11', 'sort_order': 6},
      ];
      detail['company'] = {
        'description':
            'UHM Vacation operates resorts and vacation-ownership properties across India, offering membership-based holiday packages and hospitality services.',
        'promoters': 'Mr. U. H. Mehta, Mrs. R. Mehta',
        'lead_managers': 'Beeline Capital Advisors Pvt Ltd',
        'objectives':
            '1. Funding capital expenditure for new resort properties\n2. Working capital requirements\n3. General corporate purposes',
        'website_url': 'https://www.uhmvacation.example',
      };
    }
    return IpoDetailModel.fromJson(detail);
  }
}
