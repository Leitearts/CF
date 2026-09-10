import 'package:flutter_test/flutter_test.dart';
import 'package:farm_os_mobile/features/farms/data/models/create_farm_input.dart';
import 'package:farm_os_mobile/features/farms/data/models/update_farm_input.dart';

void main() {
  group('CreateFarmInput.toJson', () {
    test('includes all provided fields', () {
      const input = CreateFarmInput(
        name: 'Caro Test Farm',
        phone: '0712345678',
        email: 'farm@testfarmos.com',
        location: 'Kabarak',
        region: 'Nakuru',
        country: 'Kenya',
        farmType: 'Mixed Livestock',
        registrationNo: 'TEST-FARM-001',
      );

      final json = input.toJson();

      expect(json['name'], 'Caro Test Farm');
      expect(json['phone'], '0712345678');
      expect(json['registrationNo'], 'TEST-FARM-001');
    });

    test('omits optional fields that are null or empty rather than sending nulls', () {
      const input = CreateFarmInput(name: 'Minimal Farm', phone: '', email: null);

      final json = input.toJson();

      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('phone'), isFalse);
      expect(json.containsKey('email'), isFalse);
    });

    test('always includes the required name field', () {
      const input = CreateFarmInput(name: 'Farm');
      expect(input.toJson()['name'], 'Farm');
    });
  });

  group('UpdateFarmInput.toJson', () {
    test('only includes fields that were set', () {
      const input = UpdateFarmInput(name: 'Renamed Farm', phone: '0700000000');

      final json = input.toJson();

      expect(json, {'name': 'Renamed Farm', 'phone': '0700000000'});
    });

    test('an all-null input produces an empty body', () {
      const input = UpdateFarmInput();
      expect(input.toJson(), isEmpty);
    });

    test('does not expose immutable fields like id or ownerUserId', () {
      const input = UpdateFarmInput(name: 'Farm');
      final json = input.toJson();
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('ownerUserId'), isFalse);
      expect(json.containsKey('version'), isFalse);
    });
  });
}
