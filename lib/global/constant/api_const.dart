/// REST endpoint paths for the FastAPI backend.
class ApiConst {
  const ApiConst._();

  static const String basicIpos = '/api/v1/ipos/basic';
  static const String currentIpos = '/api/v1/ipos/current';
  static const String listedIpos = '/api/v1/ipos/listed';
  static String ipoDetail(String id) => '/api/v1/ipos/$id';
  static String ipoGmp(String id) => '/api/v1/ipos/$id/gmp';
  static String ipoSubscription(String id) => '/api/v1/ipos/$id/subscription';
  static const String allotment = '/api/v1/allotment';
}
