import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/application/auth_state.dart';
import '../features/auth/auth_providers.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/farms/application/farms_state.dart';
import '../features/farms/farms_providers.dart';
import '../features/farms/presentation/screens/create_farm_screen.dart';
import '../features/farms/presentation/screens/edit_farm_screen.dart';
import '../features/farms/presentation/screens/farm_dashboard_screen.dart';
import '../features/farms/presentation/screens/farm_details_screen.dart';
import '../features/farms/presentation/screens/farm_selection_screen.dart';

/// Single source of truth for navigation. Auth-stage redirect logic is
/// unchanged from Sprint 1; farm-stage redirect logic is layered on top of
/// it following the same pattern (read state, compute target, redirect only
/// when the current location isn't already valid for that stage -- this is
/// what keeps it loop-free per section 19).
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AppStateListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isAuthRoute = _authRoutes.contains(state.matchedLocation);
      final isSplash = state.matchedLocation == '/splash';

      switch (authState.status) {
        case AuthStatus.checking:
          return isSplash ? null : '/splash';

        case AuthStatus.unauthenticated:
          return isAuthRoute ? null : '/login';

        case AuthStatus.authenticated:
          final farmsState = ref.read(farmsControllerProvider);
          final stage = _resolveFarmStage(farmsState);

          if (stage != _FarmStage.ready) {
            final allowed = _stageAllowedRoutes[stage]!;
            return allowed.contains(state.matchedLocation) ? null : allowed.first;
          }

          // Farm resolution complete (an active farm exists): only force a
          // redirect away from splash/auth routes -- everything else
          // (dashboard, farm details/edit, adding another farm) is free
          // navigation the app itself controls via context.push/pop/go.
          if (isSplash || isAuthRoute) return '/dashboard';
          return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(identifier: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/farms/create',
        builder: (context, state) {
          // Onboarding (no farms yet) vs "add another farm" (already has an
          // active farm) look identical to the form itself -- only the
          // app bar differs. isOnboarding defaults true; the dashboard's
          // "Add Farm" entry point can override via extra if/when Sprint 3
          // adds it. For now Sprint 2 only reaches this route via onboarding
          // or the farm-selection screen's FAB.
          return const CreateFarmScreen();
        },
      ),
      GoRoute(path: '/farms', builder: (context, state) => const FarmSelectionScreen()),
      GoRoute(
        path: '/farms/:farmId',
        builder: (context, state) =>
            FarmDetailsScreen(farmId: state.pathParameters['farmId']!),
      ),
      GoRoute(
        path: '/farms/:farmId/edit',
        builder: (context, state) => EditFarmScreen(farmId: state.pathParameters['farmId']!),
      ),
      GoRoute(path: '/dashboard', builder: (context, state) => const FarmDashboardScreen()),
    ],
  );
});

const _authRoutes = {'/login', '/register', '/forgot-password', '/reset-password'};

enum _FarmStage { loading, error, onboarding, selection, ready }

/// Which routes are valid to already be sitting on for a given non-ready
/// stage, without forcing a redirect. `.first` is used as the redirect
/// target when the current route ISN'T in this set.
final Map<_FarmStage, List<String>> _stageAllowedRoutes = {
  // Loading is allowed to stay put on /farms or /farms/create too, so a
  // pull-to-retry from FarmSelectionScreen doesn't yank the user back to
  // the splash screen mid-retry.
  _FarmStage.loading: ['/splash', '/farms', '/farms/create'],
  _FarmStage.error: ['/farms'],
  _FarmStage.onboarding: ['/farms/create'],
  _FarmStage.selection: ['/farms'],
};

_FarmStage _resolveFarmStage(FarmsState farmsState) {
  return switch (farmsState) {
    FarmsInitial() || FarmsLoading() => _FarmStage.loading,
    FarmsError() => _FarmStage.error,
    FarmsLoaded(hasNoFarms: true) => _FarmStage.onboarding,
    FarmsLoaded(activeFarmId: null) => _FarmStage.selection,
    FarmsLoaded() => _FarmStage.ready,
  };
}

/// Bridges Riverpod state changes into a Listenable, which is what
/// go_router's refreshListenable expects. Listens to BOTH auth and farms
/// state so navigation reacts immediately to either changing (e.g. farms
/// finishing their initial load right after login).
class _AppStateListenable extends ChangeNotifier {
  _AppStateListenable(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      notifyListeners();
    });
    ref.listen<FarmsState>(farmsControllerProvider, (previous, next) {
      notifyListeners();
    });
  }
}
