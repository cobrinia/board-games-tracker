import 'package:flutter/material.dart';

import '../../core/data/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/player_avatar.dart';
import '../../core/widgets/stat_card.dart';
import '../sessions/session_history_screen.dart';
import '../sessions/widgets/session_card.dart';

/// Dashboard: greeting, summary stats and the latest played sessions.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String _userName = MockData.userName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([MockData.games, MockData.sessions]),
          builder: (context, _) {
            final games = MockData.games.value;
            final sessions = MockData.sessions.value;
            final now = DateTime.now();
            final playedThisMonth = sessions
                .where(
                  (s) =>
                      s.playedAt.year == now.year &&
                      s.playedAt.month == now.month,
                )
                .length;
            final you = MockData.you;
            final wins = sessions
                .where((s) => s.winner == you.firstName)
                .length;
            final winRate = sessions.isEmpty
                ? 0
                : (wins * 100 / sessions.length).round();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            _userName,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PlayerAvatar(
                      name: you.name,
                      color: you.color,
                      size: 44,
                      ring: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Owned',
                        value: '${games.length}',
                        caption: 'Games',
                        valueColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        label: 'Played',
                        value: '$playedThisMonth',
                        caption: 'This Month',
                        valueColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        label: 'Win Rate',
                        value: '$winRate%',
                        caption: 'Overall',
                        valueColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: AppColors.success),
                    SizedBox(width: 8),
                    Text(
                      'Catalog synced 2m ago',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Recent Sessions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SessionHistoryScreen(),
                        ),
                      ),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (sessions.isEmpty)
                  const Text(
                    'No sessions yet. Tap + to log your first game.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                for (final session in sessions.take(3)) ...[
                  SessionCard(session: session),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
