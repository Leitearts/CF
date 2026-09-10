import 'package:flutter_test/flutter_test.dart';
import 'package:farm_os_mobile/core/utils/validators.dart';

void main() {
  group('Validators.emailOrPhone', () {
    test('accepts a valid email', () {
      expect(Validators.emailOrPhone('farmer@example.com'), isNull);
    });

    test('rejects an invalid email', () {
      expect(Validators.emailOrPhone('not-an-email@'), isNotNull);
    });

    test('accepts a valid phone number', () {
      expect(Validators.emailOrPhone('+254712345678'), isNull);
    });

    test('rejects empty input', () {
      expect(Validators.emailOrPhone(''), isNotNull);
    });
  });

  group('Validators.password', () {
    test('rejects passwords under 8 characters', () {
      expect(Validators.password('short'), isNotNull);
    });

    test('accepts an 8+ character password', () {
      expect(Validators.password('longenoughpassword'), isNull);
    });
  });

  group('Validators.positiveNumber', () {
    test('rejects zero and negative numbers', () {
      expect(Validators.positiveNumber('0', fieldLabel: 'Quantity'), isNotNull);
      expect(Validators.positiveNumber('-5', fieldLabel: 'Quantity'), isNotNull);
    });

    test('accepts a positive number', () {
      expect(Validators.positiveNumber('12.5', fieldLabel: 'Quantity'), isNull);
    });

    test('rejects non-numeric input', () {
      expect(Validators.positiveNumber('abc', fieldLabel: 'Quantity'), isNotNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects mismatched passwords', () {
      expect(Validators.confirmPassword('abc', 'xyz'), isNotNull);
    });

    test('accepts matching passwords', () {
      expect(Validators.confirmPassword('abc', 'abc'), isNull);
    });
  });
}
