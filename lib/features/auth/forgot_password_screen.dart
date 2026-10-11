import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/custom_text_field.dart';
import 'widgets/auth_layout.dart';

/// Password recovery. Nothing is sent yet; a valid email shows a
/// confirmation and returns to the login screen.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  void _sendLink() {
    if (!_formKey.currentState!.validate()) return;
    showSuccessSnackBar(
      ScaffoldMessenger.of(context),
      'Reset link sent to your email',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AuthLayout(
        content: const [
          SizedBox(height: 24),
          AuthHeader(icon: Icons.lock_outline, title: 'Change Password'),
          SizedBox(height: 16),
          Text(
            'Enter the email address you used during registration. We will '
            'send you an email with a link to create a new password.',
            style: TextStyle(fontSize: 17, height: 1.3),
          ),
          SizedBox(height: 48),
          CustomTextField(
            label: 'Email Address',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
          ),
        ],
        actions: [
          PrimaryButton(label: 'Accept', onPressed: _sendLink),
          const SizedBox(height: 16),
          SecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
