import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/custom_text_field.dart';
import 'widgets/auth_layout.dart';

/// Password recovery: Firebase emails a link for setting a new password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  /// Email already typed on the login screen.
  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    FocusScope.of(context).unfocus();
    if (_loading || !_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final email = _emailController.text.trim();
    setState(() => _loading = true);
    try {
      await AppScope.of(context).auth.sendPasswordResetEmail(email);
      // Firebase does not reveal whether the email is registered (this
      // protects against guessing accounts), so the message is neutral.
      showSuccessSnackBar(
        messenger,
        'If an account exists for $email, a reset link is on its way.',
      );
      navigator.pop();
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
      child: AuthLayout(
        content: [
          const SizedBox(height: 24),
          const AuthHeader(icon: Icons.lock_outline, title: 'Change Password'),
          const SizedBox(height: 16),
          const Text(
            'Enter the email address you used during registration. We will '
            'send you an email with a link to create a new password.',
            style: TextStyle(fontSize: 17, height: 1.3),
          ),
          const SizedBox(height: 48),
          CustomTextField(
            label: 'Email Address',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            enabled: !_loading,
            validator: Validators.email,
            onFieldSubmitted: (_) => _sendLink(),
          ),
        ],
        actions: [
          PrimaryButton(
            label: 'Accept',
            isLoading: _loading,
            onPressed: _sendLink,
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
