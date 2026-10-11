import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Small rounded label, e.g. "Winner: Alex", "★ 8.4", "Synced".
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.text,
    this.color = AppColors.primary,
    this.background = AppColors.primaryLight,
  });

  /// Light-orange "Winner: X" chip.
  const AppBadge.winner(String name, {super.key})
    : text = 'Winner: $name',
      color = AppColors.primary,
      background = AppColors.primaryLight;

  /// Light-green chip ("Won", "Synced").
  const AppBadge.success(this.text, {super.key})
    : color = AppColors.success,
      background = AppColors.successLight;

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
