import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'player_avatar.dart';

enum PhotoSource { camera, gallery }

/// "Change profile photo" dialog: shows the current avatar and lets the
/// user choose where the new photo comes from. Returns the chosen source,
/// or null if cancelled.
///
/// Actually taking/picking the image needs the image_picker package,
/// which is not added yet.
Future<PhotoSource?> showChangePhotoDialog(
  BuildContext context, {
  required String name,
  required Color color,
}) {
  return showDialog<PhotoSource>(
    context: context,
    builder: (context) => _ChangePhotoDialog(name: name, color: color),
  );
}

class _ChangePhotoDialog extends StatefulWidget {
  const _ChangePhotoDialog({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  State<_ChangePhotoDialog> createState() => _ChangePhotoDialogState();
}

class _ChangePhotoDialogState extends State<_ChangePhotoDialog> {
  PhotoSource? _source;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change profile photo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerAvatar(
            name: widget.name,
            color: widget.color,
            size: 80,
            ring: true,
          ),
          const SizedBox(height: 24),
          // Same height for both tiles, even if one label wraps.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _SourceOption(
                    icon: Icons.photo_camera_outlined,
                    label: 'Take Photo',
                    selected: _source == PhotoSource.camera,
                    onTap: () => setState(() => _source = PhotoSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SourceOption(
                    icon: Icons.photo_library_outlined,
                    label: 'Choose from Gallery',
                    selected: _source == PhotoSource.gallery,
                    onTap: () => setState(() => _source = PhotoSource.gallery),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          // Disabled until a source is chosen.
          onPressed: _source == null
              ? null
              : () => Navigator.pop(context, _source),
          child: const Text('Accept'),
        ),
      ],
    );
  }
}

/// Square tile with an icon and caption; orange outline when selected.
class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.text;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primaryLight : AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                Icon(icon, size: 36, color: color),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
