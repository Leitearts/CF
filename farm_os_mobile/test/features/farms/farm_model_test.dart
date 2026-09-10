import 'package:flutter_test/flutter_test.dart';
import 'package:farm_os_mobile/features/farms/data/models/farm_model.dart';

void main() {
  group('FarmModel.fromJson', () {
    test('parses a full farm response', () {
      final json = {
        'id': 'farm-1',
        'ownerUserId': 'user-1',
        'name': 'Caro Test Farm',
        'phone': '0712345678',
        'email': 'farm@testfarmos.com',
        'location': 'Kabarak',
        'region': 'Nakuru',
        'country': 'Kenya',
        'farmType': 'Mixed Livestock',
        'registrationNo': 'TEST-FARM-001',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-02T00:00:00.000Z',
        'deletedAt': null,
        'version': 1,
      };

      final farm = FarmModel.fromJson(json);

      expect(farm.id, 'farm-1');
      expect(farm.name, 'Caro Test Farm');
      expect(farm.phone, '0712345678');
      expect(farm.locationSummary, 'Kabarak, Nakuru, Kenya');
      expect(farm.deletedAt, isNull);
      expect(farm.version, 1);
    });

    test('parses a minimal farm response with only required fields', () {
      final json = {
        'id': 'farm-2',
        'ownerUserId': 'user-1',
        'name': 'Minimal Farm',
        'phone': null,
        'email': null,
        'location': null,
        'region': null,
        'country': null,
        'farmType': null,
        'registrationNo': null,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
        'deletedAt': null,
        'version': 1,
      };

      final farm = FarmModel.fromJson(json);

      expect(farm.name, 'Minimal Farm');
      expect(farm.phone, isNull);
      expect(farm.locationSummary, '');
    });

    test('locationSummary skips missing parts gracefully', () {
      final json = {
        'id': 'farm-3',
        'ownerUserId': 'user-1',
        'name': 'Partial Location Farm',
        'phone': null,
        'email': null,
        'location': 'Kabarak',
        'region': null,
        'country': 'Kenya',
        'farmType': null,
        'registrationNo': null,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
        'deletedAt': null,
        'version': 1,
      };

      final farm = FarmModel.fromJson(json);

      expect(farm.locationSummary, 'Kabarak, Kenya');
    });
  });

  group('FarmModel.toJson', () {
    test('round-trips through fromJson/toJson', () {
      final original = FarmModel(
        id: 'farm-1',
        ownerUserId: 'user-1',
        name: 'Caro Test Farm',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
        version: 1,
      );

      final roundTripped = FarmModel.fromJson(original.toJson());

      expect(roundTripped.id, original.id);
      expect(roundTripped.name, original.name);
      expect(roundTripped.createdAt, original.createdAt);
    });
  });
}
