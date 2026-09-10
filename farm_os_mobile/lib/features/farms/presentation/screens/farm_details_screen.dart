import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../application/farms_state.dart';
import '../../data/models/farm_model.dart';
import '../../farms_providers.dart';
import '../widgets/farm_switcher_sheet.dart';

class FarmDetailsScreen extends ConsumerWidget {
  const FarmDetailsScreen({super.key, required this.farmId});

  final String farmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmsState = ref.watch(farmsControllerProvider);

    FarmModel? farm;
    if (farmsState is FarmsLoaded) {
      for (final f in farmsState.farms) {
        if (f.id == farmId) farm = f;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Details'),
        actions: farm != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  onPressed: () => context.push('/farms/$farmId/edit'),
                ),
              ]
            : null,
      ),
      body: switch (farmsState) {
        FarmsInitial() || FarmsLoading() => const LoadingIndicator(),
        FarmsError(:final failure) => ErrorView(
            message: failure.message,
            onRetry: () => ref.read(farmsControllerProvider.notifier).loadFarms(),
          ),
        FarmsLoaded() when farm == null => const ErrorView(
            message: "We couldn't find that farm.",
          ),
        FarmsLoaded() => _FarmDetailsBody(farm: farm!),
      },
    );
  }
}

class _FarmDetailsBody extends StatelessWidget {
  const _FarmDetailsBody({required this.farm});

  final FarmModel farm;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        _Section(
          title: 'Farm Information',
          rows: {
            'Name': farm.name,
            'Farm Type': farm.farmType,
            'Registration Number': farm.registrationNo,
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        _Section(
          title: 'Contact',
          rows: {
            'Phone': farm.phone,
            'Email': farm.email,
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        _Section(
          title: 'Location',
          rows: {
            'Location': farm.location,
            'Region': farm.region,
            'Country': farm.country,
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton.icon(
          onPressed: () => FarmSwitcherSheet.show(context),
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Switch Farm'),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;

  /// Label -> value. Rows whose value is null or empty are hidden entirely
  /// (Sprint 2 section 15: "Hide fields that are null or unavailable rather
  /// than displaying broken placeholders").
  final Map<String, String?> rows;

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows.entries.where((e) => e.value != null && e.value!.isNotEmpty).toList();

    if (visibleRows.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            for (final row in visibleRows)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        row.key,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(child: Text(row.value!)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
