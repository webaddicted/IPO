import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../constants/api_const.dart';
import '../model/bean/ipo_model.dart';
import '../model/bean/ipo_detail_model.dart';
import '../model/bean/allotment_model.dart';

/// Talks to the Spring Boot REST API. Used for the rich detail aggregate
/// (the backend joins all child tables in one call).
class ApiService {
  final http.Client _client;
  ApiService([http.Client? client]) : _client = client ?? http.Client();

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${AppConfig.apiBaseUrl}$path').replace(queryParameters: query);

  Future<List<IpoModel>> current(IpoKind kind) async {
    final res = await _client
        .get(_uri(ApiConst.currentIpos, {'type': kind.name}))
        .timeout(const Duration(seconds: 12));
    return _parseList(res);
  }

  Future<List<IpoModel>> listed(IpoKind kind) async {
    final res = await _client
        .get(_uri(ApiConst.listedIpos, {'type': kind.name}))
        .timeout(const Duration(seconds: 12));
    return _parseList(res);
  }

  Future<IpoDetailModel> detail(String id) async {
    final res = await _client
        .get(_uri(ApiConst.ipoDetail(id)))
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw ApiException('detail ${res.statusCode}');
    }
    return IpoDetailModel.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<AllotmentResult> checkAllotment(AllotmentRequest req) async {
    final res = await _client
        .post(
          _uri(ApiConst.allotment),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(req.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = jsonDecode(res.body);
    if (res.statusCode == 400 && body is Map) {
      throw ApiException(body['error']?.toString() ?? 'Invalid request');
    }
    if (res.statusCode != 200) {
      throw ApiException('allotment ${res.statusCode}');
    }
    return AllotmentResult.fromJson((body as Map).cast<String, dynamic>());
  }

  List<IpoModel> _parseList(http.Response res) {
    if (res.statusCode != 200) {
      throw ApiException('list ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .whereType<Map>()
        .map((e) => IpoModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}
