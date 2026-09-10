import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Non-sensitive local cache: user preferences, last-selected farm, onboarding
/// flags. Never used for tokens (see SecureStorageService for that).
class LocalStorageService {
  LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  String? get activeFarmId => _prefs.getString(StorageKeys.activeFarmId);

  Future<void> setActiveFarmId(String farmId) =>
      _prefs.setString(StorageKeys.activeFarmId, farmId);

  /// Used when a locally stored activeFarmId no longer matches any farm the
  /// backend returns for this user (Sprint 2 section 11, step 4/7) --
  /// without wiping the rest of local storage.
  Future<void> clearActiveFarmId() => _prefs.remove(StorageKeys.activeFarmId);

  bool get hasCompletedOnboarding =>
      _prefs.getBool(StorageKeys.hasCompletedOnboarding) ?? false;

  Future<void> setOnboardingComplete() =>
      _prefs.setBool(StorageKeys.hasCompletedOnboarding, true);

  Future<void> clear() async {
    await _prefs.remove(StorageKeys.activeFarmId);
    // Deliberately keep hasCompletedOnboarding across logout -- a returning
    // farmer shouldn't see the onboarding slides again.
  }
}
