import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../constants/registrar_portal.dart';
import '../model/bean/ipo_model.dart';
import '../model/bean/ipo_detail_model.dart';
import '../model/bean/allotment_model.dart';
import 'api_service.dart';
import 'supabase_service.dart';

/// Single entry point for controllers. Reads from the FastAPI backend by default
/// (`/api/v1/ipos/*`). Supabase is only used when API is unavailable and keys
/// are configured.
class IpoRepository {
  final ApiService _api;
  final SupabaseService? _supabase;

  IpoRepository({ApiService? api, SupabaseService? supabase})
      : _api = api ?? ApiService(),
        _supabase = AppConfig.hasSupabase ? (supabase ?? SupabaseService()) : null;

  /// Polls the backend list endpoints (current / listed).
  Stream<List<IpoModel>> watchIpos({required IpoKind kind, required bool listed}) {
    return _apiWatchIpos(kind: kind, listed: listed);
  }

  Stream<List<IpoModel>> _apiWatchIpos({required IpoKind kind, required bool listed}) async* {
    yield await fetchIpos(kind: kind, listed: listed);
    yield* Stream.periodic(const Duration(seconds: 60))
        .asyncMap((_) => fetchIpos(kind: kind, listed: listed));
  }

  Future<List<IpoModel>> fetchIpos({required IpoKind kind, required bool listed}) async {
    if (AppConfig.hasApi) {
      try {
        return listed ? await _api.listed(kind) : await _api.current(kind);
      } catch (e) {
        debugPrint('API list failed: $e');
        if (_supabase != null) {
          return _supabase.fetchIpos(kind: kind, listed: listed);
        }
        rethrow;
      }
    }
    if (_supabase != null) {
      return _supabase.fetchIpos(kind: kind, listed: listed);
    }
    throw ApiException('No API configured. Start the backend on port 8081.');
  }

  Future<IpoDetailModel> fetchDetail(String id) async {
    if (AppConfig.hasApi) {
      try {
        return await _api.detail(id);
      } catch (e) {
        debugPrint('API detail failed: $e');
        if (_supabase != null) {
          return _supabase.fetchDetail(id);
        }
        rethrow;
      }
    }
    if (_supabase != null) {
      return _supabase.fetchDetail(id);
    }
    throw ApiException('No API configured. Start the backend on port 8081.');
  }

  /// Checks allotment via POST /api/v1/allotment.
  Future<AllotmentResult> checkAllotment(
    AllotmentRequest req, {
    String? registrarName,
    String? companyName,
  }) async {
    try {
      return await _api.checkAllotment(req);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Allotment API unreachable, offering manual link: $e');
      final url = RegistrarPortal.urlFor(registrarName);
      if (url == null) {
        return AllotmentResult(
          outcome: AllotmentOutcome.error,
          companyName: companyName,
          registrar: registrarName,
          message: 'Could not reach the allotment service and no registrar '
              'portal is known for this IPO.',
        );
      }
      return AllotmentResult(
        outcome: AllotmentOutcome.manualCheckRequired,
        companyName: companyName,
        registrar: registrarName,
        manualCheckUrl: url,
        message: 'Allotment service is offline. Tap to check on the official '
            '${registrarName ?? 'registrar'} portal.',
      );
    }
  }
}
