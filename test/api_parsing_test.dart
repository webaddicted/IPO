import 'package:flutter_test/flutter_test.dart';
import 'package:untitled_poi/model/bean/ipo_detail_model.dart';
import 'package:untitled_poi/model/bean/ipo_model.dart';

void main() {
  group('IpoModel.fromJson', () {
    test('parses camelCase list item from FastAPI', () {
      final ipo = IpoModel.fromJson({
        'id': '1731e794-cf81-4a02-92f5-61877c9b22f0',
        'companyName': 'CSM Technologies IPO',
        'ipoType': 'mainline',
        'status': 'listed',
        'offerPriceMin': '113.00',
        'offerPriceMax': '113.00',
        'issuePrice': '113.00',
        'listedPrice': '107.35',
        'lotSize': 132,
        'openDate': '2026-06-24',
        'closeDate': '2026-06-29',
        'listingDate': '2026-07-02',
        'listingAt': 'BSE, NSE',
      });

      expect(ipo.companyName, 'CSM Technologies IPO');
      expect(ipo.kind, IpoKind.mainline);
      expect(ipo.status, IpoStatus.listed);
      expect(ipo.listedPrice, 107.35);
    });
  });

  group('IpoDetailModel.fromJson', () {
    test('parses nested API aggregate', () {
      final detail = IpoDetailModel.fromJson({
        'ipo': {
          'id': 'f121651b-d52d-40c2-b64f-198a8012ecb4',
          'companyName': 'Kusumgar IPO',
          'ipoType': 'mainline',
          'status': 'upcoming',
          'registrar': 'Bigshare Services Pvt.Ltd.',
          'offerPriceMin': '398.00',
          'offerPriceMax': '419.00',
          'lotSize': 35,
        },
        'gmp': [
          {
            'gmpPrice': '140.00',
            'gmpPercent': '33.41',
            'recordedAt': '2026-07-03T02:38:44.999481Z',
          },
        ],
        'subscriptions': [
          {
            'bucket': 'overall',
            'totalSubscription': '2.5',
            'qibSubscription': '1.2',
            'niiSubscription': '3.1',
            'retailSubscription': '4.0',
          },
        ],
        'lotSizes': [
          {'applicant': 'Retail', 'lots': 1, 'shares': 35, 'amount': '8377.00'},
        ],
        'importantDates': [
          {'event': 'IPO Open', 'eventDate': '2026-07-08', 'sortOrder': 1},
        ],
        'reservations': [
          {
            'category': 'QIB',
            'sharesOffered': 1000,
            'percentOfNetIssue': '50.00',
          },
        ],
        'company': {
          'description': 'Test company',
          'promoters': 'Founder A',
          'objectives': 'Expansion',
        },
        'leadManagers': [
          {'name': 'Axis Capital'},
          {'name': 'ICICI Securities'},
        ],
      });

      expect(detail.ipo.companyName, 'Kusumgar IPO');
      expect(detail.registrar, 'Bigshare Services Pvt.Ltd.');
      expect(detail.gmp, hasLength(1));
      expect(detail.gmp.first.price, 140.0);
      expect(detail.overallSubscription?.total, 2.5);
      expect(detail.lotSizes, hasLength(1));
      expect(detail.importantDates, hasLength(1));
      expect(detail.reservations.first.percent, 50.0);
      expect(detail.company?.leadManagers, 'Axis Capital, ICICI Securities');
    });
  });
}
