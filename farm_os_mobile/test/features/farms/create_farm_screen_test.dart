import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farm_os_mobile/features/farms/presentation/screens/create_farm_screen.dart';

/// The onboarding form has ~9 fields stacked in a ListView -- taller than
/// the default 800x600 test surface, which meant the submit button (last
/// child) was never laid out/found by the finder. Using a taller test
/// viewport is simpler and less flaky than scrolling-to-element for every
/// test that needs to reach the bottom of this form.
void _useTallTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('shows a validation error when farm name is left blank', (tester) async {
    _useTallTestViewport(tester);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: CreateFarmScreen()),
      ),
    );

    // Submitting with the required "Farm name" field empty should surface
    // the validator's message and never reach the network layer.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Farm'));
    await tester.pump();

    expect(find.text('Farm name is required.'), findsOneWidget);
  });

  testWidgets('shows the onboarding heading and does not show an app bar', (tester) async {
    _useTallTestViewport(tester);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: CreateFarmScreen()),
      ),
    );

    expect(find.text("Let's set up your farm"), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('shows an app bar and different title when not onboarding', (tester) async {
    _useTallTestViewport(tester);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: CreateFarmScreen(isOnboarding: false)),
      ),
    );

    expect(find.text("Let's set up your farm"), findsNothing);
    expect(find.text('Add Farm'), findsOneWidget); // AppBar title
    expect(find.widgetWithText(ElevatedButton, 'Save Farm'), findsOneWidget);
  });

  testWidgets('selecting "Other" as farm type reveals a free-text field', (tester) async {
    _useTallTestViewport(tester);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: CreateFarmScreen()),
      ),
    );

    expect(find.text('Describe your farm type'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();

    expect(find.text('Describe your farm type'), findsOneWidget);
  });
}
