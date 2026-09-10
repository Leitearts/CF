import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/farm_model.dart';
import '../models/create_farm_input.dart';
import '../models/update_farm_input.dart';

/// Talks to /farms/* using the SAME ApiClient instance the auth feature
/// uses (via farmsRemoteDataSourceProvider in farms_providers.dart) -- the
/// JWT header injection and 401-refresh-retry logic already in ApiClient's
/// interceptor apply here automatically. No new Dio instance, no
/// duplicated auth handling.
class FarmsRemoteDataSource {
  FarmsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<FarmModel>> getFarms() async {
    final response = await _apiClient.get(ApiEndpoints.farms);
    final data = response.data['data'] as List<dynamic>;
    return data.map((json) => FarmModel.fromJson(json as Map<String, dynamic>)).toList();
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

  Future<FarmModel> updateFarm(String farmId, UpdateFarmInput input) async {
    final response = await _apiClient.put(ApiEndpoints.farm(farmId), data: input.toJson());
    final data = response.data['data'] as Map<String, dynamic>;
    return FarmModel.fromJson(data);
  }
}
