import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Green confirmation toast ("Session saved · Undo", "Profile updated").
void showSuccessSnackBar(
  ScaffoldMessengerState messenger,
  String message, {
  VoidCallback? onUndo,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: AppColors.successLight,
        // Snack bars with an action stay open by default; let this one close.
        persist: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        action: onUndo == null
            ? null
            : SnackBarAction(
                label: 'Undo',
                textColor: AppColors.success,
                onPressed: onUndo,
              ),
      ),
    );
}

/// "Are you sure?" dialog with Cancel and a red confirm button.
/// Returns true when the user confirms.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
