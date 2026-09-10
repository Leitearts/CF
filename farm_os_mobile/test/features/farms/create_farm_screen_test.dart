import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farm_os_mobile/features/farms/presentation/screens/create_farm_screen.dart';

void main() {
  testWidgets('shows a validation error when farm name is left blank', (tester) async {
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
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: CreateFarmScreen()),
      ),
    );

    expect(find.text("Let's set up your farm"), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('shows an app bar and different title when not onboarding', (tester) async {
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
