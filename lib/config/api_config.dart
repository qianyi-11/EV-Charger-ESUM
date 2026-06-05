/// Single source of truth for backend server connectivity.
///
/// Do not hardcode server URLs anywhere else in the app — import [ApiConfig] only.
///
/// Override at build time:
///   flutter run --dart-define=DEV_SERVER_HOST=192.168.1.50
///
/// Or set the host once in App Settings (persisted across rebuilds).
class ApiConfig {
  ApiConfig._();

  static const int serverPort = 5000;

  /// Last-resort default when nothing else is configured.
  /// Prefer Settings or --dart-define=DEV_SERVER_HOST instead of editing this often.
  static const String defaultDevServerHost = '10.164.37.99';

  /// Build-time override (highest priority after a successful health check cache).
  static const String buildTimeHost = String.fromEnvironment('DEV_SERVER_HOST');

  static const String prefsHostKey = 'dev_server_host';
  static const String prefsResolvedUrlKey = 'resolved_server_base_url';

  static String hostToVisionBaseUrl(String host) =>
      'http://$host:$serverPort/api/vision';

  static String hostToApiBaseUrl(String host) =>
      'http://$host:$serverPort/api';

  static String hostToHealthUrl(String host) =>
      'http://$host:$serverPort/health';
}
