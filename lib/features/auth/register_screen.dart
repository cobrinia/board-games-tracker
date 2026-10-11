import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/custom_text_field.dart';
import '../home/main_shell.dart';
import 'widgets/auth_layout.dart';

/// Registration form. A valid form opens the main app shell and clears
/// the auth screens from the navigation stack.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AuthLayout(
        content: [
          const SizedBox(height: 48),
          const AuthHeader(
            title: 'Registration',
            subtitle: 'Please enter your details.',
          ),
          const SizedBox(height: 64),
          const CustomTextField(
            label: 'Username',
            validator: Validators.required,
          ),
          const SizedBox(height: 16),
          const CustomTextField(
            label: 'Email Address',
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'New Password',
            controller: _passwordController,
            isPassword: true,
            validator: Validators.password,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Confirm New Password',
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: (value) => value == _passwordController.text
                ? null
                : 'Passwords do not match',
          ),
        ],
        actions: [
          PrimaryButton(label: 'Accept', onPressed: _register),
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
