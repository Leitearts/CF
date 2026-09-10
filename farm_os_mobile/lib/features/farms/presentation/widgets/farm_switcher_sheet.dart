import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/farms_state.dart';
import '../../farms_providers.dart';
import 'farm_card.dart';

/// "Current Farm -> tap to open -> Your Farms -> [list] -> select" flow from
/// Sprint 2 section 17. Selecting a farm updates activeFarmId immediately
/// and does not require logging out.
class FarmSwitcherSheet extends ConsumerWidget {
  const FarmSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cornerRadius * 2)),
      ),
      builder: (_) => const FarmSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmsState = ref.watch(farmsControllerProvider);

    if (farmsState is! FarmsLoaded) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Farms', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            ...farmsState.farms.map(
              (farm) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: FarmCard(
                  farm: farm,
                  isActive: farm.id == farmsState.activeFarmId,
                  onTap: () {
                    ref.read(farmsControllerProvider.notifier).selectFarm(farm.id);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // Uses go_router at the call site (dashboard screen owns
                // navigation context); this sheet only pops itself.
              },
              icon: const Icon(Icons.close),
              label: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
