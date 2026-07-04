import 'package:untitled_poi/global/sp/sp_const.dart';
import 'package:untitled_poi/global/sp/sp_helper.dart';

/// Domain-level persistence: the local watchlist of starred IPOs.
class SpManager {
  const SpManager._();

  static List<String> get watchlist => SpHelper.getStringList(SpConst.watchlist);

  static bool isWatched(String id) => watchlist.contains(id);

  static Future<void> toggleWatch(String id) async {
    final list = List<String>.from(watchlist);
    list.contains(id) ? list.remove(id) : list.add(id);
    await SpHelper.setStringList(SpConst.watchlist, list);
  }

  static bool get isDarkTheme => SpHelper.getString(SpConst.theme) == 'dark';

  static Future<void> setDarkTheme(bool isDark) async {
    await SpHelper.setString(SpConst.theme, isDark ? 'dark' : 'light');
  }
}
