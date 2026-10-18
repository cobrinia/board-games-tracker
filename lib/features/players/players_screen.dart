import 'package:flutter/material.dart';

import '../../core/data/mock_data.dart';
import '../../core/data/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/circle_icon_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/player_avatar.dart';
import 'player_profile_screen.dart';

/// List of people you play with. Tap for the profile, star to favorite,
/// trash icon or swipe left to delete.
class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  String _query = '';

  Future<bool> _confirmDelete(Player player) => showConfirmDialog(
    context,
    title: 'Delete Player?',
    message:
        'Are you sure you want to remove ${player.name}? This will not '
        'delete past session logs but they will appear as anonymous.',
    confirmLabel: 'Delete',
  );

  /// Removes the player and offers Undo, which puts them back in place.
  void _delete(Player player) {
    final index = MockData.players.value.indexOf(player);
    MockData.removePlayer(player);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${player.name} removed.'),
          persist: false,
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => MockData.insertPlayer(index, player),
          ),
        ),
      );
  }

  Future<void> _deleteWithConfirm(Player player) async {
    if (await _confirmDelete(player)) _delete(player);
  }

  Future<void> _addPlayer() async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Player'),
        content: Form(
          key: formKey,
          child: CustomTextField(
            label: 'Name',
            controller: controller,
            hint: 'e.g. Jane Smith',
            textInputAction: TextInputAction.done,
            validator: (value) {
              final error = Validators.name(
                value,
                emptyMessage: 'Please enter a name',
              );
              if (error != null) return error;
              final taken = MockData.players.value.any(
                (p) => p.name.toLowerCase() == value!.trim().toLowerCase(),
              );
              return taken ? 'This player is already in the list' : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    // Dispose after the dialog's closing animation has finished.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (name == null) return;

    final count = MockData.players.value.length;
    MockData.addPlayer(
      Player(
        name: name,
        color: MockData.palette[count % MockData.palette.length],
        winRate: 0,
        gamesPlayed: 0,
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
                  const SizedBox(width: 48),
                  const Expanded(
                    child: Text(
                      'Players',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.person_add_alt_1_outlined,
                    tooltip: 'Add player',
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    bordered: false,
                    onPressed: _addPlayer,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AppSearchField(
                hint: 'Search players...',
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<Player>>(
                valueListenable: MockData.players,
                builder: (context, players, _) {
                  final query = _query.trim().toLowerCase();
                  final visible = players
                      .where((p) => p.name.toLowerCase().contains(query))
                      .toList();
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final player = visible[index];
                      final tile = _PlayerTile(
                        player: player,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            settings: const RouteSettings(
                              name: 'player_profile',
                            ),
                            builder: (_) => PlayerProfileScreen(player: player),
                          ),
                        ),
                        // You cannot delete yourself.
                        onDelete: player.isYou
                            ? null
                            : () => _deleteWithConfirm(player),
                        onFavorite: () => MockData.replacePlayer(
                          player,
                          player.copyWith(isFavorite: !player.isFavorite),
                        ),
                      );
                      if (player.isYou) return tile;

                      return Dismissible(
                        key: ObjectKey(player),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDelete(player),
                        onDismissed: (_) => _delete(player),
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
                        child: tile,
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

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.player,
    required this.onTap,
    required this.onFavorite,
    this.onDelete,
  });

  final Player player;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  /// Null hides the delete button (for the current user).
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    const secondary = TextStyle(color: AppColors.textSecondary, fontSize: 12);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
          child: Row(
            children: [
              PlayerAvatar(name: player.name, color: player.color, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            player.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: player.isFavorite
                              ? 'Remove from favorites'
                              : 'Add to favorites',
                          onPressed: onFavorite,
                          icon: Icon(
                            player.isFavorite ? Icons.star : Icons.star_border,
                            color: AppColors.primary,
                          ),
                        ),
                        if (onDelete != null)
                          IconButton(
                            tooltip: 'Delete player',
                            onPressed: onDelete,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.danger,
                            ),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Wins: ${(player.winRate * 100).round()}%',
                                style: secondary.copyWith(
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${player.gamesPlayed} games played',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: player.winRate,
                              minHeight: 6,
                              color: AppColors.primary,
                              backgroundColor: AppColors.border,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
