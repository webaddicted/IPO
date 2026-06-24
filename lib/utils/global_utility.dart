import 'package:intl/intl.dart';

/// Number / currency formatting in the Indian style (lakh, crore).
class GlobalUtility {
  const GlobalUtility._();

  static final NumberFormat _inr =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final NumberFormat _indianGroup = NumberFormat.decimalPattern('en_IN');

  static num? toNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  /// 132800 -> '₹1,32,800'
  static String rupee(dynamic value) {
    final n = toNum(value);
    return n == null ? '—' : _inr.format(n);
  }

  /// 21688200 -> '2,16,88,200'
  static String group(dynamic value) {
    final n = toNum(value);
    return n == null ? '—' : _indianGroup.format(n);
  }

  /// 360000000 -> '₹36.00 Cr'  /  4820000 -> '₹48.20 Lakh'
  static String compactRupee(dynamic value) {
    final n = toNum(value)?.toDouble();
    if (n == null) return '—';
    if (n.abs() >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n.abs() >= 100000) return '₹${(n / 100000).toStringAsFixed(2)} Lakh';
    return _inr.format(n);
  }

  /// 57.97 -> '57.97%'
  static String percent(dynamic value, {int digits = 2}) {
    final n = toNum(value);
    return n == null ? '—' : '${n.toStringAsFixed(digits)}%';
  }

  /// 2.36 -> '2.36x'
  static String times(dynamic value, {int digits = 2}) {
    final n = toNum(value);
    return n == null ? '—' : '${n.toStringAsFixed(digits)}x';
  }

  /// Price band: 157, 166 -> '₹157 – ₹166'
  static String priceBand(dynamic min, dynamic max) {
    final lo = toNum(min);
    final hi = toNum(max);
    if (lo == null && hi == null) return '—';
    if (lo == null || hi == null || lo == hi) {
      return _inr.format(lo ?? hi);
    }
    return '${_inr.format(lo)} – ${_inr.format(hi)}';
  }
}
