import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';

/// Round avatar with the player's initials, or their photo when
/// [photoUrl] is set. If the photo fails to load, the initials stay visible.
/// [ring] adds the orange outline used for the current user.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.name,
    required this.color,
    this.size = 40,
    this.ring = false,
    this.photoUrl,
  });

  final String name;
  final String? photoUrl;
  final Color color;
  final double size;
  final bool ring;

  String get _initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .where((part) => part.isNotEmpty)
      .map((part) => part[0])
      .join()
      .toUpperCase();

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final hasPhoto = url != null && url.isNotEmpty;
    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      foregroundImage: hasPhoto ? NetworkImage(url) : null,
      onForegroundImageError: hasPhoto ? (_, _) {} : null,
      foregroundColor: Colors.white,
      child: Text(
        _initials,
        style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w700),
      ),
    );
    if (!ring) return avatar;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: avatar,
    );
  }
}

/// Overlapping row of small avatars with a "+N" bubble for the rest.
class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.names, this.maxVisible = 3});

  final List<String> names;
  final int maxVisible;

  static const double _size = 24;
  static const double _step = 16;

  @override
  Widget build(BuildContext context) {
    final visible = names.take(maxVisible).toList();
    final extra = names.length - visible.length;
    final count = visible.length + (extra > 0 ? 1 : 0);

    Widget bordered(Widget child) => Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
      child: child,
    );

    return SizedBox(
      width: _step * (count - 1) + _size + 3,
      height: _size + 3,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * _step,
              child: bordered(
                PlayerAvatar(
                  name: visible[i],
                  color:
                      MockData.playerByName(visible[i])?.color ??
                      AppColors.textSecondary,
                  size: _size,
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: visible.length * _step,
              child: bordered(
                CircleAvatar(
                  radius: _size / 2,
                  backgroundColor: AppColors.border,
                  child: Text(
                    '+$extra',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
