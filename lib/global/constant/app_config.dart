/// Central runtime configuration.
///
/// Production API is deployed on Render. For local backend dev:
///
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081
class AppConfig {
  const AppConfig._();

  static const String productionApiBaseUrl = 'https://aaipo-api.onrender.com';

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
      String.fromEnvironment('API_BASE_URL', defaultValue: productionApiBaseUrl);

  /// FastAPI backend — defaults to [productionApiBaseUrl] on Render.
  static String get apiBaseUrl => _apiFromEnv;

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static bool get hasApi => apiBaseUrl.isNotEmpty;
}
