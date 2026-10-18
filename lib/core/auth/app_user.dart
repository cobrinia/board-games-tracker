/// The signed-in user as the UI sees it.
///
/// Screens never touch Firebase types directly: the repository converts a
/// Firebase `User` into this plain class, so widgets stay easy to test.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
    this.providers = const {},
  });

  /// Provider ids used by Firebase Auth.
  static const String passwordProvider = 'password';
  static const String googleProvider = 'google.com';
  static const String appleProvider = 'apple.com';

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;

  /// Sign-in methods linked to this account, e.g. {'password', 'google.com'}.
  final Set<String> providers;

  /// Name for greetings: display name, or the part of the email before "@".
  String get name {
    final display = displayName?.trim() ?? '';
    if (display.isNotEmpty) return display;
    return email.contains('@') ? email.split('@').first : email;
  }

  bool get hasPassword => providers.contains(passwordProvider);
  bool get hasGoogle => providers.contains(googleProvider);
}
