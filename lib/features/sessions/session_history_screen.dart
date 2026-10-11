import 'package:flutter/material.dart';

import '../../core/data/mock_data.dart';
import '../../core/data/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_choice_chip.dart';
import '../../core/widgets/circle_icon_button.dart';
import 'widgets/session_card.dart';

/// All logged sessions with quick date filters. Swipe a card left to
/// delete it (with Undo).
class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  static const List<String> _filters = [
    'All',
    'This Week',
    'This Month',
    'By Game',
  ];
  String _filter = _filters.first;

  List<GameSession> _apply(List<GameSession> sessions) {
    final now = DateTime.now();
    return switch (_filter) {
      'This Week' =>
        sessions.where((s) => now.difference(s.playedAt).inDays < 7).toList(),
      'This Month' =>
        sessions
            .where(
              (s) =>
                  s.playedAt.year == now.year && s.playedAt.month == now.month,
            )
            .toList(),
      'By Game' => [
        ...sessions,
      ]..sort((a, b) => a.gameTitle.compareTo(b.gameTitle)),
      _ => sessions,
    };
  }

  void _delete(GameSession session) {
    MockData.removeSession(session);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Session deleted.'),
          persist: false,
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => MockData.addSession(session),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Session History',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => AppChoiceChip(
                  label: _filters[index],
                  selected: _filters[index] == _filter,
                  onSelected: () => setState(() => _filter = _filters[index]),
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<GameSession>>(
                valueListenable: MockData.sessions,
                builder: (context, sessions, _) {
                  final visible = _apply(sessions);
                  if (visible.isEmpty) {
                    return const Center(
                      child: Text(
                        'No sessions for this period',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final session = visible[index];
                      return Dismissible(
                        key: ObjectKey(session),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _delete(session),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                        child: SessionCard(session: session, detailed: true),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
