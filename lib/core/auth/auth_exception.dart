/// Error thrown by [AuthRepository] methods.
///
/// [message] is already written for the user, so screens can show it as is
/// instead of the technical text of a Firebase exception.
class AuthException implements Exception {
  const AuthException(this.message, {this.code = 'unknown'});

  /// The user closed the Google/Apple window. Screens ignore this case.
  const AuthException.cancelled()
    : message = 'Sign-in was cancelled.',
      code = 'cancelled';

  final String message;

  /// Firebase error code, e.g. `invalid-credential`. Useful for logs.
  final String code;

  bool get isCancelled => code == 'cancelled';

  /// Firebase wants the user to confirm their identity again.
  bool get requiresRecentLogin => code == 'requires-recent-login';

  @override
  String toString() => 'AuthException($code): $message';
}
