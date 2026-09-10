import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

/// The ONLY place HTTP calls are made from (Stage 4 section 7: "Do not make
/// raw HTTP calls directly from UI widgets"). Every feature's remote data
/// source is constructed with an instance of this client.
///
/// Responsibilities:
///  - attaches the JWT access token to every request
///  - on a 401, attempts exactly one silent refresh + retry of the original
///    request, using the rotating refresh token
///  - if refresh itself fails, calls [onSessionExpired] so the app can route
///    back to Login -- this class does not know about navigation
class ApiClient {
  ApiClient({
    required SecureStorageService secureStorage,
    required this.onSessionExpired,
    Dio? dio,
  })  : _secureStorage = secureStorage,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: AppConfig.connectTimeout,
                receiveTimeout: AppConfig.receiveTimeout,
                headers: {'Content-Type': 'application/json'},
              ),
            ) {
    _dio.interceptors.add(_AuthInterceptor(this));
    if (!AppConfig.isProduction) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, error: true),
      );
    }
  }

  final Dio _dio;
  final SecureStorageService _secureStorage;

  /// Called when the refresh token itself is invalid/expired -- the app must
  /// treat this as a full logout and return to the Login screen.
  final VoidCallback onSessionExpired;

  Dio get dio => _dio;
  SecureStorageService get secureStorage => _secureStorage;

  // Guards against multiple concurrent requests each independently trying to
  // refresh the token when a 401 arrives at roughly the same time.
  Future<String?>? _refreshInFlight;

  Future<String?> refreshAccessToken() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await _secureStorage.readRefreshToken();
    if (refreshToken == null) return null;

    try {
      // A bare Dio instance is used here (not `_dio`) to avoid recursively
      // triggering the auth interceptor while refreshing the token itself.
      final response = await Dio(
        BaseOptions(baseUrl: AppConfig.apiBaseUrl),
      ).post('/auth/refresh', data: {'refreshToken': refreshToken});

      final data = response.data['data'] as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;

      await _secureStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      return newAccessToken;
    } catch (_) {
      await _secureStorage.clearAll();
      onSessionExpired();
      return null;
    }
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response<dynamic>> post(String path, {Object? data}) => _dio.post(path, data: data);

  Future<Response<dynamic>> put(String path, {Object? data}) => _dio.put(path, data: data);

  Future<Response<dynamic>> patch(String path, {Object? data}) => _dio.patch(path, data: data);

  Future<Response<dynamic>> delete(String path) => _dio.delete(path);
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._client);

  final ApiClient _client;

  static const List<String> _publicPaths = [
    '/auth/register',
    '/auth/login',
    '/auth/refresh',
    '/auth/password-reset/request',
    '/auth/password-reset/confirm',
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_publicPaths.contains(options.path)) {
      final accessToken = await _client.secureStorage.readAccessToken();
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isPublicPath = _publicPaths.contains(err.requestOptions.path);

    if (isUnauthorized && !isPublicPath) {
      final newAccessToken = await _client.refreshAccessToken();
      if (newAccessToken != null) {
        // Retry the original request once, with the fresh token.
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        try {
          final response = await _client.dio.fetch(retryOptions);
          return handler.resolve(response);
        } catch (retryError) {
          return handler.next(err);
        }
      }
    }
    handler.next(err);
  }
}
