import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/app_bottom_nav.dart';
import '../catalog/add_game_sheet.dart';
import '../catalog/catalog_screen.dart';
import '../players/players_screen.dart';
import '../sessions/log_session_screen.dart';
import '../settings/settings_screen.dart';
import 'home_screen.dart';

enum _AddAction { logSession, addGame }

/// Root of the signed-in app.
///
/// Every tab has its own [Navigator], so screens opened from a tab (game
/// details, player profile...) keep the bottom bar visible, and each tab
/// remembers its own stack when you switch away and back.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _tabRoots = [
    HomeScreen(),
    CatalogScreen(),
    PlayersScreen(),
    SettingsScreen(),
  ];

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    _tabRoots.length,
    (_) => GlobalKey<NavigatorState>(),
  );

  NavigatorState get _currentNavigator =>
      _navigatorKeys[_currentIndex].currentState!;

  void _selectTab(int index) {
    if (index == _currentIndex) {
      // Tapping the active tab again returns to its first screen.
      _currentNavigator.popUntil((route) => route.isFirst);
    } else {
      setState(() => _currentIndex = index);
    }
  }

  Future<void> _openAddMenu() async {
    final action = await showModalBottomSheet<_AddAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Log Session'),
              onTap: () => Navigator.pop(context, _AddAction.logSession),
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Add New Game'),
              onTap: () => Navigator.pop(context, _AddAction.addGame),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _AddAction.logSession:
        _currentNavigator.push(
          MaterialPageRoute(builder: (_) => const LogSessionScreen()),
        );
      case _AddAction.addGame:
        showAddGameSheet(context);
    }
  }

  /// Android back button: pop inside the current tab first, then go to
  /// the Home tab, and only then leave the app.
  void _handleBack(bool didPop, Object? result) {
    if (didPop) return;
    if (_currentNavigator.canPop()) {
      _currentNavigator.pop();
    } else if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handleBack,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            for (var i = 0; i < _tabRoots.length; i++)
              Navigator(
                key: _navigatorKeys[i],
                onGenerateRoute: (_) =>
                    MaterialPageRoute(builder: (_) => _tabRoots[i]),
              ),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _currentIndex,
          onTabSelected: _selectTab,
          onAddPressed: _openAddMenu,
        ),
      ),
    );
  }
}
