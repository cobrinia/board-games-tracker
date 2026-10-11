import 'package:flutter/material.dart';

import '../../core/data/mock_data.dart';
import '../../core/data/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_choice_chip.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/circle_icon_button.dart';
import '../../core/widgets/game_card.dart';
import 'filters_screen.dart';
import 'game_details_screen.dart';

/// Game library: search, category chips, advanced filters and a 2-column grid.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const List<String> _chips = ['All', ...MockData.categories];

  final _searchController = TextEditingController();
  String _category = 'All';
  CatalogFilters _filters = const CatalogFilters();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BoardGame> _visible(List<BoardGame> games) {
    final query = _searchController.text.trim().toLowerCase();
    return games.where((game) {
      if (query.isNotEmpty && !game.title.toLowerCase().contains(query)) {
        return false;
      }
      if (_category != 'All' && game.category != _category) return false;
      return _filters.matches(game);
    }).toList();
  }

  Future<void> _openFilters() async {
    // Root navigator: the filters screen covers the bottom bar.
    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<CatalogFilters>(
        fullscreenDialog: true,
        builder: (_) => FiltersScreen(
          initial: _filters,
          initialQuery: _searchController.text,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      _filters = result;
      _searchController.text = result.query;
    });
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
                  Expanded(
                    child: AppSearchField(
                      controller: _searchController,
                      hint: 'Search game library...',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Badge(
                    isLabelVisible: _filters.isActive,
                    backgroundColor: AppColors.primary,
                    smallSize: 10,
                    child: CircleIconButton(
                      icon: Icons.tune,
                      tooltip: 'Filters',
                      onPressed: _openFilters,
                    ),
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
                itemCount: _chips.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => AppChoiceChip(
                  label: _chips[index],
                  selected: _chips[index] == _category,
                  onSelected: () => setState(() => _category = _chips[index]),
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<BoardGame>>(
                valueListenable: MockData.games,
                builder: (context, games, _) {
                  final visible = _visible(games);
                  if (visible.isEmpty) {
                    return const Center(
                      child: Text(
                        'No games match your search',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.78,
                        ),
                    itemCount: visible.length,
                    itemBuilder: (context, index) => GameCard(
                      game: visible[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GameDetailsScreen(game: visible[index]),
                        ),
                      ),
                    ),
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
