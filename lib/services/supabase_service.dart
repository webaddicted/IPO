import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../model/bean/ipo_model.dart';
import '../model/bean/ipo_detail_model.dart';

/// Reads directly from Supabase (Postgres) using the anon key — including a
/// realtime stream of the IPO list. Only available when [AppConfig.hasSupabase].
class SupabaseService {
  SupabaseClient get _db => Supabase.instance.client;

  /// One-time initialisation. Safe to call when keys are missing (no-op).
  static Future<void> init() async {
    if (!AppConfig.hasSupabase) return;
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // Supabase renamed anon key -> publishable key; the value is the same one
      // from Project Settings → API.
      publishableKey: AppConfig.supabasePublishableKey,
    );
  }

  /// Realtime stream of IPOs filtered to a kind + listed/current split.
  Stream<List<IpoModel>> watchIpos({required IpoKind kind, required bool listed}) {
    return _db
        .from('ipos')
        .stream(primaryKey: ['id'])
        .eq('ipo_type', kind.name)
        .order('company_name')
        .map((rows) => rows
            .map((e) => IpoModel.fromJson(e))
            .where((i) => listed ? i.status == IpoStatus.listed : i.status != IpoStatus.listed)
            .toList());
  }

  Future<List<IpoModel>> fetchIpos({required IpoKind kind, required bool listed}) async {
    var query = _db.from('ipos').select().eq('ipo_type', kind.name);
    query = listed ? query.eq('status', 'listed') : query.neq('status', 'listed');
    final rows = await query.order('company_name');
    return (rows as List)
        .map((e) => IpoModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Assembles the full detail aggregate from the child tables (0003 schema).
  Future<IpoDetailModel> fetchDetail(String id) async {
    final ipo = await _db.from('ipos').select().eq('id', id).single();
    final ipoMap = Map<String, dynamic>.from(ipo as Map);

    Future<List<Map<String, dynamic>>> child(String table, [String orderBy = '']) async {
      var q = _db.from(table).select().eq('ipo_id', id);
      final rows = orderBy.isEmpty ? await q : await q.order(orderBy);
      return (rows as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
    }

    final company = await _db
        .from('company_profiles')
        .select()
        .eq('ipo_id', id)
        .maybeSingle();

    final leadManagers = await child('lead_managers');
    Map<String, dynamic>? companyMap;
    if (company != null) {
      companyMap = Map<String, dynamic>.from(company as Map);
      final names = leadManagers
          .map((m) => m['name'])
          .whereType<String>()
          .where((n) => n.isNotEmpty)
          .join(', ');
      if (names.isNotEmpty) companyMap['lead_managers'] = names;
    }

    final aggregate = <String, dynamic>{
      'ipo': ipoMap,
      'registrar': ipoMap['registrar_name'],
      'gmp': await child('gmp_history', 'recorded_at'),
      'subscriptions': await child('subscription_snapshots', 'subscription_date'),
      'financials': await child('financial_periods', 'period'),
      'kpis': await child('kpi_metrics', 'metric'),
      'reservations': await child('ipo_reservations', 'category'),
      'lotSizes': await child('lot_size_tiers', 'applicant'),
      'importantDates': await child('important_dates', 'sort_order'),
      'company': companyMap,
    };
    return IpoDetailModel.fromJson(aggregate);
  }
}
