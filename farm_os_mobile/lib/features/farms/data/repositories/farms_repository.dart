import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../datasources/farms_remote_data_source.dart';
import '../models/farm_model.dart';
import '../models/create_farm_input.dart';
import '../models/update_farm_input.dart';

/// Mirrors AuthRepository's shape exactly: wraps the remote data source,
/// converts every exception to Result<T> via the existing ErrorMapper, and
/// exposes nothing Dio-specific to callers.
class FarmsRepository {
  FarmsRepository(this._remote);

  final FarmsRemoteDataSource _remote;

  Future<Result<List<FarmModel>>> getFarms() async {
    try {
      final farms = await _remote.getFarms();
      return Result.success(farms);
    } catch (e) {
      return Result.failure(ErrorMapper.fromException(e));
    }
  }

  Future<Result<FarmModel>> getFarm(String farmId) async {
    try {
      final farm = await _remote.getFarm(farmId);
      return Result.success(farm);
    } catch (e) {
      return Result.failure(ErrorMapper.fromException(e));
    }
  }

  Future<Result<FarmModel>> createFarm(CreateFarmInput input) async {
    try {
      final farm = await _remote.createFarm(input);
      return Result.success(farm);
    } catch (e) {
      return Result.failure(ErrorMapper.fromException(e));
    }
  }

  Future<Result<FarmModel>> updateFarm(String farmId, UpdateFarmInput input) async {
    try {
      final farm = await _remote.updateFarm(farmId, input);
      return Result.success(farm);
    } catch (e) {
      return Result.failure(ErrorMapper.fromException(e));
    }
  }
}
