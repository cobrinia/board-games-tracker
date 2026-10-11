import 'package:flutter/material.dart';

import '../../core/data/mock_data.dart';
import '../../core/data/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/player_avatar.dart';

/// One player row in the session: the player and their score input.
class _ScoreEntry {
  _ScoreEntry(this.player);

  final Player player;
  final TextEditingController controller = TextEditingController();

  int? get score => int.tryParse(controller.text);
}

/// Form for recording a played game. The winner is the player with the
/// highest score and is highlighted as scores are typed.
class LogSessionScreen extends StatefulWidget {
  const LogSessionScreen({super.key, this.initialGame});

  /// Pre-selected game title (when opened from Game Details).
  final String? initialGame;

  @override
  State<LogSessionScreen> createState() => _LogSessionScreenState();
}

class _LogSessionScreenState extends State<LogSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  final _notesController = TextEditingController();
  late final List<_ScoreEntry> _entries;
  String? _game;
  DateTime _date = DateTime.now();

  /// Set after the first Save tap, so empty scores are only shown as errors
  /// once the user has tried to save.
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final games = MockData.games.value;
    _game = widget.initialGame ?? (games.isEmpty ? null : games.first.title);
    _dateController.text = formatDate(_date);

    // Start with you plus the first two other players.
    final players = MockData.players.value;
    _entries = [
      for (final p in players.where((p) => p.isYou)) _ScoreEntry(p),
      for (final p in players.where((p) => !p.isYou).take(2)) _ScoreEntry(p),
    ];
  }

  @override
  void dispose() {
    _dateController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    for (final entry in _entries) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  _ScoreEntry? get _winner {
    _ScoreEntry? best;
    for (final entry in _entries) {
      final score = entry.score;
      if (score != null && (best == null || score > best.score!)) best = entry;
    }
    return best;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _dateController.text = formatDate(picked);
    });
  }

  Future<void> _addPlayer() async {
    final added = _entries.map((e) => e.player.name).toSet();
    final available = MockData.players.value
        .where((p) => !added.contains(p.name))
        .toList();

    final player = await showModalBottomSheet<Player>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: available.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('All players are already in this session.'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final p in available)
                    ListTile(
                      leading: PlayerAvatar(name: p.name, color: p.color),
                      title: Text(p.name),
                      onTap: () => Navigator.pop(context, p),
                    ),
                ],
              ),
      ),
    );
    if (player != null) setState(() => _entries.add(_ScoreEntry(player)));
  }

  /// [quick] logs the session without scores (Quick Log).
  void _save({bool quick = false}) {
    setState(() => _submitted = !quick);
    final formValid = _formKey.currentState!.validate();
    final scoresValid = quick || _entries.every((e) => e.score != null);
    if (!formValid || !scoresValid || _entries.isEmpty) return;

    final winner = quick ? null : _winner;
    final now = DateTime.now();
    final session = GameSession(
      gameTitle: _game!,
      playedAt: DateTime(
        _date.year,
        _date.month,
        _date.day,
        now.hour,
        now.minute,
      ),
      durationMinutes: int.tryParse(_durationController.text) ?? 0,
      playerNames: [for (final e in _entries) e.player.name],
      winner: winner?.player.firstName ?? 'Not recorded',
      result: winner == null ? 'Quick log' : '${winner.score} pts',
    );
    MockData.addSession(session);

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    showSuccessSnackBar(
      messenger,
      'Session saved',
      onUndo: () => MockData.removeSession(session),
    );
  }

  @override
  Widget build(BuildContext context) {
    final winner = _winner;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Log Session'),
        actions: [
          TextButton(
            onPressed: () => _save(quick: true),
            child: const Text('Quick Log'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _game,
                    decoration: const InputDecoration(
                      labelText: 'Select Board Game',
                    ),
                    items: [
                      for (final game in MockData.games.value)
                        DropdownMenuItem(
                          value: game.title,
                          child: Text(game.title),
                        ),
                    ],
                    validator: (value) =>
                        value == null ? 'Choose a game' : null,
                    onChanged: (value) => setState(() => _game = value),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Date Played',
                          controller: _dateController,
                          readOnly: true,
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          label: 'Duration',
                          controller: _durationController,
                          suffixText: 'mins',
                          keyboardType: TextInputType.number,
                          validator: Validators.positiveInt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Players & Scores',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  for (final entry in _entries) ...[
                    _ScoreRow(
                      entry: entry,
                      isWinner: identical(entry, winner),
                      showError: _submitted && entry.score == null,
                      onChanged: () => setState(() {}),
                      onRemove: entry.player.isYou
                          ? null
                          : () {
                              setState(() => _entries.remove(entry));
                              // The row's TextField still uses the controller
                              // until this frame is rebuilt.
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => entry.controller.dispose(),
                              );
                            },
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _addPlayer,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Player to Session'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Session Notes',
                    controller: _notesController,
                    hint: 'E.g. Great close game! Late military expansion...',
                    maxLines: 2,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PrimaryButton(
                  label: 'Save Session Log',
                  icon: Icons.check,
                  onPressed: _save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.entry,
    required this.isWinner,
    required this.showError,
    required this.onChanged,
    this.onRemove,
  });

  final _ScoreEntry entry;
  final bool isWinner;
  final bool showError;
  final VoidCallback onChanged;

  /// Null for the current user, who cannot be removed.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final borderColor = showError ? AppColors.danger : AppColors.border;
    final scoreBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(
        color: showError ? AppColors.danger : AppColors.inputBorder,
      ),
    );

    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          PlayerAvatar(name: entry.player.name, color: entry.player.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.player.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (isWinner)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: AppWinnerBadge(),
            ),
          SizedBox(
            width: 64,
            child: TextField(
              controller: entry.controller,
              onChanged: (_) => onChanged(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: '-',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: scoreBorder,
                enabledBorder: scoreBorder,
                focusedBorder: scoreBorder.copyWith(
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Swipe a player away to remove them from the session.
        if (onRemove == null)
          row
        else
          Dismissible(
            key: ObjectKey(entry),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => onRemove!(),
            child: row,
          ),
        if (showError)
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Score is required to compute winner',
              style: TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

/// Yellow "🏆 WINNER" tag.
class AppWinnerBadge extends StatelessWidget {
  const AppWinnerBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.winnerBadge,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        '🏆 WINNER',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}
