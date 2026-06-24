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
        .map((rows) => rows
            .map(IpoModel.fromJson)
            .where((i) =>
                i.kind == kind &&
                (listed ? i.status == IpoStatus.listed : i.status != IpoStatus.listed))
            .toList());
  }

  Future<List<IpoModel>> fetchIpos({required IpoKind kind, required bool listed}) async {
    final query = _db.from('ipos').select().eq('ipo_type', kind.name);
    final rows = listed
        ? await query.eq('status', 'listed')
        : await query.neq('status', 'listed');
    return (rows as List)
        .map((e) => IpoModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Assembles the full detail aggregate from the child tables.
  Future<IpoDetailModel> fetchDetail(String id) async {
    final ipo = await _db.from('ipos').select().eq('id', id).single();

    Future<List<Map<String, dynamic>>> child(String table, [String orderBy = '']) async {
      var q = _db.from(table).select().eq('ipo_id', id);
      final rows = orderBy.isEmpty ? await q : await q.order(orderBy);
      return (rows as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
    }

    final company = await _db
        .from('company_info')
        .select()
        .eq('ipo_id', id)
        .maybeSingle();

    final aggregate = <String, dynamic>{
      'ipo': ipo,
      'gmp': await child('gmp_data', 'recorded_at'),
      'subscriptions': await child('subscription_data'),
      'financials': await child('financial_data'),
      'kpis': await child('kpi_data'),
      'reservations': await child('ipo_reservation'),
      'lotSizes': await child('lot_size_tier'),
      'importantDates': await child('important_dates', 'sort_order'),
      'company': company,
    };
    return IpoDetailModel.fromJson(aggregate);
  }
}
