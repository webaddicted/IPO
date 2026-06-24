/// Central runtime configuration.
///
/// Values are read from --dart-define so secrets stay out of source. Example:
///
/// flutter run \
///   --dart-define=SUPABASE_URL=https://ddtztnkkhlldxrumajxb.supabase.co \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
///   --dart-define=API_BASE_URL=http://10.0.2.2:8080
///
/// When Supabase keys are absent the app still runs against bundled mock data,
/// so it is demoable with zero setup.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ddtztnkkhlldxrumajxb.supabase.co',
  );
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_BpIAizOHgzSstZbrWH59hg_RxqViofk',
  );

  /// Legacy alias — prefer [supabasePublishableKey].
  static const String supabaseAnonKey = supabasePublishableKey;

  /// Spring Boot API. 10.0.2.2 is the Android emulator's alias for host machine.
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
