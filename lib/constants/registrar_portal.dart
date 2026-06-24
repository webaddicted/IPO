/// Client-side mirror of the backend RegistrarPortal: maps a free-text
/// registrar name to its official allotment-status page. Used to build a
/// manual-check link when the backend is unreachable.
class RegistrarPortal {
  const RegistrarPortal._();

  static const Map<String, String> _portals = {
    'bigshare': 'https://ipo.bigshareonline.com/ipo_Allotment.html',
    'linkintime': 'https://linkintime.co.in/initial_offer/public-issues.html',
    'kfin': 'https://ris.kfintech.com/ipostatus/',
    'karvy': 'https://ris.kfintech.com/ipostatus/',
    'maashitla': 'https://www.maashitla.com/allotment-status/public-issues',
    'cameo': 'https://ipo.cameoindia.com/',
  };

  /// Returns the portal URL for a registrar name, or null if unknown.
  static String? urlFor(String? registrar) {
    if (registrar == null) return null;
    final n = registrar.toLowerCase();
    for (final entry in _portals.entries) {
      if (n.contains(entry.key)) return entry.value;
    }
    if (n.contains('link') && n.contains('intime')) return _portals['linkintime'];
    return null;
  }
}
