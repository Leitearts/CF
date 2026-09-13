import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../datasources/farms_remote_data_source.dart';
import '../models/farm_input.dart';
import '../models/farm_model.dart';

class FarmsRepository {
  FarmsRepository(this._remoteDataSource);

  final FarmsRemoteDataSource _remoteDataSource;

  Future<Result<List<FarmModel>>> listFarms() async {
    try {
      final farms = await _remoteDataSource.listFarms();
      return Result.success(farms);
    } catch (error) {
      return Result.failure(ErrorMapper.fromException(error));
    }
  }

  Future<Result<FarmModel>> getFarm(String farmId) async {
    try {
      final farm = await _remoteDataSource.getFarm(farmId);
      return Result.success(farm);
    } catch (error) {
      return Result.failure(ErrorMapper.fromException(error));
    }
  }

  Future<Result<FarmModel>> createFarm(CreateFarmInput input) async {
    try {
      final farm = await _remoteDataSource.createFarm(input);
      return Result.success(farm);
    } catch (error) {
      return Result.failure(ErrorMapper.fromException(error));
    }
  }

  Future<Result<FarmModel>> updateFarm({
    required String farmId,
    required UpdateFarmInput input,
  }) async {
    try {
      final farm = await _remoteDataSource.updateFarm(farmId: farmId, input: input);
      return Result.success(farm);
    } catch (error) {
      return Result.failure(ErrorMapper.fromException(error));
    }
  }
}
