import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/analytics_service.dart';
import '../services/crash_reporting.dart';
import 'auth_repository.dart';

/// [AuthRepository] backed by Firebase Authentication.
///
/// All Firebase calls go through [_guard], which turns a
/// [FirebaseAuthException] into an [AuthException] with a message the
/// user can understand, and reports unexpected errors to Crashlytics.
class FirebaseAuthRepository extends AuthRepository {
  FirebaseAuthRepository({
    required this._analytics,
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance {
    // userChanges() fires on sign-in, sign-out and profile updates. Its first
    // event tells us whether a saved session was restored.
    _subscription = _auth.userChanges().listen((user) {
      _user.value = user == null ? null : _toAppUser(user);
      if (!_ready.isCompleted) _ready.complete();
    });
  }

  final FirebaseAuth _auth;
  final AnalyticsService _analytics;
  final ValueNotifier<AppUser?> _user = ValueNotifier(null);
  final Completer<void> _ready = Completer<void>();
  late final StreamSubscription<User?> _subscription;

  @override
  ValueListenable<AppUser?> get user => _user;

  @override
  Future<void> get ready => _ready.future;

  // ---------------------------------------------------------------- sign up / in

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) => _guard(() async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(name.trim());
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error, stack) {
      // The account already exists; a missing email must not fail sign-up.
      await CrashReporting.recordNonFatal(
        error,
        stack,
        reason: 'Verification email after sign-up failed',
      );
    }
    await _refreshUser();
    await _analytics.logSignUp('email');
  });

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(() async {
        await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        await _analytics.logLogin('email');
      });

  @override
  Future<void> signInWithGoogle() => _guard(() async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    final result = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    await _logProviderSignIn(result, 'google');
  });

  @override
  Future<void> signInWithApple() => _guard(() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    final result = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    await _logProviderSignIn(result, 'apple');
  });

  Future<void> _logProviderSignIn(UserCredential result, String method) {
    final isNewUser = result.additionalUserInfo?.isNewUser ?? false;
    return isNewUser
        ? _analytics.logSignUp(method)
        : _analytics.logLogin(method);
  }

  // ---------------------------------------------------------------- email

  @override
  Future<void> sendPasswordResetEmail(String email) => _guard(() async {
    await _auth.sendPasswordResetEmail(email: email.trim());
    await _analytics.logEvent('password_reset_requested');
  });

  @override
  Future<void> sendEmailVerification() => _guard(() async {
    await _requireUser().sendEmailVerification();
  });

  // ---------------------------------------------------------------- profile

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) =>
      _guard(() async {
        final user = _requireUser();
        if (displayName != null) {
          await user.updateDisplayName(displayName.trim());
        }
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl.isEmpty ? null : photoUrl);
        }
        await _refreshUser();
        await _analytics.logEvent('profile_updated', {
          'changed_name': displayName != null ? 1 : 0,
          'changed_photo': photoUrl != null ? 1 : 0,
        });
      });

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _guard(() async {
    final user = _requireUser();
    final email = user.email;
    final hasPassword = user.providerData.any(
      (info) => info.providerId == AppUser.passwordProvider,
    );
    if (email == null || !hasPassword) {
      throw const AuthException(
        'This account signs in with Google, so it has no password to change.',
        code: 'no-password',
      );
    }

    // Changing a password is a sensitive operation: Firebase rejects it with
    // `requires-recent-login` if the last sign-in was too long ago. Confirming
    // the current password first refreshes the sign-in and also checks that
    // the person holding the phone really knows the old password.
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: currentPassword),
      );
    } on FirebaseAuthException catch (error) {
      if (_wrongCredentialCodes.contains(error.code)) {
        throw const AuthException(
          'The current password is incorrect.',
          code: 'wrong-password',
        );
      }
      rethrow;
    }

    await user.updatePassword(newPassword);
    await _analytics.logEvent('password_changed');
  });

  @override
  Future<void> linkGoogle() => _guard(() async {
    final user = _requireUser();
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    if (kIsWeb) {
      await user.linkWithPopup(provider);
    } else {
      await user.linkWithProvider(provider);
    }
    await _refreshUser();
    await _analytics.logEvent('account_linked', {'provider': 'google'});
  });

  @override
  Future<void> signOut() => _guard(() async {
    await _analytics.logEvent('logout');
    await _auth.signOut();
  });

  // ---------------------------------------------------------------- helpers

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(
        'You are signed out. Please sign in again.',
        code: 'no-current-user',
      );
    }
    return user;
  }

  /// Reloads the user from the server and republishes it, so the UI shows
  /// a new name, photo or linked provider right away.
  Future<void> _refreshUser() async {
    await _auth.currentUser?.reload();
    final user = _auth.currentUser;
    _user.value = user == null ? null : _toAppUser(user);
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw _toAuthException(error);
    } catch (error, stack) {
      // Not an expected auth failure: keep a report so it can be fixed.
      await CrashReporting.recordNonFatal(
        error,
        stack,
        reason: 'Unexpected error in FirebaseAuthRepository',
      );
      throw const AuthException('Something went wrong. Please try again.');
    }
  }

  static AppUser _toAppUser(User user) => AppUser(
    uid: user.uid,
    email: user.email ?? '',
    displayName: user.displayName,
    photoUrl: user.photoURL,
    emailVerified: user.emailVerified,
    providers: {for (final info in user.providerData) info.providerId},
  );

  static const Set<String> _wrongCredentialCodes = {
    'wrong-password',
    'invalid-credential',
    'invalid-login-credentials',
    'INVALID_LOGIN_CREDENTIALS',
    'user-mismatch',
  };

  static const Set<String> _cancelledCodes = {
    'canceled',
    'cancelled',
    'web-context-canceled',
    'web-context-cancelled',
    'popup-closed-by-user',
    'cancelled-popup-request',
    'user-cancelled',
  };

  /// Firebase error code → message for the user.
  static AuthException _toAuthException(FirebaseAuthException error) {
    final code = error.code;
    if (_cancelledCodes.contains(code)) return const AuthException.cancelled();
    if (_wrongCredentialCodes.contains(code) || code == 'user-not-found') {
      return AuthException(
        'Could not sign in. Check your email and password.',
        code: code,
      );
    }
    final message = switch (code) {
      'invalid-email' => 'The email address is not valid.',
      'user-disabled' => 'This account has been disabled.',
      'email-already-in-use' =>
        'An account with this email already exists. Sign in instead.',
      'weak-password' =>
        'The password is too weak. Use at least 8 characters with letters '
            'and numbers.',
      'too-many-requests' =>
        'Too many attempts. Please wait a few minutes and try again.',
      'network-request-failed' =>
        'No internet connection. Check your network and try again.',
      'requires-recent-login' =>
        'For security reasons, please sign out and sign in again, then '
            'repeat this action.',
      'operation-not-allowed' =>
        'This sign-in method is turned off for the app.',
      'account-exists-with-different-credential' =>
        'An account with this email already exists. Sign in with your '
            'password, then link Google in Settings.',
      'credential-already-in-use' =>
        'This Google account is already used by another GameShelf account.',
      'provider-already-linked' => 'Google is already linked to your account.',
      'user-token-expired' => 'Your session has expired. Please sign in again.',
      _ => 'Something went wrong. Please try again.',
    };
    return AuthException(message, code: code);
  }

  /// Stops listening to Firebase. Call when the repository is thrown away.
  void dispose() {
    _subscription.cancel();
    _user.dispose();
  }
}
