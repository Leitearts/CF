import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/local_storage_service.dart';
import '../auth/auth_providers.dart';
import 'application/farms_controller.dart';
import 'application/farms_state.dart';
import 'data/datasources/farms_remote_data_source.dart';
import 'data/repositories/farms_repository.dart';

final localStorageServiceProvider = FutureProvider<LocalStorageService>((ref) async {
  return LocalStorageService.create();
});

final farmsRemoteDataSourceProvider = Provider<FarmsRemoteDataSource>((ref) {
  return FarmsRemoteDataSource(ref.watch(apiClientProvider));
});

final farmsRepositoryProvider = Provider<FarmsRepository>((ref) {
  return FarmsRepository(ref.watch(farmsRemoteDataSourceProvider));
});

final farmsControllerProvider = StateNotifierProvider<FarmsController, FarmsState>((ref) {
  return FarmsController(ref);
});
