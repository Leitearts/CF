import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farm_os_mobile/features/farms/data/models/farm_model.dart';
import 'package:farm_os_mobile/features/farms/presentation/widgets/farm_card.dart';

FarmModel _farm({String? location, String? region, String? country, String? farmType}) {
  return FarmModel(
    id: 'farm-1',
    ownerUserId: 'user-1',
    name: 'Caro Test Farm',
    location: location,
    region: region,
    country: country,
    farmType: farmType,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    version: 1,
  );
}

void main() {
  testWidgets('shows the farm name and location summary when available', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FarmCard(
            farm: _farm(location: 'Kabarak', region: 'Nakuru'),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Caro Test Farm'), findsOneWidget);
    expect(find.text('Kabarak, Nakuru'), findsOneWidget);
  });

  testWidgets('does not render a location line when no location fields are set', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FarmCard(farm: _farm(), onTap: () {})),
      ),
    );

    expect(find.text('Caro Test Farm'), findsOneWidget);
    // No location text anywhere -- an empty locationSummary must not render
    // as an awkward blank line or "null, null".
    expect(find.textContaining('null'), findsNothing);
  });

  testWidgets('shows a check icon when active, chevron when not', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FarmCard(farm: _farm(), onTap: () {}, isActive: true)),
      ),
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('tapping the card triggers onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FarmCard(farm: _farm(), onTap: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.byType(FarmCard));
    expect(tapped, isTrue);
  });
}
