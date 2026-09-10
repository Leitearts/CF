import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../application/farms_state.dart';
import '../../data/models/farm_model.dart';
import '../../farms_providers.dart';
import '../widgets/farm_card.dart';

/// Shown when: farms are still loading, farm loading failed (with retry),
/// or the farmer has farms but none is currently active. Consolidating
/// these into one screen (rather than a separate error route) keeps the
/// farm-resolution flow to a small, loop-free set of routes.
class FarmSelectionScreen extends ConsumerWidget {
  const FarmSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmsState = ref.watch(farmsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Farms'),
        automaticallyImplyLeading: false,
      ),
      body: switch (farmsState) {
        FarmsInitial() || FarmsLoading() => const LoadingIndicator(message: 'Loading your farms...'),
        FarmsError(:final failure) => ErrorView(
            message: failure.message,
            onRetry: () => ref.read(farmsControllerProvider.notifier).loadFarms(),
          ),
        FarmsLoaded(:final farms) => _FarmList(farms: farms, ref: ref),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/farms/create'),
        icon: const Icon(Icons.add),
        label: const Text('Add Farm'),
      ),
    );
  }
}

class _FarmList extends StatelessWidget {
  const _FarmList({required this.farms, required this.ref});

  final List<FarmModel> farms;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (farms.isEmpty) {
      // Reaching this screen with zero farms shouldn't normally happen (the
      // router sends empty-farms straight to onboarding), but handle it
      // gracefully rather than showing a blank list.
      return const Center(child: Text('No farms yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: farms.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final farm = farms[index];
        return FarmCard(
          farm: farm,
          onTap: () => ref.read(farmsControllerProvider.notifier).selectFarm(farm.id),
        );
      },
    );
  }
}
