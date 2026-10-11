import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/custom_text_field.dart';
import '../home/main_shell.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'widgets/auth_layout.dart';
import 'widgets/social_sign_in_button.dart';

/// Sign-in form. There is no real auth yet: a valid form simply opens
/// the main app shell.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  void _signIn() {
    if (!_formKey.currentState!.validate()) return;
    _openApp();
  }

  /// Google / Apple sign-in. Simulated for now; the real flow needs
  /// Firebase Auth (or google_sign_in / sign_in_with_apple) later.
  void _signInWith(SocialProvider provider) => _openApp();

  /// Simulated successful auth: replace login so Back does not return here.
  void _openApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
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
          const CustomTextField(
            label: 'Email Address',
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 16),
          const CustomTextField(
            label: 'Password',
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: Validators.password,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: 8),
          const OrDivider(),
          const SizedBox(height: 16),
          SocialSignInButton(
            provider: SocialProvider.google,
            onPressed: () => _signInWith(SocialProvider.google),
          ),
          const SizedBox(height: 12),
          SocialSignInButton(
            provider: SocialProvider.apple,
            onPressed: () => _signInWith(SocialProvider.apple),
          ),
        ],
        actions: [
          PrimaryButton(label: 'Sign In', onPressed: _signIn),
          const SizedBox(height: 16),
          SecondaryButton(
            label: 'Create Account',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
