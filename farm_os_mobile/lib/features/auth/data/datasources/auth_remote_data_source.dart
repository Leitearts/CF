import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/auth_tokens.dart';
import '../models/user_model.dart';

/// Talks to the /auth/* endpoints and nothing else. Returns raw
/// models/tokens; all error translation happens in the repository so this
/// class stays a thin, easily-mockable HTTP boundary.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<(UserModel, AuthTokens)> register({
    required String fullName,
    String? email,
    String? phone,
    required String password,
  }) async {
    final response = await _apiClient.post(ApiEndpoints.register, data: {
      'fullName': fullName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'password': password,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    return (
      UserModel.fromJson(data['user'] as Map<String, dynamic>),
      AuthTokens.fromJson(data),
    );
  }

  Future<(UserModel, AuthTokens)> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _apiClient.post(ApiEndpoints.login, data: {
      'identifier': identifier,
      'password': password,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    return (
      UserModel.fromJson(data['user'] as Map<String, dynamic>),
      AuthTokens.fromJson(data),
    );
  }

  Future<void> logout() async {
    await _apiClient.post(ApiEndpoints.logout);
  }

  Future<void> forgotPassword(String identifier) async {
    await _apiClient.post(ApiEndpoints.forgotPassword, data: {'identifier': identifier});
  }

  Future<void> resetPassword({
    required String identifier,
    required String resetCode,
    required String newPassword,
  }) async {
    await _apiClient.post(ApiEndpoints.resetPassword, data: {
      'identifier': identifier,
      'resetCode': resetCode,
      'newPassword': newPassword,
    });
  }
}
