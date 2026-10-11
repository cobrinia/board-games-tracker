import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// White card with a small label, a big value and an optional caption
/// (e.g. "Owned / 47 / Games").
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.valueColor = AppColors.text,
    this.centered = false,
  });

  final String label;
  final String value;
  final String? caption;
  final Color valueColor;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    const secondary = TextStyle(color: AppColors.textSecondary, fontSize: 12);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: centered
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(label, style: secondary.copyWith(fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (caption != null) Text(caption!, style: secondary),
          ],
        ),
      ),
    );
  }
}
