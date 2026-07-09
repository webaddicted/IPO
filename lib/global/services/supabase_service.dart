import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:untitled_poi/global/constant/app_config.dart';
import 'package:untitled_poi/global/constant/supabase_tables.dart';
import 'package:untitled_poi/features/home/domain/ipo_model.dart';
import 'package:untitled_poi/features/ipo_detail/domain/ipo_detail_model.dart';

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
        .from(SupabaseTables.ipos)
        .stream(primaryKey: ['id'])
        .eq('ipo_type', kind.name)
        .order('company_name')
        .map((rows) => rows
            .map((e) => IpoModel.fromJson(e))
            .where((i) => listed ? i.status == IpoStatus.listed : i.status != IpoStatus.listed)
            .toList());
  }

  Future<List<IpoModel>> fetchIpos({required IpoKind kind, required bool listed}) async {
    var query = _db.from(SupabaseTables.ipos).select().eq('ipo_type', kind.name);
    query = listed ? query.eq('status', 'listed') : query.neq('status', 'listed');
    final rows = await query.order('company_name');
    return (rows as List)
        .map((e) => IpoModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Assembles the full detail aggregate from the child tables (0003 schema).
  Future<IpoDetailModel> fetchDetail(String id) async {
    final ipo = await _db.from(SupabaseTables.ipos).select().eq('id', id).single();
    final ipoMap = Map<String, dynamic>.from(ipo as Map);

    Future<List<Map<String, dynamic>>> child(String table, [String orderBy = '']) async {
      var q = _db.from(table).select().eq('ipo_id', id);
      final rows = orderBy.isEmpty ? await q : await q.order(orderBy);
      return (rows as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
    }

    final company = await _db
        .from(SupabaseTables.companyProfiles)
        .select()
        .eq('ipo_id', id)
        .maybeSingle();

    final leadManagers = await child(SupabaseTables.leadManagers);
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
      'gmp': await child(SupabaseTables.gmpHistory, 'recorded_at'),
      'subscriptions': await child(SupabaseTables.subscriptionSnapshots, 'subscription_date'),
      'financials': await child(SupabaseTables.financialPeriods, 'period'),
      'kpis': await child(SupabaseTables.kpiMetrics, 'metric'),
      'reservations': await child(SupabaseTables.ipoReservations, 'category'),
      'lotSizes': await child(SupabaseTables.lotSizeTiers, 'applicant'),
      'importantDates': await child(SupabaseTables.importantDates, 'sort_order'),
      'company': companyMap,
    };
    return IpoDetailModel.fromJson(aggregate);
  }
}
