import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farm_os_mobile/core/errors/app_failure.dart';
import 'package:farm_os_mobile/core/errors/error_mapper.dart';

void main() {
  group('ErrorMapper', () {
    test('maps connection timeout to a friendly network message', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/farms'),
        type: DioExceptionType.connectionTimeout,
      );

      final failure = ErrorMapper.fromException(dioError);

      expect(failure.type, FailureType.timeout);
      expect(failure.message, isNot(contains('DioException')));
      expect(failure.message, isNot(contains('Exception')));
    });

    test('maps a 401 response to unauthorized with a session-expired message', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/farms'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/farms'),
          statusCode: 401,
        ),
      );

      final failure = ErrorMapper.fromException(dioError);

      expect(failure.type, FailureType.unauthorized);
      expect(failure.isAuthError, isTrue);
    });

    test('maps a 500 response to a generic server failure without leaking details', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/farms'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/farms'),
          statusCode: 500,
          data: {
            'success': false,
            'error': {'message': 'PrismaClientValidationError: ...'},
          },
        ),
      );

      final failure = ErrorMapper.fromException(dioError);

      expect(failure.type, FailureType.server);
      expect(failure.message, isNot(contains('Prisma')));
    });

    test('surfaces backend validation messages for 400/422 responses', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/feed/purchase'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/feed/purchase'),
          statusCode: 422,
          data: {
            'success': false,
            'error': {'message': 'Quantity must be a positive number.'},
          },
        ),
      );

      final failure = ErrorMapper.fromException(dioError);

      expect(failure.type, FailureType.validation);
      expect(failure.message, 'Quantity must be a positive number.');
    });

    test('falls back to a generic message for a non-Dio exception', () {
      final failure = ErrorMapper.fromException(Exception('some internal detail'));

      expect(failure.type, FailureType.unknown);
      expect(failure.message, 'Something went wrong. Please try again.');
    });
  });
}
