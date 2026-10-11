import 'package:flutter/material.dart';

import '../../core/data/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_choice_chip.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/circle_icon_button.dart';

enum PlayTimeRange {
  under30('< 30min', 0, 29),
  from30to60('30-60min', 30, 60),
  from60to90('60-90min', 61, 90),
  over90('90+min', 91, 1 << 30);

  const PlayTimeRange(this.label, this.min, this.max);

  final String label;
  final int min;
  final int max;

  bool contains(int minutes) => minutes >= min && minutes <= max;
}

/// Advanced catalog filters returned by [FiltersScreen].
class CatalogFilters {
  const CatalogFilters({
    this.query = '',
    this.playerCount,
    this.playTime,
    this.categories = const {},
    this.minStars = 0,
  });

  final String query;

  /// Null means "any number of players".
  final int? playerCount;
  final PlayTimeRange? playTime;
  final Set<String> categories;

  /// 0–5 stars; game ratings are on a 0–10 scale, so 1 star = 2 points.
  final int minStars;

  bool get isActive =>
      playerCount != null ||
      playTime != null ||
      categories.isNotEmpty ||
      minStars > 0;

  bool matches(BoardGame game) {
    final players = playerCount;
    if (players != null &&
        (players < game.minPlayers || players > game.maxPlayers)) {
      return false;
    }
    if (playTime != null && !playTime!.contains(game.playTimeMinutes)) {
      return false;
    }
    if (categories.isNotEmpty && !categories.contains(game.category)) {
      return false;
    }
    return game.rating / 2 >= minStars;
  }
}

/// Full-screen search + filters. Pops with a [CatalogFilters] on Apply.
class FiltersScreen extends StatefulWidget {
  const FiltersScreen({
    super.key,
    required this.initial,
    required this.initialQuery,
  });

  final CatalogFilters initial;
  final String initialQuery;

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  static const List<String> _recentSearches = [
    'Scythe',
    'Terraforming Mars',
    'Pandemic',
  ];
  static const List<String> _categoryOptions = [
    'Strategy',
    'Party',
    'Family',
    'Co-op',
    'Card',
    'Dice',
  ];

  late final TextEditingController _searchController;
  late int _players; // 0 = any
  PlayTimeRange? _playTime;
  late Set<String> _categories;
  late int _minStars;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _players = widget.initial.playerCount ?? 0;
    _playTime = widget.initial.playTime;
    _categories = {...widget.initial.categories};
    _minStars = widget.initial.minStars;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAll() => setState(() {
    _searchController.clear();
    _players = 0;
    _playTime = null;
    _categories = {};
    _minStars = 0;
  });

  void _apply() => Navigator.pop(
    context,
    CatalogFilters(
      query: _searchController.text,
      playerCount: _players == 0 ? null : _players,
      playTime: _playTime,
      categories: _categories,
      minStars: _minStars,
    ),
  );

  @override
  Widget build(BuildContext context) {
    const sectionTitle = TextStyle(fontWeight: FontWeight.w700, fontSize: 15);
    const caption = TextStyle(color: AppColors.textSecondary, fontSize: 12);
    final playersLabel = switch (_players) {
      0 => 'Any',
      1 => '1 Player',
      8 => '8+ Players',
      _ => '$_players Players',
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppSearchField(
                    controller: _searchController,
                    hint: 'Search game library...',
                    autofocus: widget.initialQuery.isEmpty,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CircleIconButton(
                      icon: Icons.close,
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Recent Searches', style: sectionTitle),
                  for (final search in _recentSearches)
                    InkWell(
                      onTap: () =>
                          setState(() => _searchController.text = search),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(32, 14, 16, 14),
                        child: Text(
                          search,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Player Count', style: sectionTitle),
                      ),
                      Text(
                        playersLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _players.toDouble(),
                    max: 8,
                    divisions: 8,
                    label: playersLabel,
                    onChanged: (value) =>
                        setState(() => _players = value.round()),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Any', style: caption),
                        Text('4', style: caption),
                        Text('8+', style: caption),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Play Time', style: sectionTitle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final range in PlayTimeRange.values)
                        AppChoiceChip(
                          label: range.label,
                          selected: _playTime == range,
                          onSelected: () => setState(
                            () => _playTime = _playTime == range ? null : range,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Category', style: sectionTitle),
                  Wrap(
                    children: [
                      for (final category in _categoryOptions)
                        InkWell(
                          onTap: () => setState(() {
                            if (!_categories.remove(category)) {
                              _categories.add(category);
                            }
                          }),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _categories.contains(category),
                                onChanged: (checked) => setState(() {
                                  checked == true
                                      ? _categories.add(category)
                                      : _categories.remove(category);
                                }),
                              ),
                              Text(category),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Rating', style: sectionTitle),
                  Row(
                    children: [
                      for (var star = 1; star <= 5; star++)
                        IconButton(
                          tooltip: '$star+ stars',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(
                            () => _minStars = _minStars == star ? 0 : star,
                          ),
                          icon: Icon(
                            star <= _minStars ? Icons.star : Icons.star_border,
                            color: star <= _minStars
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _minStars == 0 ? 'Any rating' : '$_minStars.0+ Stars',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  PrimaryButton(label: 'Apply Filters', onPressed: _apply),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    onPressed: _clearAll,
                    child: const Text('Clear All'),
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
