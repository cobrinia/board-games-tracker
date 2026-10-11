import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/app_colors.dart';
import 'badges.dart';

/// Catalog grid tile: cover, title, category, players, play time, rating.
class GameCard extends StatelessWidget {
  const GameCard({super.key, required this.game, this.onTap});

  final BoardGame game;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const secondary = TextStyle(color: AppColors.textSecondary, fontSize: 12);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: ColoredBox(color: game.color)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(game.category, style: secondary),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.group_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${game.playersLabel} • ${game.playTimeMinutes}m',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: secondary,
                        ),
                      ),
                      if (game.rating > 0)
                        AppBadge(text: '★ ${game.rating.toStringAsFixed(1)}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
