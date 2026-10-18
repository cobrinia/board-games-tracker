import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/custom_text_field.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'widgets/auth_layout.dart';
import 'widgets/social_sign_in_button.dart';

/// Sign-in with email/password or Google (Apple on iOS/macOS).
///
/// The screen only calls [AuthRepository]. After a successful sign-in the
/// [AuthGate] sees the new user and replaces this screen with the app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Which request is running; null when idle. Disables the whole form.
  String? _busyWith;

  bool get _busy => _busyWith != null;

  /// Sign in with Apple needs an Apple developer account and only works
  /// natively on Apple platforms, so the button is hidden elsewhere.
  static bool get _showApple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await _run('email', () {
      return AppScope.of(context).auth.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    });
  }

  Future<void> _signInWith(SocialProvider provider) {
    final auth = AppScope.of(context).auth;
    return _run(provider.name, switch (provider) {
      SocialProvider.google => auth.signInWithGoogle,
      SocialProvider.apple => auth.signInWithApple,
    });
  }

  /// Runs a sign-in request with a loading state and readable errors.
  Future<void> _run(String method, Future<void> Function() request) async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final auth = AppScope.of(context).auth;
    setState(() => _busyWith = method);
    try {
      await request();
      showSuccessSnackBar(
        messenger,
        'Signed in as ${auth.currentUser?.email ?? 'you'}',
      );
    } on AuthException catch (error) {
      if (!error.isCancelled) showErrorSnackBar(messenger, error.message);
    } finally {
      if (mounted) setState(() => _busyWith = null);
    }
  }

  void _openForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'forgot_password'),
        builder: (_) =>
            ForgotPasswordScreen(initialEmail: _emailController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AuthLayout(
        content: [
          const SizedBox(height: 24),
          const AuthHeader(
            icon: Icons.casino_outlined,
            title: 'GameShelf',
            subtitle: 'Your Board Game Companion',
          ),
          const SizedBox(height: 48),
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  label: 'Email Address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: !_busy,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Password',
                  controller: _passwordController,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  enabled: !_busy,
                  validator: Validators.password,
                  onFieldSubmitted: (_) => _signIn(),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : _openForgotPassword,
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: 8),
          const OrDivider(),
          const SizedBox(height: 16),
          SocialSignInButton(
            provider: SocialProvider.google,
            isLoading: _busyWith == SocialProvider.google.name,
            onPressed: _busy ? null : () => _signInWith(SocialProvider.google),
          ),
          if (_showApple) ...[
            const SizedBox(height: 12),
            SocialSignInButton(
              provider: SocialProvider.apple,
              isLoading: _busyWith == SocialProvider.apple.name,
              onPressed: _busy
                  ? null
                  : () => _signInWith(SocialProvider.apple),
            ),
          ],
        ],
        actions: [
          PrimaryButton(
            label: 'Sign In',
            isLoading: _busyWith == 'email',
            onPressed: _busy ? null : _signIn,
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            label: 'Create Account',
            onPressed: _busy
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'register'),
                      builder: (_) => const RegisterScreen(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
