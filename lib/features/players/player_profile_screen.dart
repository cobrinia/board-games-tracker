import 'package:flutter/material.dart';

import '../../core/data/mock_data.dart';
import '../../core/data/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/change_photo_dialog.dart';
import '../../core/widgets/circle_icon_button.dart';
import '../../core/widgets/player_avatar.dart';
import '../../core/widgets/stat_card.dart';
import '../sessions/session_history_screen.dart';

/// Stats, recent activity and achievements of one player.
class PlayerProfileScreen extends StatelessWidget {
  const PlayerProfileScreen({super.key, required this.player});

  final Player player;

  Future<void> _editProfile(BuildContext context) async {
    final source = await showChangePhotoDialog(
      context,
      name: player.name,
      color: player.color,
    );
    if (source != null && context.mounted) {
      showSuccessSnackBar(ScaffoldMessenger.of(context), 'Profile updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    const sectionTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

    final sessions = MockData.sessions.value
        .where((s) => s.playerNames.contains(player.name))
        .toList();
    final wins = (player.winRate * player.gamesPlayed).round();

    // Most played game in this player's sessions.
    final counts = <String, int>{};
    for (final s in sessions) {
      counts[s.gameTitle] = (counts[s.gameTitle] ?? 0) + 1;
    }
    final favoriteGame = counts.isEmpty
        ? '—'
        : (counts.entries.toList()..sort((a, b) => b.value - a.value))
              .first
              .key;

    // Consecutive wins counting back from the latest session.
    var streak = 0;
    for (final s in sessions) {
      if (s.winner != player.firstName) break;
      streak++;
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                CircleIconButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Back',
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Player Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: PlayerAvatar(
                name: player.name,
                color: player.color,
                size: 96,
                ring: true,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              player.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            Text(
              'Member since ${formatMonthYear(DateTime(2026))}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Games Played',
                    value: '${player.gamesPlayed}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Win Rate',
                    value: '${(player.winRate * 100).round()}%',
                    valueColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Wins / Losses',
                    value: '$wins / ${player.gamesPlayed - wins}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: StatCard(label: 'Favorite Game', value: favoriteGame),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Active Streak',
                    value: '$streak Wins',
                    valueColor: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text('Recent Activity', style: sectionTitle),
                ),
                IconButton(
                  tooltip: 'All sessions',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SessionHistoryScreen(),
                    ),
                  ),
                ),
              ],
            ),
            if (sessions.isEmpty)
              const Text(
                'No games played yet.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              Card(
                child: ListTile(
                  title: Text(
                    sessions.first.gameTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${formatDate(sessions.first.playedAt)} • Winner: '
                    '${sessions.first.winner} (${sessions.first.result})',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: sessions.first.winner == player.firstName
                      ? const AppBadge.success('Won')
                      : const AppBadge(
                          text: 'Lost',
                          color: AppColors.textSecondary,
                          background: AppColors.background,
                        ),
                ),
              ),
            const SizedBox(height: 24),
            const Text('Achievements', style: sectionTitle),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _Achievement(
                    emoji: '🏆',
                    title: 'First Win',
                    subtitle: 'Won a match',
                    unlocked: wins > 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Achievement(
                    emoji: '🎲',
                    title: '10 Games',
                    subtitle: 'Played 10 times',
                    unlocked: player.gamesPlayed >= 10,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Achievement(
                    emoji: '🔥',
                    title: 'Streak Master',
                    subtitle: '5 game win streak',
                    unlocked: streak >= 5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SecondaryButton(
              label: 'Edit Profile',
              onPressed: () => _editProfile(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _Achievement extends StatelessWidget {
  const _Achievement({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.unlocked,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    // Locked achievements are shown faded.
    return Opacity(
      opacity: unlocked ? 1 : 0.4,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
