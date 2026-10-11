import 'package:flutter/material.dart';

import '../../core/data/mock_data.dart';
import '../../core/data/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/circle_icon_button.dart';
import '../../core/widgets/stat_card.dart';
import '../sessions/log_session_screen.dart';
import 'add_game_sheet.dart';

/// Game page: cover header, description, your stats and recent sessions.
class GameDetailsScreen extends StatefulWidget {
  const GameDetailsScreen({super.key, required this.game});

  final BoardGame game;

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  late BoardGame _game = widget.game;
  bool _favorite = false;

  Future<void> _edit() async {
    final updated = await showAddGameSheet(context, initial: _game);
    if (updated != null) setState(() => _game = updated);
  }

  @override
  Widget build(BuildContext context) {
    const sectionTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _Header(
                  game: _game,
                  favorite: _favorite,
                  onFavorite: () => setState(() => _favorite = !_favorite),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ValueListenableBuilder<List<GameSession>>(
                    valueListenable: MockData.sessions,
                    builder: (context, allSessions, _) {
                      final sessions = allSessions
                          .where((s) => s.gameTitle == _game.title)
                          .toList();
                      final scores = sessions
                          .map((s) => s.score)
                          .whereType<int>()
                          .toList();
                      final avgScore = scores.isEmpty
                          ? '—'
                          : (scores.reduce((a, b) => a + b) / scores.length)
                                .round()
                                .toString();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _game.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('About the Game', style: sectionTitle),
                          const SizedBox(height: 8),
                          Text(
                            _game.description.isEmpty
                                ? 'No description yet.'
                                : _game.description,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text('Your Stats', style: sectionTitle),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  label: 'Times Played',
                                  value: '${sessions.length}',
                                  centered: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: StatCard(
                                  label: 'Avg. Score',
                                  value: avgScore,
                                  centered: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: StatCard(
                                  label: 'Last Played',
                                  value: sessions.isEmpty
                                      ? '—'
                                      : formatShortDate(
                                          sessions.first.playedAt,
                                        ),
                                  centered: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Recent Session Logs',
                            style: sectionTitle,
                          ),
                          const SizedBox(height: 8),
                          if (sessions.isEmpty)
                            const Text(
                              'This game has not been played yet.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          for (final session in sessions.take(3)) ...[
                            _SessionLogRow(session: session),
                            const SizedBox(height: 8),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: 'Log Session',
                    icon: Icons.add,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LogSessionScreen(initialGame: _game.title),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.inputBorder),
                      ),
                      onPressed: _edit,
                      child: const Text('Edit'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.game,
    required this.favorite,
    required this.onFavorite,
  });

  final BoardGame game;
  final bool favorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final translucent = Colors.black.withValues(alpha: 0.25);
    final description = MockData.categoryDescriptions[game.category];

    return Container(
      color: game.color,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 8,
        16,
        16,
      ),
      height: 260 + MediaQuery.paddingOf(context).top,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleIconButton(
                icon: Icons.arrow_back,
                tooltip: 'Back',
                backgroundColor: translucent,
                foregroundColor: Colors.white,
                bordered: false,
                onPressed: () => Navigator.pop(context),
              ),
              CircleIconButton(
                icon: favorite ? Icons.favorite : Icons.favorite_border,
                tooltip: favorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                backgroundColor: translucent,
                foregroundColor: Colors.white,
                bordered: false,
                onPressed: onFavorite,
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _HeaderTag(text: game.category, color: AppColors.primary),
              const SizedBox(width: 8),
              _HeaderTag(
                text: '${game.playersLabel} Players',
                color: Colors.white.withValues(alpha: 0.3),
              ),
              if (description != null)
                Tooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  showDuration: const Duration(seconds: 5),
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.tooltip,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  richMessage: TextSpan(
                    children: [
                      TextSpan(
                        text: '${game.category}\n',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: description),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.info_outline, color: Colors.white),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderTag extends StatelessWidget {
  const _HeaderTag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SessionLogRow extends StatelessWidget {
  const _SessionLogRow({required this.session});

  final GameSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: Text(formatDate(session.playedAt))),
          Text(
            'Winner: ${session.winner}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          Text(
            session.result,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
