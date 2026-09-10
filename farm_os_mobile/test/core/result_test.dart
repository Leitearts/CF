import 'package:flutter_test/flutter_test.dart';
import 'package:farm_os_mobile/core/errors/app_failure.dart';
import 'package:farm_os_mobile/core/errors/result.dart';

void main() {
  group('Result', () {
    test('success carries its value through when()', () {
      const result = Result<int>.success(42);

      final output = result.when(
        success: (value) => 'got $value',
        failure: (failure) => 'failed: ${failure.message}',
      );

      expect(output, 'got 42');
      expect(result.isSuccess, isTrue);
    });

    test('failure carries its AppFailure through when()', () {
      const failure = AppFailure(type: FailureType.validation, message: 'bad input');
      const result = Result<int>.failure(failure);

      final output = result.when(
        success: (value) => 'got $value',
        failure: (f) => 'failed: ${f.message}',
      );

      expect(output, 'failed: bad input');
      expect(result.isSuccess, isFalse);
    });
  });
}
