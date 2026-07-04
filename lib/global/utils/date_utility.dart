import 'package:intl/intl.dart';

/// Date parsing + formatting helpers.
class DateUtility {
  const DateUtility._();

  static final DateFormat _display = DateFormat('d MMM yyyy');
  static final DateFormat _displayWithDay = DateFormat('EEE, MMM d, yyyy');

  static DateTime? parse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  /// '2026-06-04' -> '4 Jun 2026'
  static String format(dynamic value) {
    final d = parse(value);
    return d == null ? '—' : _display.format(d);
  }

  static String formatWithDay(dynamic value) {
    final d = parse(value);
    return d == null ? '—' : _displayWithDay.format(d);
  }

  /// '4 to 8 Jun, 2026' style range.
  static String range(dynamic from, dynamic to) {
    final a = parse(from);
    final b = parse(to);
    if (a == null && b == null) return '—';
    if (a == null) return format(b);
    if (b == null) return format(a);
    if (a.month == b.month && a.year == b.year) {
      return '${a.day} to ${b.day} ${DateFormat('MMM, yyyy').format(b)}';
    }
    return '${format(a)} – ${format(b)}';
  }
}
