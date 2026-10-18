import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/services/crash_reporting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_feedback.dart';
import '../home/main_shell.dart';
import 'login_screen.dart';

/// Decides what to show from the authentication state.
///
/// * While Firebase restores the saved session → splash with a spinner.
/// * Signed out → [LoginScreen].
/// * Signed in → [MainShell].
///
/// Screens never navigate to the app or back to login themselves: they call
/// the repository, and this widget reacts to the new user value. That is
/// also how a session is restored when the app is reopened.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late AuthRepository _auth;
  bool _listening = false;
  bool _ready = false;
  String? _uid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_listening) return;
    _listening = true;
    _auth = AppScope.of(context).auth;
    _auth.user.addListener(_onUserChanged);
    _auth.ready.then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _uid = _auth.currentUser?.uid;
      _reportUser(_auth.currentUser);
      final restored = _auth.currentUser;
      if (restored != null) {
        // Session restored from the previous launch.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showSuccessSnackBar(
            ScaffoldMessenger.of(context),
            'Welcome back, ${restored.name}! You are still signed in.',
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _auth.user.removeListener(_onUserChanged);
    super.dispose();
  }

  /// Runs on sign-in, sign-out and profile updates.
  void _onUserChanged() {
    if (!_ready) return;
    final user = _auth.currentUser;
    if (user?.uid == _uid) return; // Only the profile changed.
    _uid = user?.uid;
    _reportUser(user);

    // Close Register / Forgot password / dialogs that were opened on top of
    // the gate, so the new home (login or app) is what the user sees.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _reportUser(AppUser? user) {
    AppScope.of(context).analytics.setUserId(user?.uid);
    CrashReporting.setUser(user?.uid);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const _Splash();
    return ValueListenableBuilder<AppUser?>(
      valueListenable: _auth.user,
      builder: (context, user, _) =>
          user == null ? const LoginScreen() : const MainShell(),
    );
  }
}

/// Shown for a moment at start-up while the session is restored.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.casino_outlined, size: 56, color: AppColors.primary),
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Restoring your session...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
