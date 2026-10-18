import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_colors.dart';

enum SocialProvider {
  google('Google', FontAwesomeIcons.google, Color(0xFF4285F4)),
  apple('Apple', FontAwesomeIcons.apple, Colors.black);

  const SocialProvider(this.label, this.icon, this.iconColor);

  final String label;
  final FaIconData icon;
  final Color iconColor;
}

/// White full-width "Sign in with Google / Apple" button.
class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  final SocialProvider provider;

  /// Null disables the button (another request is running).
  final VoidCallback? onPressed;

  /// Shows a spinner instead of the logo while this provider's window is open.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.inputBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : FaIcon(provider.icon, size: 20, color: provider.iconColor),
        label: Text('Sign in with ${provider.label}'),
      ),
    );
  }
}

/// "──── or ────" separator.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('or', style: TextStyle(color: AppColors.textSecondary)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}
