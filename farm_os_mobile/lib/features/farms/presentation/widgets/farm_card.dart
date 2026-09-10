import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/farm_model.dart';

class FarmCard extends StatelessWidget {
  const FarmCard({
    super.key,
    required this.farm,
    required this.onTap,
    this.isActive = false,
  });

  final FarmModel farm;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final locationSummary = farm.locationSummary;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cornerRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.agriculture_outlined),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(farm.name, style: Theme.of(context).textTheme.titleMedium),
                    if (locationSummary.isNotEmpty)
                      Text(locationSummary, style: Theme.of(context).textTheme.bodyMedium),
                    if (farm.farmType != null && farm.farmType!.isNotEmpty)
                      Text(farm.farmType!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              if (isActive)
                const Icon(Icons.check_circle, color: Colors.green)
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
