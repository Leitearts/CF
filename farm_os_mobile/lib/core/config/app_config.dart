/// Central place for environment-specific configuration. Avoids scattering
/// `--dart-define` reads or hard-coded URLs across the codebase.
library;

import 'package:flutter/foundation.dart' show kReleaseMode;

class AppConfig {
  AppConfig._();

  /// Backend base URL. Overridable at build time:
  ///   flutter run --dart-define=API_BASE_URL=https://api.farmos.app
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000', // Android emulator -> host localhost:3000
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static bool get isProduction => kReleaseMode;
}
