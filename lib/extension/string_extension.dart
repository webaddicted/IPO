/// String helpers.
extension StringExtension on String? {
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;

  /// 'open' -> 'Open', 'bse sme' -> 'Bse Sme'
  String get titleCase {
    final s = this;
    if (s == null || s.isEmpty) return '';
    return s
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String orDash() => isNullOrEmpty ? '—' : this!;
}
