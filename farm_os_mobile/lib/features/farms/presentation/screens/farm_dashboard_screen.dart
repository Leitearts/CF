import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/auth_providers.dart';
import '../../application/farms_state.dart';
import '../../data/models/farm_model.dart';
import '../../farms_providers.dart';
import '../widgets/farm_switcher_sheet.dart';

/// The first real Farm OS dashboard. Deliberately does NOT show
/// livestock/feed/finance statistics -- the backend has no such endpoints
/// yet (Sprint 2 section 14: "DO NOT invent dashboard statistics"). Those
/// module cards are shown as clearly-labeled "Coming soon" placeholders.
class FarmDashboardScreen extends ConsumerWidget {
  const FarmDashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmsState = ref.watch(farmsControllerProvider);
    final authState = ref.watch(authControllerProvider);

    if (farmsState is! FarmsLoaded || farmsState.activeFarm == null) {
      // Router should prevent reaching this screen without an active farm,
      // but render a safe loading state instead of crashing if it ever does
      // (e.g. mid-transition right after switching farms).
      return const Scaffold(body: LoadingIndicator());
    }

    final farm = farmsState.activeFarm!;
    final userName = authState.user?.fullName.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => FarmSwitcherSheet.show(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(farm.name, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 4),
              const Icon(Icons.unfold_more, size: 20),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(farmsControllerProvider.notifier).loadFarms(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Text(
              userName != null ? '${_greeting()}, $userName' : _greeting(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            _ActiveFarmCard(farm: farm),
            const SizedBox(height: AppSpacing.xl),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            _QuickActions(farmId: farm.id),
            const SizedBox(height: AppSpacing.xl),
            Text('Coming Soon', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            const _ComingSoonGrid(),
          ],
        ),
      ),
    );
  }
}

class _ActiveFarmCard extends StatelessWidget {
  const _ActiveFarmCard({required this.farm});

  final FarmModel farm;

  @override
  Widget build(BuildContext context) {
    final locationSummary = farm.locationSummary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.agriculture, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    farm.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (locationSummary.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(locationSummary, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
            if (farm.farmType != null && farm.farmType!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.category_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(farm.farmType!, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.farmId});

  final String farmId;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        OutlinedButton.icon(
          onPressed: () => context.push('/farms/$farmId'),
          icon: const Icon(Icons.info_outline),
          label: const Text('Farm Details'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.push('/farms/$farmId/edit'),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Farm'),
        ),
        OutlinedButton.icon(
          onPressed: () => FarmSwitcherSheet.show(context),
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Switch Farm'),
        ),
      ],
    );
  }
}

class _ComingSoonGrid extends StatelessWidget {
  const _ComingSoonGrid();

  static const _modules = [
    ('Livestock', Icons.pets_outlined),
    ('Feed', Icons.grass_outlined),
    ('Drugs', Icons.medication_outlined),
    ('Equipment', Icons.build_outlined),
    ('Finance', Icons.payments_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 2.2,
      children: [
        for (final (label, icon) in _modules)
          Opacity(
            opacity: 0.5,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(icon, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(label, style: Theme.of(context).textTheme.bodyMedium),
                          const Text(
                            'Coming soon',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
