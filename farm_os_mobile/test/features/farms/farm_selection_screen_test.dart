import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:farm_os_mobile/core/errors/app_failure.dart';
import 'package:farm_os_mobile/core/errors/result.dart';
import 'package:farm_os_mobile/core/storage/local_storage_service.dart';
import 'package:farm_os_mobile/features/farms/application/farms_controller.dart';
import 'package:farm_os_mobile/features/farms/data/models/farm_model.dart';
import 'package:farm_os_mobile/features/farms/data/repositories/farms_repository.dart';
import 'package:farm_os_mobile/features/farms/farms_providers.dart';
import 'package:farm_os_mobile/features/farms/presentation/screens/farm_selection_screen.dart';

class MockFarmsRepository extends Mock implements FarmsRepository {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

FarmModel _farm(String id, String name) => FarmModel(
      id: id,
      ownerUserId: 'user-1',
      name: name,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      version: 1,
    );

void main() {
  testWidgets('lists multiple farms for selection when none is active', (tester) async {
    final repository = MockFarmsRepository();
    final localStorage = MockLocalStorageService();
    when(() => localStorage.activeFarmId).thenReturn(null);
    when(() => localStorage.setActiveFarmId(any())).thenAnswer((_) async {});
    when(() => repository.getFarms()).thenAnswer(
      (_) async =>
          Result.success([_farm('farm-1', 'Caro Test Farm'), _farm('farm-2', 'Other Farm')]),
    );

    final controller = FarmsController(repository: repository, localStorage: localStorage);
    await controller.loadFarms();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [farmsControllerProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: FarmSelectionScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Caro Test Farm'), findsOneWidget);
    expect(find.text('Other Farm'), findsOneWidget);
  });

  testWidgets('tapping a farm calls selectFarm and updates the active farm', (tester) async {
    final repository = MockFarmsRepository();
    final localStorage = MockLocalStorageService();
    when(() => localStorage.activeFarmId).thenReturn(null);
    when(() => localStorage.setActiveFarmId(any())).thenAnswer((_) async {});
    when(() => repository.getFarms()).thenAnswer(
      (_) async =>
          Result.success([_farm('farm-1', 'Caro Test Farm'), _farm('farm-2', 'Other Farm')]),
    );

    final controller = FarmsController(repository: repository, localStorage: localStorage);
    await controller.loadFarms();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [farmsControllerProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: FarmSelectionScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Caro Test Farm'));
    await tester.pump();

    verify(() => localStorage.setActiveFarmId('farm-1')).called(1);
  });

  testWidgets('shows an error state with a retry button when loading fails', (tester) async {
    final repository = MockFarmsRepository();
    final localStorage = MockLocalStorageService();
    when(() => localStorage.activeFarmId).thenReturn(null);
    when(() => repository.getFarms()).thenAnswer(
      (_) async => const Result.failure(
        AppFailure(type: FailureType.network, message: "Couldn't connect. Check your internet."),
      ),
    );

    final controller = FarmsController(repository: repository, localStorage: localStorage);
    await controller.loadFarms();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [farmsControllerProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: FarmSelectionScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Try Again'), findsOneWidget);
  });
}
