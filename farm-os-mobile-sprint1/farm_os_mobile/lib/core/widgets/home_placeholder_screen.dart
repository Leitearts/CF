import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_providers.dart';
import '../theme/app_spacing.dart';

/// TEMPORARY: Sprint 1 only needs to prove Login -> "you're in" works.
/// This screen is replaced entirely by the real Dashboard in Sprint 2
/// (Section 10 of the Stage 4 brief).
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm OS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You're logged in.",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              authState.user != null
                  ? 'Welcome, ${authState.user!.fullName}.'
                  : 'Session restored from a previous login.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Sprint 1 (Foundation) is complete: authentication, theming, '
              'routing, secure storage, and the API client are all wired up '
              'end-to-end.\n\nFarm onboarding and the real Dashboard land in Sprint 2.',
            ),
          ],
        ),
      ),
    );
  }
}
