// Smoke + unit tests for the IPO Tracker.

import 'package:flutter_test/flutter_test.dart';

import 'package:untitled_poi/global/constant/registrar_portal.dart';
import 'package:untitled_poi/features/ipo_detail/domain/allotment_model.dart';
import 'package:untitled_poi/features/home/domain/ipo_model.dart';
import 'package:untitled_poi/global/services/mock_data.dart';
import 'package:untitled_poi/global/utils/global_utility.dart';
import 'package:untitled_poi/global/utils/date_utility.dart';

void main() {
  group('MockData', () {
    test('returns SME current IPOs (UHM Vacation)', () {
      final smeCurrent = MockData.ipos(kind: IpoKind.sme, listed: false);
      expect(smeCurrent, isNotEmpty);
      expect(smeCurrent.first.companyName, 'UHM Vacation');
      expect(smeCurrent.first.kind, IpoKind.sme);
    });

    test('separates listed from current', () {
      final listed = MockData.ipos(kind: IpoKind.mainline, listed: true);
      expect(listed.every((i) => i.status == IpoStatus.listed), isTrue);

      final current = MockData.ipos(kind: IpoKind.mainline, listed: false);
      expect(current.every((i) => i.status != IpoStatus.listed), isTrue);
    });

    test('builds full detail aggregate with all tabs populated', () {
      final detail = MockData.detail('uhm-vacation');
      expect(detail.ipo.companyName, 'UHM Vacation');
      expect(detail.gmp, isNotEmpty);
      expect(detail.subscriptions, isNotEmpty);
      expect(detail.financials.length, 3);
      expect(detail.kpis, isNotEmpty);
      expect(detail.reservations, isNotEmpty);
      expect(detail.importantDates.length, 6);
      expect(detail.company, isNotNull);
      expect(detail.overallSubscription?.total, 2.36);
      expect(detail.dayWise.length, 3);
    });
  });

  group('GlobalUtility', () {
    test('formats Indian rupee grouping', () {
      expect(GlobalUtility.rupee(132800), '₹1,32,800');
    });

    test('compactRupee uses crore/lakh', () {
      expect(GlobalUtility.compactRupee(36000000), '₹3.60 Cr');
      expect(GlobalUtility.compactRupee(4820000), '₹48.20 Lakh');
    });

    test('priceBand renders a range', () {
      expect(GlobalUtility.priceBand(157, 166), '₹157 – ₹166');
      expect(GlobalUtility.priceBand(166, 166), '₹166');
    });

    test('times and percent', () {
      expect(GlobalUtility.times(2.36), '2.36x');
      expect(GlobalUtility.percent(57.97), '57.97%');
    });
  });

  group('DateUtility', () {
    test('range collapses same month/year', () {
      final r = DateUtility.range('2026-06-04', '2026-06-08');
      expect(r, '4 to 8 Jun, 2026');
    });
  });

  group('Allotment', () {
    test('registrar name maps to known portal', () {
      expect(RegistrarPortal.urlFor('Bigshare Services Pvt Ltd'),
          contains('bigshareonline'));
      expect(RegistrarPortal.urlFor('Link Intime India Pvt Ltd'),
          contains('linkintime'));
      expect(RegistrarPortal.urlFor('KFin Technologies'),
          contains('kfintech'));
      expect(RegistrarPortal.urlFor('Some Unknown Registrar'), isNull);
      expect(RegistrarPortal.urlFor(null), isNull);
    });

    test('parses backend result JSON', () {
      final r = AllotmentResult.fromJson({
        'outcome': 'MANUAL_CHECK_REQUIRED',
        'companyName': 'UHM Vacation',
        'registrar': 'Bigshare Services',
        'manualCheckUrl': 'https://ipo.bigshareonline.com/ipo_Allotment.html',
        'message': 'check manually',
      });
      expect(r.outcome, AllotmentOutcome.manualCheckRequired);
      expect(r.companyName, 'UHM Vacation');
      expect(r.manualCheckUrl, contains('bigshareonline'));
    });

    test('request serialises and omits blank application number', () {
      final json = const AllotmentRequest(ipoId: 'uhm-vacation', pan: 'ABCDE1234F')
          .toJson();
      expect(json['pan'], 'ABCDE1234F');
      expect(json.containsKey('applicationNumber'), isFalse);
    });
  });
}
