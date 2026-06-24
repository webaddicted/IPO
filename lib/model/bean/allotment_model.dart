import '../../utils/json_reader.dart';

enum AllotmentOutcome {
  allotted,
  notAllotted,
  notFound,
  manualCheckRequired,
  error,
}

AllotmentOutcome _outcomeFrom(String? s) {
  switch (s) {
    case 'ALLOTTED':
      return AllotmentOutcome.allotted;
    case 'NOT_ALLOTTED':
      return AllotmentOutcome.notAllotted;
    case 'NOT_FOUND':
      return AllotmentOutcome.notFound;
    case 'MANUAL_CHECK_REQUIRED':
      return AllotmentOutcome.manualCheckRequired;
    default:
      return AllotmentOutcome.error;
  }
}

class AllotmentRequest {
  final String ipoId;
  final String pan;
  final String? applicationNumber;

  const AllotmentRequest({
    required this.ipoId,
    required this.pan,
    this.applicationNumber,
  });

  Map<String, dynamic> toJson() => {
        'ipoId': ipoId,
        'pan': pan,
        if (applicationNumber != null && applicationNumber!.isNotEmpty)
          'applicationNumber': applicationNumber,
      };
}

class AllotmentResult {
  final AllotmentOutcome outcome;
  final String? companyName;
  final String? registrar;
  final String? manualCheckUrl;
  final int? sharesApplied;
  final int? sharesAllotted;
  final String? message;

  const AllotmentResult({
    required this.outcome,
    this.companyName,
    this.registrar,
    this.manualCheckUrl,
    this.sharesApplied,
    this.sharesAllotted,
    this.message,
  });

  factory AllotmentResult.fromJson(Map<String, dynamic> json) {
    final r = JsonReader(json);
    return AllotmentResult(
      outcome: _outcomeFrom(r.str(['outcome'])),
      companyName: r.str(JsonReader.alias('company_name')),
      registrar: r.str(['registrar']),
      manualCheckUrl: r.str(JsonReader.alias('manual_check_url')),
      sharesApplied: r.integer(JsonReader.alias('shares_applied')),
      sharesAllotted: r.integer(JsonReader.alias('shares_allotted')),
      message: r.str(['message']),
    );
  }
}
