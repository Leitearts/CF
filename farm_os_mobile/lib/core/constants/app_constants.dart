/// Keys used with SecureStorageService / SharedPreferences.
/// Centralized so a typo can't silently create a second, disconnected key.
class StorageKeys {
  StorageKeys._();

  static const String accessToken = 'auth_access_token';
  static const String refreshToken = 'auth_refresh_token';
  static const String cachedUserJson = 'auth_cached_user';
  static const String activeFarmId = 'active_farm_id';
  static const String hasCompletedOnboarding = 'has_completed_onboarding';
}

class ApiEndpoints {
  ApiEndpoints._();

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/password-reset/request';
  static const String resetPassword = '/auth/password-reset/confirm';

  static const String farms = '/farms';
  static String farm(String farmId) => '/farms/$farmId';
}
