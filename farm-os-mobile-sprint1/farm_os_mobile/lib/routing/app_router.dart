import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/home_placeholder_screen.dart';
import '../features/auth/application/auth_state.dart';
import '../features/auth/auth_providers.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';

/// Single source of truth for navigation. Redirect logic is centralized here
/// (not scattered across screens) so "where does an authenticated/
/// unauthenticated user belong" is answered in exactly one place.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthStateListenable(ref),
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
          return (isAuthRoute || isSplash) ? '/home' : null;
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
      // TEMPORARY: '/home' is the Sprint 1 placeholder. Sprint 2 replaces
      // this with '/farm-onboarding' (new users) and the real '/dashboard'
      // shell (returning users), per the Farm Onboarding flow in the brief.
      GoRoute(path: '/home', builder: (context, state) => const HomePlaceholderScreen()),
    ],
  );
});

const _authRoutes = {'/login', '/register', '/forgot-password', '/reset-password'};

/// Bridges Riverpod's StateNotifier stream into a Listenable, which is what
/// go_router's refreshListenable expects, so navigation reacts immediately
/// to auth state changes instead of only on the next route push.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      notifyListeners();
    });
  }
}
