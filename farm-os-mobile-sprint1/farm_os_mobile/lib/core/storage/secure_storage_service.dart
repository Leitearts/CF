import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Thin wrapper around flutter_secure_storage. This is the ONLY place tokens
/// are persisted -- per Stage 4 section 30, never store passwords locally,
/// and tokens must use platform secure storage (Keystore on Android).
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: StorageKeys.accessToken, value: accessToken);
    await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
  }

  Future<String?> readAccessToken() => _storage.read(key: StorageKeys.accessToken);

  Future<String?> readRefreshToken() => _storage.read(key: StorageKeys.refreshToken);

  Future<void> updateAccessToken(String accessToken) =>
      _storage.write(key: StorageKeys.accessToken, value: accessToken);

  /// Clears everything on logout -- "Clear sensitive local data on logout"
  /// (Stage 4 section 30).
  Future<void> clearAll() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.cachedUserJson);
  }

  Future<bool> hasValidSession() async {
    final refreshToken = await readRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }
}
