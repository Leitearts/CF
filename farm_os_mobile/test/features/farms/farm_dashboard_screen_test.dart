import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:farm_os_mobile/core/errors/result.dart';
import 'package:farm_os_mobile/core/storage/local_storage_service.dart';
import 'package:farm_os_mobile/features/auth/application/auth_controller.dart';
import 'package:farm_os_mobile/features/auth/auth_providers.dart';
import 'package:farm_os_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:farm_os_mobile/features/farms/application/farms_controller.dart';
import 'package:farm_os_mobile/features/farms/data/models/farm_model.dart';
import 'package:farm_os_mobile/features/farms/data/repositories/farms_repository.dart';
import 'package:farm_os_mobile/features/farms/farms_providers.dart';
import 'package:farm_os_mobile/features/farms/presentation/screens/farm_dashboard_screen.dart';

class MockFarmsRepository extends Mock implements FarmsRepository {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

class MockAuthRepository extends Mock implements AuthRepository {}

FarmModel _farm(String id, String name, {String? location, String? farmType}) => FarmModel(
      id: id,
      ownerUserId: 'user-1',
      name: name,
      location: location,
      farmType: farmType,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      version: 1,
    );

void main() {
  testWidgets('shows the active farm name, location, and quick actions', (tester) async {
    final farmsRepo = MockFarmsRepository();
    final localStorage = MockLocalStorageService();
    when(() => localStorage.activeFarmId).thenReturn('farm-1');
    when(() => farmsRepo.getFarms()).thenAnswer(
      (_) async => Result.success(
        [_farm('farm-1', 'Caro Test Farm', location: 'Kabarak', farmType: 'Mixed Livestock')],
      ),
    );
    final farmsController = FarmsController(repository: farmsRepo, localStorage: localStorage);
    await farmsController.loadFarms();

    // Backed by a mock so this never touches real secure storage --
    // FarmDashboardScreen only reads authState.user, which stays null here,
    // so the greeting falls back gracefully (already covered by the widget
    // itself; not re-asserted here).
    final authRepo = MockAuthRepository();
    when(() => authRepo.hasValidSession()).thenAnswer((_) async => false);
    final authController = AuthController(authRepo);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          farmsControllerProvider.overrideWith((ref) => farmsController),
          authControllerProvider.overrideWith((ref) => authController),
        ],
        child: const MaterialApp(home: FarmDashboardScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Caro Test Farm'), findsOneWidget);
    expect(find.text('Kabarak'), findsOneWidget);
    expect(find.text('Mixed Livestock'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Farm Details'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Edit Farm'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Switch Farm'), findsOneWidget);
  });

  testWidgets('shows all module cards as "Coming soon"', (tester) async {
    final farmsRepo = MockFarmsRepository();
    final localStorage = MockLocalStorageService();
    when(() => localStorage.activeFarmId).thenReturn('farm-1');
    when(() => farmsRepo.getFarms())
        .thenAnswer((_) async => Result.success([_farm('farm-1', 'Caro Test Farm')]));
    final farmsController = FarmsController(repository: farmsRepo, localStorage: localStorage);
    await farmsController.loadFarms();

    final authRepo = MockAuthRepository();
    when(() => authRepo.hasValidSession()).thenAnswer((_) async => false);
    final authController = AuthController(authRepo);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          farmsControllerProvider.overrideWith((ref) => farmsController),
          authControllerProvider.overrideWith((ref) => authController),
        ],
        child: const MaterialApp(home: FarmDashboardScreen()),
      ),
    );
    await tester.pump();

    for (final label in ['Livestock', 'Feed', 'Drugs', 'Equipment', 'Finance']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Coming soon'), findsNWidgets(5));
  });
}
