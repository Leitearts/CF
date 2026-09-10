import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/repositories/auth_repository.dart';
import 'application/auth_controller.dart';
import 'application/auth_state.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// apiClientProvider reads authControllerProvider.notifier ONLY inside the
/// onSessionExpired closure, which runs later (on a 401), not during this
/// provider's own build -- so this does not create a circular dependency
/// even though authControllerProvider transitively depends on apiClient via
/// authRepositoryProvider below.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    secureStorage: ref.watch(secureStorageProvider),
    onSessionExpired: () => ref.read(authControllerProvider.notifier).forceLogout(),
  );
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
