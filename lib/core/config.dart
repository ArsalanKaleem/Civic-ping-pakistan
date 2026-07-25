/// Runtime configuration.
class AppConfig {
  /// Backend base URL. Override at build time:
  ///   flutter run -d chrome --dart-define=API_BASE_URL=https://api.civicping.pk
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}
