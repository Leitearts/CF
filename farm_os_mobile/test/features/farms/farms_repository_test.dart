import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:farm_os_mobile/core/errors/app_failure.dart';
import 'package:farm_os_mobile/features/farms/data/datasources/farms_remote_data_source.dart';
import 'package:farm_os_mobile/features/farms/data/models/create_farm_input.dart';
import 'package:farm_os_mobile/features/farms/data/models/farm_model.dart';
import 'package:farm_os_mobile/features/farms/data/models/update_farm_input.dart';
import 'package:farm_os_mobile/features/farms/data/repositories/farms_repository.dart';

class MockFarmsRemoteDataSource extends Mock implements FarmsRemoteDataSource {}

FarmModel _sampleFarm({String id = 'farm-1'}) => FarmModel(
      id: id,
      ownerUserId: 'user-1',
      name: 'Caro Test Farm',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      version: 1,
    );

void main() {
  late MockFarmsRemoteDataSource remote;
  late FarmsRepository repository;

  setUp(() {
    remote = MockFarmsRemoteDataSource();
    repository = FarmsRepository(remote);
  });

  group('getFarms', () {
    test('returns Success with the farms on a successful call', () async {
      when(() => remote.getFarms()).thenAnswer((_) async => [_sampleFarm()]);

      final result = await repository.getFarms();

      expect(result.isSuccess, isTrue);
      result.when(
        success: (farms) => expect(farms, hasLength(1)),
        failure: (_) => fail('expected success'),
      );
    });

    test('returns Failure with a mapped AppFailure on a network error', () async {
      when(() => remote.getFarms()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/farms'),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repository.getFarms();

      expect(result.isSuccess, isFalse);
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) => expect(failure.type, FailureType.network),
      );
    });
  });

  group('createFarm', () {
    test('returns Success with the created farm', () async {
      const input = CreateFarmInput(name: 'Caro Test Farm');
      when(() => remote.createFarm(input)).thenAnswer((_) async => _sampleFarm());

      final result = await repository.createFarm(input);

      expect(result.isSuccess, isTrue);
    });

    test('surfaces a validation failure from the backend', () async {
      const input = CreateFarmInput(name: '');
      when(() => remote.createFarm(input)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/farms'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/farms'),
            statusCode: 422,
            data: {
              'success': false,
              'error': {'message': 'Farm name is required.'},
            },
          ),
        ),
      );

      final result = await repository.createFarm(input);

      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure.type, FailureType.validation);
          expect(failure.message, 'Farm name is required.');
        },
      );
    });
  });

  group('updateFarm', () {
    test('returns Success with the updated farm', () async {
      const input = UpdateFarmInput(name: 'Renamed Farm');
      when(() => remote.updateFarm('farm-1', input))
          .thenAnswer((_) async => _sampleFarm(id: 'farm-1'));

      final result = await repository.updateFarm('farm-1', input);

      expect(result.isSuccess, isTrue);
    });

    test('surfaces a 403 as a forbidden failure', () async {
      const input = UpdateFarmInput(name: 'Renamed Farm');
      when(() => remote.updateFarm('farm-1', input)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/farms/farm-1'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/farms/farm-1'),
            statusCode: 403,
          ),
        ),
      );

      final result = await repository.updateFarm('farm-1', input);

      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) => expect(failure.isForbidden, isTrue),
      );
    });
  });
}
