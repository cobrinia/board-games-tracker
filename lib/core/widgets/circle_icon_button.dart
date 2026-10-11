import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Round 48dp icon button (back, close, filters, favorite...).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.backgroundColor = AppColors.surface,
    this.foregroundColor = AppColors.text,
    this.bordered = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        fixedSize: const Size.square(48),
        side: bordered ? const BorderSide(color: AppColors.border) : null,
      ),
    );
  }
}
