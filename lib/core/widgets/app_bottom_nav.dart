import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Bottom bar from the design: four tabs with a raised orange "+" button
/// in the middle.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddPressed,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;

  static const List<(IconData, IconData, String)> _tabs = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.menu_book_outlined, Icons.menu_book, 'Catalog'),
    (Icons.people_outline, Icons.people, 'Players'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    Widget tab(int index) {
      final (icon, selectedIcon, label) = _tabs[index];
      final selected = index == currentIndex;
      final color = selected ? AppColors.primary : AppColors.text;

      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          child: InkWell(
            onTap: () => onTabSelected(index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryLight : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(selected ? selectedIcon : icon, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              tab(0),
              tab(1),
              Expanded(
                child: Center(
                  child: Tooltip(
                    message: 'Add',
                    child: Material(
                      color: AppColors.primary,
                      elevation: 4,
                      shadowColor: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: onAddPressed,
                        child: const SizedBox.square(
                          dimension: 56,
                          child: Icon(Icons.add, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              tab(2),
              tab(3),
            ],
          ),
        ),
      ),
    );
  }
}
