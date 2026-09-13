import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/auth_providers.dart';
import '../../application/farms_state.dart';
import '../../data/models/farm_model.dart';
import '../../farms_providers.dart';
import '../widgets/farm_form_dialog.dart';

class FarmsHomeScreen extends ConsumerWidget {
  const FarmsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(farmsControllerProvider);

    ref.listen(farmsControllerProvider, (previous, next) {
      if (next.saveFailure != null && previous?.saveFailure != next.saveFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.saveFailure!.message)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Farms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isSaving ? null : () => _showCreateFarmDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Farm'),
      ),
      body: Column(
        children: [
          if (state.isSaving) const LinearProgressIndicator(),
          Expanded(child: _buildBody(context, ref, state)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, FarmsState state) {
    if (state.isLoading) {
      return const LoadingIndicator(message: 'Loading farms...');
    }

    if (state.loadFailure != null) {
      return ErrorView(
        message: state.loadFailure!.message,
        onRetry: () => ref.read(farmsControllerProvider.notifier).loadFarms(),
      );
    }

    if (state.farms.isEmpty) {
      return EmptyStateView(
        message: 'No farms yet. Create your first farm to get started.',
        ctaLabel: 'Create Farm',
        onCtaPressed: () => _showCreateFarmDialog(context, ref),
        icon: Icons.agriculture_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(farmsControllerProvider.notifier).loadFarms(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          _SelectedFarmCard(
            farm: state.selectedFarm,
            onEdit: state.selectedFarm == null
                ? null
                : () => _showUpdateFarmDialog(context, ref, state.selectedFarm!),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('All farms', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...state.farms.map(
            (farm) => Card(
              child: RadioListTile<String>(
                value: farm.id,
                groupValue: state.selectedFarm?.id,
                title: Text(farm.name),
                subtitle: Text(_farmSubtitle(farm)),
                onChanged: (_) => ref.read(farmsControllerProvider.notifier).selectFarm(farm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateFarmDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return FarmFormDialog(
          title: 'Create Farm',
          submitLabel: 'Create',
          onSubmit: (createInput, _) async {
            final success = await ref.read(farmsControllerProvider.notifier).createFarm(createInput);
            if (success && dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          },
        );
      },
    );
  }

  Future<void> _showUpdateFarmDialog(
    BuildContext context,
    WidgetRef ref,
    FarmModel farm,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return FarmFormDialog(
          title: 'Update Farm',
          submitLabel: 'Save Changes',
          initialFarm: farm,
          onSubmit: (_, updateInput) async {
            final success =
                await ref.read(farmsControllerProvider.notifier).updateSelectedFarm(updateInput);
            if (success && dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          },
        );
      },
    );
  }

  String _farmSubtitle(FarmModel farm) {
    final location = [farm.location, farm.region, farm.country]
        .where((part) => part != null && part.isNotEmpty)
        .join(', ');
    return location.isEmpty ? 'Tap to select this farm' : location;
  }
}

class _SelectedFarmCard extends StatelessWidget {
  const _SelectedFarmCard({required this.farm, this.onEdit});

  final FarmModel? farm;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    if (farm == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.cardPadding),
          child: Text('Select a farm to view details.'),
        ),
      );
    }

    final selectedFarm = farm!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedFarm.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _FarmDetailRow(label: 'Phone', value: selectedFarm.phone),
            _FarmDetailRow(label: 'Email', value: selectedFarm.email),
            _FarmDetailRow(label: 'Location', value: selectedFarm.location),
            _FarmDetailRow(label: 'Region', value: selectedFarm.region),
            _FarmDetailRow(label: 'Country', value: selectedFarm.country),
            _FarmDetailRow(label: 'Farm type', value: selectedFarm.farmType),
            _FarmDetailRow(label: 'Registration No.', value: selectedFarm.registrationNo),
          ],
        ),
      ),
    );
  }
}

class _FarmDetailRow extends StatelessWidget {
  const _FarmDetailRow({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text('$label: ${value!.trim()}'),
    );
  }
}
