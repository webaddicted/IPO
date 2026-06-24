import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../constants/registrar_portal.dart';
import '../model/bean/ipo_model.dart';
import '../model/bean/ipo_detail_model.dart';
import '../model/bean/allotment_model.dart';
import 'api_service.dart';
import 'mock_data.dart';
import 'supabase_service.dart';

/// Single entry point the controllers use. Implements the chosen hybrid policy:
///
///  - **Lists**: prefer Supabase realtime; else Supabase fetch; else mock.
///  - **Detail**: prefer the Spring API aggregate; else Supabase; else mock.
///
/// Every path degrades gracefully so the UI always has something to show.
class IpoRepository {
  final ApiService _api;
  final SupabaseService _supabase;

  IpoRepository({ApiService? api, SupabaseService? supabase})
      : _api = api ?? ApiService(),
        _supabase = supabase ?? SupabaseService();

  /// Realtime stream when Supabase is configured, otherwise a single-shot
  /// stream from the API/mock so callers can treat both uniformly.
  Stream<List<IpoModel>> watchIpos({required IpoKind kind, required bool listed}) {
    if (AppConfig.hasSupabase) {
      return _supabase.watchIpos(kind: kind, listed: listed);
    }
    return Stream.fromFuture(fetchIpos(kind: kind, listed: listed));
  }

  Future<List<IpoModel>> fetchIpos({required IpoKind kind, required bool listed}) async {
    if (AppConfig.hasSupabase) {
      try {
        return await _supabase.fetchIpos(kind: kind, listed: listed);
      } catch (e) {
        debugPrint('Supabase list failed, falling back: $e');
      }
    }
    try {
      return listed ? await _api.listed(kind) : await _api.current(kind);
    } catch (e) {
      debugPrint('API list failed, using mock: $e');
      return MockData.ipos(kind: kind, listed: listed);
    }
  }

  Future<IpoDetailModel> fetchDetail(String id) async {
    try {
      return await _api.detail(id);
    } catch (e) {
      debugPrint('API detail failed: $e');
    }
    if (AppConfig.hasSupabase) {
      try {
        return await _supabase.fetchDetail(id);
      } catch (e) {
        debugPrint('Supabase detail failed: $e');
      }
    }
    return MockData.detail(id);
  }

  /// Checks allotment via the backend. If the backend is unreachable, degrades
  /// to a manual-check result pointing at the registrar's official portal
  /// (resolved client-side from [registrarName]).
  Future<AllotmentResult> checkAllotment(
    AllotmentRequest req, {
    String? registrarName,
    String? companyName,
  }) async {
    try {
      return await _api.checkAllotment(req);
    } on ApiException {
      rethrow; // validation / known API errors should surface to the user
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
