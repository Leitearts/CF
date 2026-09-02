import 'package:dio/dio.dart';
import 'app_failure.dart';

/// The single place raw errors get translated into farmer-readable text.
/// Per Stage 4 section 21: never show "HTTP 422: ..." or stack traces.
class ErrorMapper {
  ErrorMapper._();

  static AppFailure fromException(Object error) {
    if (error is AppFailure) return error;

    if (error is DioException) {
      return _fromDioException(error);
    }

    return const AppFailure(
      type: FailureType.unknown,
      message: 'Something went wrong. Please try again.',
    );
  }

  static AppFailure _fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppFailure(
          type: FailureType.timeout,
          message: 'The request took too long. Please check your connection and try again.',
        );

      case DioExceptionType.connectionError:
        return const AppFailure(
          type: FailureType.network,
          message: 'No internet connection. Please check your network and try again.',
        );

      case DioExceptionType.badResponse:
        return _fromResponse(error);

      case DioExceptionType.cancel:
        return const AppFailure(
          type: FailureType.unknown,
          message: 'Request was cancelled.',
        );

      case DioExceptionType.badCertificate:
        return const AppFailure(
          type: FailureType.network,
          message: 'Could not establish a secure connection. Please try again later.',
        );

      case DioExceptionType.unknown:
        return const AppFailure(
          type: FailureType.network,
          message: 'No internet connection. Please check your network and try again.',
        );
    }
  }

  static AppFailure _fromResponse(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final body = error.response?.data;

    // Backend envelope: { success: false, data: null, error: { message, ... } }
    String? backendMessage;
    Map<String, String>? fieldErrors;
    if (body is Map<String, dynamic>) {
      final errorObj = body['error'];
      if (errorObj is Map<String, dynamic>) {
        final rawMessage = errorObj['message'];
        if (rawMessage is String) {
          backendMessage = rawMessage;
        } else if (rawMessage is List) {
          // class-validator often returns an array of field messages.
          backendMessage = rawMessage.isNotEmpty ? rawMessage.first.toString() : null;
          fieldErrors = _extractFieldErrors(rawMessage);
        }
      }
    }

    switch (statusCode) {
      case 400:
      case 422:
        return AppFailure(
          type: FailureType.validation,
          message: backendMessage ?? 'Please check the information you entered and try again.',
          fieldErrors: fieldErrors,
        );
      case 401:
        return const AppFailure(
          type: FailureType.unauthorized,
          message: 'Your session has expired. Please log in again.',
        );
      case 403:
        return const AppFailure(
          type: FailureType.unauthorized,
          message: "You don't have permission to do that.",
        );
      case 404:
        return AppFailure(
          type: FailureType.notFound,
          message: backendMessage ?? 'We could not find what you were looking for.',
        );
      case 409:
        return AppFailure(
          type: FailureType.validation,
          message: backendMessage ?? 'This already exists.',
        );
      case >= 500:
        return const AppFailure(
          type: FailureType.server,
          message: 'Our servers are having trouble. Please try again shortly.',
        );
      default:
        return const AppFailure(
          type: FailureType.unknown,
          message: 'Something went wrong. Please try again.',
        );
    }
  }

  static Map<String, String>? _extractFieldErrors(List<dynamic> messages) {
    // Best-effort: class-validator messages are plain strings like
    // "quantity must be a positive number", not structured per-field data,
    // so we surface them as a general list rather than guessing field names.
    if (messages.isEmpty) return null;
    return {'general': messages.join('\n')};
  }
}
