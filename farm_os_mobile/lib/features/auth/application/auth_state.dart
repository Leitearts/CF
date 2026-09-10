import '../data/models/user_model.dart';

enum AuthStatus {
  /// Splash is still checking secure storage for an existing session.
  checking,
  authenticated,
  unauthenticated,
}

class AuthState {
  const AuthState({required this.status, this.user});

  final AuthStatus status;
  final UserModel? user;

  const AuthState.checking() : this(status: AuthStatus.checking);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);
  const AuthState.authenticated(UserModel user)
      : this(status: AuthStatus.authenticated, user: user);
}
