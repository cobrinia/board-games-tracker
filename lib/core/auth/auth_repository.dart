import 'package:flutter/foundation.dart';

import 'app_user.dart';

export 'app_user.dart';
export 'auth_exception.dart';

/// Everything the app can do with user accounts.
///
/// Screens depend only on this interface. The real implementation is
/// [FirebaseAuthRepository]; widget tests use a fake one, so they run
/// without Firebase.
///
/// Every method that talks to the server throws an [AuthException] with a
/// user-friendly message when it fails.
abstract class AuthRepository {
  /// The signed-in user, or null. Changes on sign-in, sign-out and
  /// profile updates, so widgets can rebuild with [ValueListenableBuilder].
  ValueListenable<AppUser?> get user;

  /// Completes once the saved session has been restored (or found empty).
  Future<void> get ready;

  AppUser? get currentUser => user.value;

  /// Creates an email/password account, saves [name] as the display name
  /// and sends a verification email.
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signIn({required String email, required String password});

  Future<void> signInWithGoogle();

  /// Only offered on iOS/macOS (needs an Apple developer account).
  Future<void> signInWithApple();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> sendEmailVerification();

  /// Saves a new display name and/or photo URL.
  Future<void> updateProfile({String? displayName, String? photoUrl});

  /// Confirms [currentPassword] and then sets [newPassword].
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Adds Google as a second way to sign in to the current account.
  Future<void> linkGoogle();

  Future<void> signOut();
}
