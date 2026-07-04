import 'package:untitled_poi/global/utils/json_reader.dart';
import 'package:untitled_poi/features/home/domain/ipo_model.dart';

/// Full detail aggregate backing the IPO detail screen and all its tabs.
class IpoDetailModel {
  final IpoModel ipo;
  // Extended fields not present on the summary
  final num? issuePrice;
  final num? faceValue;
  final num? minInvestment;
  final String? issueType;
  final String? saleType;
  final num? totalIssueSizeShares;
  final num? totalIssueSizeAmount;
  final num? marketMakerShares;
  final String? registrar;

  final List<GmpPoint> gmp;
  final List<SubscriptionRow> subscriptions;
  final List<FinancialRow> financials;
  final List<KpiRow> kpis;
  final List<ReservationRow> reservations;
  final List<LotSizeRow> lotSizes;
  final List<ImportantDateRow> importantDates;
  final CompanyInfoModel? company;

  const IpoDetailModel({
    required this.ipo,
    this.issuePrice,
    this.faceValue,
    this.minInvestment,
    this.issueType,
    this.saleType,
    this.totalIssueSizeShares,
    this.totalIssueSizeAmount,
    this.marketMakerShares,
    this.registrar,
    this.gmp = const [],
    this.subscriptions = const [],
    this.financials = const [],
    this.kpis = const [],
    this.reservations = const [],
    this.lotSizes = const [],
    this.importantDates = const [],
    this.company,
  });

  SubscriptionRow? get overallSubscription {
    for (final s in subscriptions) {
      if (s.bucket == 'overall') return s;
    }
    return null;
  }

  List<SubscriptionRow> get dayWise =>
      subscriptions.where((s) => s.bucket != 'overall').toList()
        ..sort((a, b) => a.bucket.compareTo(b.bucket));

  factory IpoDetailModel.fromJson(Map<String, dynamic> json) {
    // API shape nests the entity under `ipo`; Supabase shape is flat.
    final ipoJson =
        (json['ipo'] as Map<String, dynamic>?) ?? json;
    final r = JsonReader(ipoJson);

    List<T> list<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final raw = json[key] ?? json[_snake(key)];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => fromJson(e.cast<String, dynamic>()))
            .toList();
      }
      return const [];
    }

    final companyRaw = json['company'];
    Map<String, dynamic>? companyMap;
    if (companyRaw is Map) {
      companyMap = Map<String, dynamic>.from(companyRaw.cast<String, dynamic>());
    }

    final leadManagers = list('leadManagers', (m) => m);
    if (leadManagers.isNotEmpty) {
      final names = leadManagers
          .map((m) => m['name'])
          .whereType<String>()
          .where((n) => n.isNotEmpty)
          .join(', ');
      if (names.isNotEmpty) {
        companyMap ??= <String, dynamic>{};
        companyMap['leadManagers'] = names;
      }
    }

    return IpoDetailModel(
      ipo: IpoModel.fromJson(ipoJson),
      issuePrice: r.number(JsonReader.alias('issue_price')),
      faceValue: r.number(JsonReader.alias('face_value')),
      minInvestment: r.number(JsonReader.alias('min_investment')),
      issueType: r.str(JsonReader.alias('issue_type')),
      saleType: r.str(JsonReader.alias('sale_type')),
      totalIssueSizeShares: r.number(JsonReader.alias('total_issue_size_shares')),
      totalIssueSizeAmount: r.number(JsonReader.alias('total_issue_size_amount')),
      marketMakerShares: r.number(JsonReader.alias('market_maker_shares')),
      registrar: JsonReader(json).str([
        ...JsonReader.alias('registrar_name'),
        'registrar',
      ]) ?? r.str([...JsonReader.alias('registrar_name'), 'registrar']),
      gmp: list('gmp', GmpPoint.fromJson),
      subscriptions: list('subscriptions', SubscriptionRow.fromJson),
      financials: list('financials', FinancialRow.fromJson),
      kpis: list('kpis', KpiRow.fromJson),
      reservations: list('reservations', ReservationRow.fromJson),
      lotSizes: list('lotSizes', LotSizeRow.fromJson),
      importantDates: list('importantDates', ImportantDateRow.fromJson),
      company: companyMap != null ? CompanyInfoModel.fromJson(companyMap) : null,
    );
  }

  static String _snake(String camel) {
    return camel.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
  }
}

class GmpPoint {
  final num? price;
  final num? percent;
  final num? estimatedListing;
  final num? issuePrice;
  final DateTime? recordedAt;
  const GmpPoint({
    this.price,
    this.percent,
    this.estimatedListing,
    this.issuePrice,
    this.recordedAt,
  });

  factory GmpPoint.fromJson(Map<String, dynamic> j) {
    final r = JsonReader(j);
    return GmpPoint(
      price: r.number(JsonReader.alias('gmp_price')),
      percent: r.number(JsonReader.alias('gmp_percent')),
      estimatedListing: r.number(JsonReader.alias('estimated_listing_price')),
      issuePrice: r.number(JsonReader.alias('issue_price')),
      recordedAt: r.date(JsonReader.alias('recorded_at')),
    );
  }
}

class SubscriptionRow {
  final String bucket;
  final num? total;
  final num? qib;
  final num? nii;
  final num? retail;
  final num? employee;
  final num? marketMaker;
  const SubscriptionRow({
    required this.bucket,
    this.total,
    this.qib,
    this.nii,
    this.retail,
    this.employee,
    this.marketMaker,
  });

