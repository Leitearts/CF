import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Owns the app-wide "am I logged in" state. Consumed by the router (see
/// routing/app_router.dart) to redirect between the auth stack and the main
/// app shell. This is deliberately separate from the per-form controllers
/// (LoginController etc.) which only track that individual form's submit
/// lifecycle.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState.checking()) {
    _checkExistingSession();
  }

  final AuthRepository _repository;

  Future<void> _checkExistingSession() async {
    final hasSession = await _repository.hasValidSession();
    // Sprint 1 only confirms a refresh token exists locally; the first
    // authenticated API call will transparently refresh/validate it. A
    // dedicated "GET /auth/me" hydration call can replace this in Sprint 2
    // once the user's own profile endpoint exists.
    state = hasSession ? const _PendingRehydrate() : const AuthState.unauthenticated();
  }

  void onAuthenticated(UserModel user) {
    state = AuthState.authenticated(user);
  }

  /// Called by ApiClient when a refresh attempt fails -- the refresh token
  /// itself is no longer valid, so treat this as a full logout.
  void forceLogout() {
    state = const AuthState.unauthenticated();
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState.unauthenticated();
  }
}

/// Session exists locally (a refresh token was found) but we haven't loaded
/// the user's profile yet this launch. Treated as "authenticated enough to
/// enter the app shell" by the router; the dashboard/profile call in Sprint 2
/// will populate the full user object or bounce to Login if the token is
/// actually invalid.
class _PendingRehydrate extends AuthState {
  const _PendingRehydrate() : super(status: AuthStatus.authenticated);
}
