import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/application/auth_state.dart';
import '../auth/auth_providers.dart';
import '../../core/providers/core_providers.dart';
import 'data/datasources/farms_remote_data_source.dart';
import 'data/repositories/farms_repository.dart';
import 'application/farms_controller.dart';
import 'application/farms_state.dart';

final farmsRemoteDataSourceProvider = Provider<FarmsRemoteDataSource>((ref) {
  // Reuses the SAME apiClientProvider the auth feature uses -- one
  // ApiClient, one Dio instance, one auth interceptor for the whole app.
  return FarmsRemoteDataSource(ref.watch(apiClientProvider));
});

final farmsRepositoryProvider = Provider<FarmsRepository>((ref) {
  return FarmsRepository(ref.watch(farmsRemoteDataSourceProvider));
});

/// Watches authControllerProvider so this entire provider (and its
/// StateNotifier) is torn down and rebuilt fresh on every login/logout
/// transition -- otherwise farmer A's farms could briefly flash on screen
/// after farmer B logs in on the same device. Rebuilding is cheap (a plain
/// object + one HTTP call) and only happens on auth transitions, never on
/// ordinary navigation, so this does not violate the "avoid unnecessary API
/// calls" requirement (section 24).
final farmsControllerProvider = StateNotifierProvider<FarmsController, FarmsState>((ref) {
  final authState = ref.watch(authControllerProvider);
  final controller = FarmsController(
    repository: ref.watch(farmsRepositoryProvider),
    localStorage: ref.watch(localStorageServiceProvider),
  );
  if (authState.status == AuthStatus.authenticated) {
    controller.loadFarms();
  }
  return controller;
});
