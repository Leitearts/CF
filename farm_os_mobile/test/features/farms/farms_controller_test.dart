import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:farm_os_mobile/core/errors/app_failure.dart';
import 'package:farm_os_mobile/core/errors/result.dart';
import 'package:farm_os_mobile/core/storage/local_storage_service.dart';
import 'package:farm_os_mobile/features/farms/application/farms_controller.dart';
import 'package:farm_os_mobile/features/farms/application/farms_state.dart';
import 'package:farm_os_mobile/features/farms/data/models/farm_model.dart';
import 'package:farm_os_mobile/features/farms/data/repositories/farms_repository.dart';

class MockFarmsRepository extends Mock implements FarmsRepository {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

FarmModel _farm(String id, {String name = 'Farm'}) => FarmModel(
      id: id,
      ownerUserId: 'user-1',
      name: name,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      version: 1,
    );

void main() {
  late MockFarmsRepository repository;
  late MockLocalStorageService localStorage;
  late FarmsController controller;

  setUp(() {
    repository = MockFarmsRepository();
    localStorage = MockLocalStorageService();
    when(() => localStorage.setActiveFarmId(any())).thenAnswer((_) async {});
    when(() => localStorage.clearActiveFarmId()).thenAnswer((_) async {});
    controller = FarmsController(repository: repository, localStorage: localStorage);
  });

  test('zero farms -> FarmsLoaded with hasNoFarms true (onboarding stage)', () async {
    when(() => localStorage.activeFarmId).thenReturn(null);
    when(() => repository.getFarms()).thenAnswer((_) async => const Result.success([]));

    await controller.loadFarms();

    final state = controller.state as FarmsLoaded;
    expect(state.hasNoFarms, isTrue);
    expect(state.activeFarmId, isNull);
  });

  test('exactly one farm and no stored active id -> auto-selects it', () async {
    when(() => localStorage.activeFarmId).thenReturn(null);
    when(() => repository.getFarms()).thenAnswer((_) async => Result.success([_farm('farm-1')]));

    await controller.loadFarms();

    final state = controller.state as FarmsLoaded;
    expect(state.activeFarmId, 'farm-1');
    verify(() => localStorage.setActiveFarmId('farm-1')).called(1);
  });

  test('multiple farms and no stored active id -> selection stage (activeFarmId null)', () async {
    when(() => localStorage.activeFarmId).thenReturn(null);
    when(() => repository.getFarms())
        .thenAnswer((_) async => Result.success([_farm('farm-1'), _farm('farm-2')]));

    await controller.loadFarms();

    final state = controller.state as FarmsLoaded;
    expect(state.hasMultipleFarms, isTrue);
    expect(state.activeFarmId, isNull);
  });

  test('stored activeFarmId matching a real farm is kept', () async {
    when(() => localStorage.activeFarmId).thenReturn('farm-2');
    when(() => repository.getFarms())
        .thenAnswer((_) async => Result.success([_farm('farm-1'), _farm('farm-2')]));

    await controller.loadFarms();

    final state = controller.state as FarmsLoaded;
    expect(state.activeFarmId, 'farm-2');
    verifyNever(() => localStorage.clearActiveFarmId());
  });

  test('stored activeFarmId that no longer matches any farm is cleared', () async {
    when(() => localStorage.activeFarmId).thenReturn('deleted-farm');
    when(() => repository.getFarms())
        .thenAnswer((_) async => Result.success([_farm('farm-1'), _farm('farm-2')]));

    await controller.loadFarms();

    final state = controller.state as FarmsLoaded;
    expect(state.activeFarmId, isNull); // 2 farms remain -> selection stage, not auto-selected
    verify(() => localStorage.clearActiveFarmId()).called(1);
  });

  test('a repository failure produces FarmsError', () async {
    when(() => localStorage.activeFarmId).thenReturn(null);
    when(() => repository.getFarms()).thenAnswer(
      (_) async => const Result.failure(
        AppFailure(type: FailureType.network, message: 'network down'),
      ),
    );

    await controller.loadFarms();

    expect(controller.state, isA<FarmsError>());
  });

  test('selectFarm ignores an id not present in the loaded farms list', () async {
    when(() => localStorage.activeFarmId).thenReturn(null);
    when(() => repository.getFarms())
        .thenAnswer((_) async => Result.success([_farm('farm-1'), _farm('farm-2')]));
    await controller.loadFarms();

    await controller.selectFarm('not-a-real-farm-id');

    final state = controller.state as FarmsLoaded;
    expect(state.activeFarmId, isNull);
    verifyNever(() => localStorage.setActiveFarmId('not-a-real-farm-id'));
  });

  test('selectFarm persists and updates state for a valid farm id', () async {
    when(() => localStorage.activeFarmId).thenReturn(null);
    when(() => repository.getFarms())
        .thenAnswer((_) async => Result.success([_farm('farm-1'), _farm('farm-2')]));
    await controller.loadFarms();

    await controller.selectFarm('farm-2');

    final state = controller.state as FarmsLoaded;
    expect(state.activeFarmId, 'farm-2');
    verify(() => localStorage.setActiveFarmId('farm-2')).called(1);
  });

  test('onFarmCreated appends the farm and makes it active', () async {
    when(() => localStorage.activeFarmId).thenReturn(null);
    when(() => repository.getFarms()).thenAnswer((_) async => const Result.success([]));
    await controller.loadFarms();

    await controller.onFarmCreated(_farm('new-farm', name: 'New Farm'));

    final state = controller.state as FarmsLoaded;
    expect(state.farms, hasLength(1));
    expect(state.activeFarmId, 'new-farm');
  });

  test('onFarmUpdated replaces the matching farm without changing activeFarmId', () async {
    when(() => localStorage.activeFarmId).thenReturn('farm-1');
    when(() => repository.getFarms())
        .thenAnswer((_) async => Result.success([_farm('farm-1', name: 'Old Name')]));
    await controller.loadFarms();

    controller.onFarmUpdated(_farm('farm-1', name: 'New Name'));

    final state = controller.state as FarmsLoaded;
    expect(state.farms.first.name, 'New Name');
    expect(state.activeFarmId, 'farm-1');
  });
}
