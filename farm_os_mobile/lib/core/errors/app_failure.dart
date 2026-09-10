/// What kind of problem occurred, independent of the transport used to
/// discover it (Dio, storage, etc). Screens branch on this, never on raw
/// exception types or HTTP status codes.
enum FailureType {
  network,
  timeout,
  unauthorized,
  forbidden,
  validation,
  notFound,
  server,
  unknown,
}

/// A user-safe representation of "something went wrong". [message] is
/// always safe to show directly in the UI (see ErrorMapper) -- raw
/// exception text/stack traces must never reach this class's [message].
class AppFailure implements Exception {
  const AppFailure({
    required this.type,
    required this.message,
    this.fieldErrors,
  });

  final FailureType type;
  final String message;

  /// Field-level validation errors from the backend, e.g. {"quantity": "must
  /// be greater than 0"}, so forms can highlight the specific field instead
  /// of showing a generic banner.
  final Map<String, String>? fieldErrors;

  bool get isAuthError => type == FailureType.unauthorized;
  bool get isForbidden => type == FailureType.forbidden;

  @override
  String toString() => message;
}
