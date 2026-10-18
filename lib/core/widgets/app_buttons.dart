import 'package:flutter/material.dart';

/// Full-width filled (orange) pill button for the main action on a screen.
///
/// While [isLoading] is true the label is replaced by a spinner and the
/// button is disabled, so a request cannot be sent twice.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final onTap = isLoading ? null : onPressed;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: isLoading
          ? FilledButton(
              onPressed: null,
              child: Semantics(
                label: '$label, loading',
                child: const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          : icon == null
          ? FilledButton(onPressed: onTap, child: Text(label))
          : FilledButton.icon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(label),
            ),
    );
  }
}

/// Full-width outlined (orange border) pill button for secondary actions.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: icon == null
          ? OutlinedButton(onPressed: onPressed, child: Text(label))
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            ),
    );
  }
}
