import 'package:untitled_poi/global/utils/json_reader.dart';

enum IpoKind { mainline, sme }

enum IpoStatus { upcoming, open, closed, listed }

IpoKind ipoKindFrom(String? s) =>
    IpoKind.values.firstWhere((e) => e.name == s, orElse: () => IpoKind.mainline);

IpoStatus ipoStatusFrom(String? s) =>
    IpoStatus.values.firstWhere((e) => e.name == s, orElse: () => IpoStatus.upcoming);

/// Summary record shown on the listing cards.
class IpoModel {
  final String id;
  final String companyName;
  final String? logoUrl;
  final IpoKind kind;
  final IpoStatus status;
  final num? offerPriceMin;
  final num? offerPriceMax;
  final int? lotSize;
  final DateTime? openDate;
  final DateTime? closeDate;
  final DateTime? listingDate;
  final String? listingAt;
  final num? latestGmp;
  final num? latestGmpPercent;
  final num? issuePrice;
  final num? listedPrice;
  final num? estimatedListingPrice;
  final num? latestSubscription;

  const IpoModel({
    required this.id,
    required this.companyName,
    this.logoUrl,
    required this.kind,
    required this.status,
    this.offerPriceMin,
    this.offerPriceMax,
    this.issuePrice,
    this.listedPrice,
    this.lotSize,
    this.openDate,
    this.closeDate,
    this.listingDate,
    this.listingAt,
    this.latestGmp,
    this.latestGmpPercent,
    this.estimatedListingPrice,
    this.latestSubscription,
  });

  factory IpoModel.fromJson(Map<String, dynamic> json) {
    final r = JsonReader(json);
    return IpoModel(
      id: r.str(['id']) ?? '',
      companyName: r.str(JsonReader.alias('company_name')) ?? '—',
      logoUrl: r.str(JsonReader.alias('logo_url')),
      kind: ipoKindFrom(r.str(JsonReader.alias('ipo_type'))),
      status: ipoStatusFrom(r.str(['status'])),
      offerPriceMin: r.number(JsonReader.alias('offer_price_min')),
      offerPriceMax: r.number(JsonReader.alias('offer_price_max')),
      issuePrice: r.number(JsonReader.alias('issue_price')),
      listedPrice: r.number(JsonReader.alias('listed_price')),
      lotSize: r.integer(JsonReader.alias('lot_size')),
      openDate: r.date(JsonReader.alias('open_date')),
      closeDate: r.date(JsonReader.alias('close_date')),
      listingDate: r.date(JsonReader.alias('listing_date')),
      listingAt: r.str(JsonReader.alias('listing_at')),
      latestGmp: r.number(JsonReader.alias('latest_gmp')),
      latestGmpPercent: r.number(JsonReader.alias('latest_gmp_percent')),
      estimatedListingPrice: r.number(JsonReader.alias('estimated_listing_price')),
      latestSubscription: r.number(JsonReader.alias('latest_subscription')),
    );
  }
}
