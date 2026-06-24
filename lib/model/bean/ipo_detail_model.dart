import '../../utils/json_reader.dart';
import 'ipo_model.dart';

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
      final raw = json[key];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => fromJson(e.cast<String, dynamic>()))
            .toList();
      }
      return const [];
    }

    final companyRaw = json['company'];

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
      registrar: r.str(['registrar']),
      gmp: list('gmp', GmpPoint.fromJson),
      subscriptions: list('subscriptions', SubscriptionRow.fromJson),
      financials: list('financials', FinancialRow.fromJson),
      kpis: list('kpis', KpiRow.fromJson),
      reservations: list('reservations', ReservationRow.fromJson),
      lotSizes: list('lotSizes', LotSizeRow.fromJson),
      importantDates: list('importantDates', ImportantDateRow.fromJson),
      company: companyRaw is Map
          ? CompanyInfoModel.fromJson(companyRaw.cast<String, dynamic>())
          : null,
    );
  }
}

class GmpPoint {
  final num? price;
  final num? percent;
  final DateTime? recordedAt;
  const GmpPoint({this.price, this.percent, this.recordedAt});

  factory GmpPoint.fromJson(Map<String, dynamic> j) {
    final r = JsonReader(j);
    return GmpPoint(
      price: r.number(JsonReader.alias('gmp_price')),
      percent: r.number(JsonReader.alias('gmp_percent')),
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
  const SubscriptionRow({
    required this.bucket,
    this.total,
    this.qib,
    this.nii,
    this.retail,
    this.employee,
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
    );
  }
}

class FinancialRow {
  final String? period;
  final num? revenue;
  final num? pat;
  final num? totalAssets;
  final num? netWorth;
  const FinancialRow(
      {this.period, this.revenue, this.pat, this.totalAssets, this.netWorth});

  factory FinancialRow.fromJson(Map<String, dynamic> j) {
    final r = JsonReader(j);
    return FinancialRow(
      period: r.str(['period']),
      revenue: r.number(['revenue']),
      pat: r.number(JsonReader.alias('profit_after_tax')),
      totalAssets: r.number(JsonReader.alias('total_assets')),
      netWorth: r.number(JsonReader.alias('net_worth')),
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
      percent: r.number(JsonReader.alias('percent_of_total')),
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
  final String? promoters;
  final String? leadManagers;
  final String? objectives;
  final String? websiteUrl;
  const CompanyInfoModel({
    this.description,
    this.promoters,
    this.leadManagers,
    this.objectives,
    this.websiteUrl,
  });

  factory CompanyInfoModel.fromJson(Map<String, dynamic> j) {
    final r = JsonReader(j);
    return CompanyInfoModel(
      description: r.str(['description']),
      promoters: r.str(['promoters']),
      leadManagers: r.str(JsonReader.alias('lead_managers')),
      objectives: r.str(['objectives']),
      websiteUrl: r.str(JsonReader.alias('website_url')),
    );
  }
}
