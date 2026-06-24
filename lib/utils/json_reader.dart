/// Reads a value from a JSON map by trying several key aliases.
///
/// The same logical field arrives as snake_case from Supabase
/// (`offer_price_min`) and camelCase from the Spring API (`offerPriceMin`),
/// so models look up both.
class JsonReader {
  final Map<String, dynamic> _json;
  const JsonReader(this._json);

  dynamic _first(List<String> keys) {
    for (final k in keys) {
      if (_json.containsKey(k) && _json[k] != null) return _json[k];
    }
    return null;
  }

  String? str(List<String> keys) => _first(keys)?.toString();

  int? integer(List<String> keys) {
    final v = _first(keys);
    if (v == null) return null;
    if (v is int) return v;
    return num.tryParse(v.toString())?.toInt();
  }

  num? number(List<String> keys) {
    final v = _first(keys);
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  DateTime? date(List<String> keys) {
    final v = _first(keys);
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  /// Snake + camel variants for a base name, e.g. 'offer_price_min'.
  static List<String> alias(String snake) {
    final parts = snake.split('_');
    final camel = parts.first +
        parts.skip(1).map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}').join();
    return snake == camel ? [snake] : [snake, camel];
  }
}
