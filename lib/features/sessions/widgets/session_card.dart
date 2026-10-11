import 'package:flutter/material.dart';

import '../../../core/data/mock_data.dart';
import '../../../core/data/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/player_avatar.dart';

/// Session list item. The [detailed] variant (Session History) also shows
/// the time, the duration and who played.
class SessionCard extends StatelessWidget {
  const SessionCard({super.key, required this.session, this.detailed = false});

  final GameSession session;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    const secondary = TextStyle(color: AppColors.textSecondary, fontSize: 13);
    final coverColor =
        MockData.gameByTitle(session.gameTitle)?.color ?? AppColors.border;
    final subtitle = detailed
        ? '${formatDate(session.playedAt)} • ${formatTime(session.playedAt)}'
        : '${formatDate(session.playedAt)} • '
              '${session.playerNames.length} Players';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: coverColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.gameTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: secondary),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      AppBadge.winner(session.winner),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '(${session.result})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: secondary.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (detailed)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${session.durationMinutes}m',
                    style: secondary.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  AvatarStack(names: session.playerNames),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
