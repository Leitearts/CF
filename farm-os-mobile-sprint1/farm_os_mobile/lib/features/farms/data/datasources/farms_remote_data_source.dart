import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/farm_input.dart';
import '../models/farm_model.dart';

class FarmsRemoteDataSource {
  FarmsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<FarmModel>> listFarms() async {
    final response = await _apiClient.get(ApiEndpoints.farms);
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((farmJson) => FarmModel.fromJson(farmJson as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<FarmModel> getFarm(String farmId) async {
    final response = await _apiClient.get(ApiEndpoints.farm(farmId));
    final data = response.data['data'] as Map<String, dynamic>;
    return FarmModel.fromJson(data);
  }

  Future<FarmModel> createFarm(CreateFarmInput input) async {
    final response = await _apiClient.post(ApiEndpoints.farms, data: input.toJson());
    final data = response.data['data'] as Map<String, dynamic>;
    return FarmModel.fromJson(data);
  }

  Future<FarmModel> updateFarm({
    required String farmId,
    required UpdateFarmInput input,
  }) async {
    final response = await _apiClient.put(ApiEndpoints.farm(farmId), data: input.toJson());
    final data = response.data['data'] as Map<String, dynamic>;
    return FarmModel.fromJson(data);
  }
}
