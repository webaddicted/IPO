import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Central runtime configuration.
///
/// Override with --dart-define when needed, e.g. physical Android device:
///
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8081
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  /// Legacy alias — prefer [supabasePublishableKey].
  static const String supabaseAnonKey = supabasePublishableKey;

  static const String _apiFromEnv =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// FastAPI backend (`http://localhost:8081/doc`).
  /// Defaults to the local dev server; Android emulator uses `10.0.2.2`.
  static String get apiBaseUrl {
    if (_apiFromEnv.isNotEmpty) return _apiFromEnv;
    if (kIsWeb) return 'http://localhost:8081';
    if (Platform.isAndroid) return 'http://10.0.2.2:8081';
    return 'http://localhost:8081';
  }

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static bool get hasApi => apiBaseUrl.isNotEmpty;
}
