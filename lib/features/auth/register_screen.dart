import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/custom_text_field.dart';
import 'widgets/auth_layout.dart';

/// Registration with name, email and password.
///
/// The form is validated locally first; only a valid form is sent to
/// Firebase. On success [AuthGate] closes this screen and opens the app.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (_loading || !_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final auth = AppScope.of(context).auth;
    setState(() => _loading = true);
    try {
      await auth.signUp(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      showSuccessSnackBar(
        messenger,
        'Account created! We sent a confirmation link to '
        '${_emailController.text.trim()}.',
      );
    } on AuthException catch (error) {
      showErrorSnackBar(messenger, error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      // Each field is checked as soon as the user leaves it.
      autovalidateMode: AutovalidateMode.onUnfocus,
      child: AuthLayout(
        content: [
          const SizedBox(height: 48),
          const AuthHeader(
            title: 'Registration',
            subtitle: 'Please enter your details.',
          ),
          const SizedBox(height: 64),
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  label: 'Username',
                  controller: _nameController,
                  hint: 'How other players will see you',
                  autofillHints: const [AutofillHints.name],
                  enabled: !_loading,
                  validator: Validators.name,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email Address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: !_loading,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'New Password',
                  controller: _passwordController,
                  hint: 'At least 8 characters, letters and numbers',
                  isPassword: true,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !_loading,
                  validator: Validators.newPassword,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Confirm New Password',
                  controller: _confirmController,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  enabled: !_loading,
                  validator: Validators.confirmPassword(
                    () => _passwordController.text,
                  ),
                  onFieldSubmitted: (_) => _register(),
                ),
              ],
            ),
          ),
        ],
        actions: [
          PrimaryButton(
            label: 'Accept',
            isLoading: _loading,
            onPressed: _register,
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            label: 'Cancel',
            onPressed: _loading ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
