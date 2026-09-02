import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

/// The boundary the rest of the app talks to for auth. Combines the remote
/// data source with local token persistence, and converts every exception
/// into a Result<T> so AuthController never needs try/catch.
class AuthRepository {
  AuthRepository({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageService secureStorage,
  })  : _remote = remoteDataSource,
        _secureStorage = secureStorage;

  final AuthRemoteDataSource _remote;
  final SecureStorageService _secureStorage;

  Future<Result<UserModel>> register({
    required String fullName,
    String? email,
    String? phone,
    required String password,
  }) async {
    try {
      final (user, tokens) = await _remote.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );
      await _secureStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return Result.success(user);
    } catch (e) {
      return Result.failure(ErrorMapper.fromException(e));
    }
  }

  Future<Result<UserModel>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final (user, tokens) = await _remote.login(identifier: identifier, password: password);
      await _secureStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return Result.success(user);
    } catch (e) {
      return Result.failure(ErrorMapper.fromException(e));
    }
  }

  /// Best-effort server-side logout (revokes the refresh token), followed by
  /// an unconditional local clear -- the user is logged out locally even if
  /// the network call fails, so they're never stuck.
  Future<void> logout() async {
    try {
      await _remote.logout();
    } catch (_) {
      // Ignore -- local session clear below is what actually matters to the UI.
    } finally {
      await _secureStorage.clearAll();
    }
  }

  Future<Result<void>> forgotPassword(String identifier) async {
    try {
      await _remote.forgotPassword(identifier);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ErrorMapper.fromException(e));
    }
  }

  Future<Result<void>> resetPassword({
    required String identifier,
    required String resetCode,
    required String newPassword,
  }) async {
    try {
      await _remote.resetPassword(
        identifier: identifier,
        resetCode: resetCode,
        newPassword: newPassword,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ErrorMapper.fromException(e));
    }
  }

  Future<bool> hasValidSession() => _secureStorage.hasValidSession();
}
