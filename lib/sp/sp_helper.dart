import 'package:shared_preferences/shared_preferences.dart';

/// Thin async wrapper over SharedPreferences.
class SpHelper {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    final p = _prefs;
    if (p == null) {
      throw StateError('SpHelper.init() must be awaited before use');
    }
    return p;
  }

  static List<String> getStringList(String key) => _p.getStringList(key) ?? const [];

  static Future<void> setStringList(String key, List<String> value) =>
      _p.setStringList(key, value);

  static String? getString(String key) => _p.getString(key);

  static Future<void> setString(String key, String value) => _p.setString(key, value);
}
