import 'package:board_games/core/auth/auth_repository.dart';
import 'package:flutter/foundation.dart';

/// In-memory [AuthRepository] for widget tests: no Firebase, no network.
///
/// Knows one account: test@example.com / secret123.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({AppUser? signedIn}) : _user = ValueNotifier(signedIn);

  static const String email = 'test@example.com';
  static const String password = 'secret123';

  final ValueNotifier<AppUser?> _user;
  final Map<String, String> _passwords = {email: password};
  final Map<String, String> _names = {email: 'Test Player'};

  /// Last address a reset link was "sent" to.
  String? lastResetEmail;

  @override
  ValueListenable<AppUser?> get user => _user;

  @override
  Future<void> get ready => Future.value();

  AppUser _accountFor(String email, {Set<String>? providers}) => AppUser(
    uid: 'uid-$email',
    email: email,
    displayName: _names[email],
    providers: providers ?? {AppUser.passwordProvider},
  );

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final key = email.trim();
    if (_passwords.containsKey(key)) {
      throw const AuthException(
        'An account with this email already exists. Sign in instead.',
        code: 'email-already-in-use',
      );
    }
    _passwords[key] = password;
    _names[key] = name.trim();
    _user.value = _accountFor(key);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final key = email.trim();
    if (_passwords[key] != password) {
      throw const AuthException(
        'Could not sign in. Check your email and password.',
        code: 'invalid-credential',
      );
    }
    _user.value = _accountFor(key);
  }

  @override
  Future<void> signInWithGoogle() async {
    _user.value = const AppUser(
      uid: 'uid-google',
      email: 'player@gmail.com',
      displayName: 'Google Player',
      emailVerified: true,
      providers: {AppUser.googleProvider},
    );
  }

  @override
  Future<void> signInWithApple() => signInWithGoogle();

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    lastResetEmail = email.trim();
  }

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final current = _user.value!;
    _user.value = AppUser(
      uid: current.uid,
      email: current.email,
      displayName: displayName ?? current.displayName,
      photoUrl: photoUrl ?? current.photoUrl,
      emailVerified: current.emailVerified,
      providers: current.providers,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _user.value!.email;
    if (_passwords[email] != currentPassword) {
      throw const AuthException(
        'The current password is incorrect.',
        code: 'wrong-password',
      );
    }
    _passwords[email] = newPassword;
  }

  @override
  Future<void> linkGoogle() async {
    final current = _user.value!;
    _user.value = AppUser(
      uid: current.uid,
      email: current.email,
      displayName: current.displayName,
      providers: {...current.providers, AppUser.googleProvider},
    );
  }

  @override
  Future<void> signOut() async => _user.value = null;
}