  factory SubscriptionRow.fromJson(Map<String, dynamic> j) {
    final r = JsonReader(j);
    return SubscriptionRow(
      bucket: r.str(['bucket']) ?? 'overall',
      total: r.number(JsonReader.alias('total_subscription')),
      qib: r.number(JsonReader.alias('qib_subscription')),
      nii: r.number(JsonReader.alias('nii_subscription')),
      retail: r.number(JsonReader.alias('retail_subscription')),
      employee: r.number(JsonReader.alias('employee_subscription')),
      marketMaker: r.number(JsonReader.alias('market_maker_subscription')),
    );
  }
}

class FinancialRow {
  final String? period;
  final num? revenue;
  final num? pat;
  final num? ebitda;
  final num? pbt;
  final num? totalAssets;
  final num? netWorth;
  final num? reservesSurplus;
  final num? totalBorrowing;
  const FinancialRow({
    this.period,
    this.revenue,
    this.pat,
    this.ebitda,
    this.pbt,
    this.totalAssets,
    this.netWorth,
    this.reservesSurplus,
    this.totalBorrowing,
  });

  factory FinancialRow.fromJson(Map<String, dynamic> j) {
    final r = JsonReader(j);
    return FinancialRow(
      period: r.str(['period']),
      revenue: r.number(['revenue']),
      pat: r.number(JsonReader.alias('profit_after_tax')),
      ebitda: r.number(['ebitda']),
      pbt: r.number(JsonReader.alias('profit_before_tax')),
      totalAssets: r.number(JsonReader.alias('total_assets')),
      netWorth: r.number(JsonReader.alias('net_worth')),
      reservesSurplus: r.number([
        ...JsonReader.alias('reserves_and_surplus'),
        'reserves_surplus',
      ]),
      totalBorrowing: r.number(JsonReader.alias('total_borrowing')),
    );
  }
}

class KpiRow {
  final String metric;
  final num? value;
  final String? unit;
  const KpiRow({required this.metric, this.value, this.unit});

  factory KpiRow.fromJson(Map<String, dynamic> j) {
    final r = JsonReader(j);
    return KpiRow(
      metric: r.str(['metric']) ?? '',
      value: r.number(['value']),
      unit: r.str(['unit']),
    );
  }
}

class ReservationRow {
  final String category;
  final num? shares;
  final num? percent;
  const ReservationRow({required this.category, this.shares, this.percent});

  factory ReservationRow.fromJson(Map<String, dynamic> j) {
    final r = JsonReader(j);
    return ReservationRow(
      category: r.str(['category']) ?? '',
      shares: r.number(JsonReader.alias('shares_offered')),
      percent: r.number([
        ...JsonReader.alias('percent_of_total'),
        ...JsonReader.alias('percent_of_net_issue'),
      ]),
    );
  }
}

class LotSizeRow {
  final String applicant;
  final int? lots;
  final num? shares;
  final num? amount;
  const LotSizeRow({required this.applicant, this.lots, this.shares, this.amount});

  factory LotSizeRow.fromJson(Map<String, dynamic> j) {
    final r = JsonReader(j);
    return LotSizeRow(
      applicant: r.str(['applicant']) ?? '',
      lots: r.integer(['lots']),
      shares: r.number(['shares']),
      amount: r.number(['amount']),
    );
  }
}

class ImportantDateRow {
  final String event;
  final DateTime? date;
  final int sortOrder;
  const ImportantDateRow({required this.event, this.date, this.sortOrder = 0});

  factory ImportantDateRow.fromJson(Map<String, dynamic> j) {
    final r = JsonReader(j);
    return ImportantDateRow(
      event: r.str(['event']) ?? '',
      date: r.date(JsonReader.alias('event_date')),
      sortOrder: r.integer(JsonReader.alias('sort_order')) ?? 0,
    );
  }
}

class CompanyInfoModel {
  final String? description;
  final String? industry;
  final String? businessSegment;
  final String? productDetails;
  final String? manufacturingLocation;
  final String? customerSegment;
  final String? exportInfo;
  final String? promoters;
  final String? leadManagers;
  final String? objectives;
  final String? websiteUrl;
  const CompanyInfoModel({
    this.description,
    this.industry,
    this.businessSegment,
    this.productDetails,
    this.manufacturingLocation,
    this.customerSegment,
    this.exportInfo,
    this.promoters,
    this.leadManagers,
    this.objectives,
    this.websiteUrl,
  });

  factory CompanyInfoModel.fromJson(Map<String, dynamic> j) {
    final r = JsonReader(j);
    return CompanyInfoModel(
      description: r.str(['description']),
      industry: r.str(['industry']),
      businessSegment: r.str(JsonReader.alias('business_segment')),
      productDetails: r.str(JsonReader.alias('product_details')),
      manufacturingLocation: r.str(JsonReader.alias('manufacturing_location')),
      customerSegment: r.str(JsonReader.alias('customer_segment')),
      exportInfo: r.str(JsonReader.alias('export_info')),
      promoters: r.str(['promoters']),
      leadManagers: r.str(JsonReader.alias('lead_managers')),
      objectives: r.str(['objectives']),
      websiteUrl: r.str(JsonReader.alias('website_url')),
    );
  }
}
