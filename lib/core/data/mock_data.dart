import 'package:flutter/material.dart';

import 'models.dart';

/// In-memory app data used until the backend is connected.
/// Screens listen to the [ValueNotifier]s, so adding or deleting an item
/// on one screen updates every other screen automatically.
class MockData {
  MockData._();

  static const String userName = 'Alex Mercer';
  static const String userEmail = 'pavlo.kobrin.pz.2024@lpnu.ua';

  static const List<String> categories = [
    'Strategy',
    'Party',
    'Family',
    'Co-op',
  ];

  static const Map<String, String> categoryDescriptions = {
    'Strategy': 'Deep games where long-term planning beats luck.',
    'Party': 'Light, social games for bigger groups and lots of laughs.',
    'Family':
        'Games that are easy to teach, quick to play, and work well for '
        'mixed ages and casual groups.',
    'Co-op': 'Everyone plays together as a team against the game itself.',
  };

  /// Colors given to newly added games and players.
  static const List<Color> palette = [
    Color(0xFF4DB6AC),
    Color(0xFF7986CB),
    Color(0xFFFFB74D),
    Color(0xFFA1887F),
    Color(0xFF90A4AE),
  ];

  static final ValueNotifier<List<BoardGame>> games = ValueNotifier([
    const BoardGame(
      title: 'Scythe',
      category: 'Strategy',
      minPlayers: 1,
      maxPlayers: 5,
      playTimeMinutes: 115,
      rating: 8.4,
      color: Color(0xFFE8A0A0),
      description:
          'Set in an alternate-history 1920s period, Scythe is an '
          'engine-building game of farming, war, and economic expansion. '
          'Lead your faction to conquest!',
    ),
    const BoardGame(
      title: 'Catan',
      category: 'Family',
      minPlayers: 3,
      maxPlayers: 4,
      playTimeMinutes: 90,
      rating: 7.1,
      color: Color(0xFFC8F7CF),
      description:
          'Gather resources, build roads and settlements, and trade your way '
          'to becoming the dominant force on the island of Catan.',
    ),
    const BoardGame(
      title: 'Dixit',
      category: 'Party',
      minPlayers: 3,
      maxPlayers: 8,
      playTimeMinutes: 30,
      rating: 7.3,
      color: Color(0xFFB38DF5),
      description:
          'A storytelling game of dreamlike cards: give a clue that is not '
          'too obvious and not too obscure.',
    ),
    const BoardGame(
      title: 'Pandemic',
      category: 'Co-op',
      minPlayers: 2,
      maxPlayers: 4,
      playTimeMinutes: 45,
      rating: 7.6,
      color: Color(0xFFF27BE6),
      description:
          'Work together as a team of specialists to stop four deadly '
          'diseases from spreading across the world.',
    ),
    const BoardGame(
      title: 'Wingspan',
      category: 'Strategy',
      minPlayers: 1,
      maxPlayers: 5,
      playTimeMinutes: 75,
      rating: 8.1,
      color: Color(0xFFEC4BC8),
      description:
          'Attract a beautiful and diverse collection of birds to your '
          'wildlife preserve.',
    ),
    const BoardGame(
      title: 'Terraforming Mars',
      category: 'Strategy',
      minPlayers: 1,
      maxPlayers: 5,
      playTimeMinutes: 120,
      rating: 8.4,
      color: Color(0xFFE53935),
      description:
          'Lead a corporation competing to make Mars habitable for '
          'humanity in this engine-building classic.',
    ),
  ]);

  static final ValueNotifier<List<Player>> players = ValueNotifier(const [
    Player(
      name: 'John Doe',
      color: Color(0xFF5C6BC0),
      winRate: 0.72,
      gamesPlayed: 32,
    ),
    Player(
      name: 'Sarah Jenkins',
      color: Color(0xFF8D6E63),
      winRate: 0.64,
      gamesPlayed: 45,
      isFavorite: true,
    ),
    Player(
      name: 'Emma Wilson',
      color: Color(0xFF26A69A),
      winRate: 0.51,
      gamesPlayed: 28,
    ),
    Player(
      name: 'Mike Chen',
      color: Color(0xFF78909C),
      winRate: 0.38,
      gamesPlayed: 19,
    ),
    Player(
      name: userName,
      color: Color(0xFFFF8A50),
      winRate: 0.68,
      gamesPlayed: 47,
      isYou: true,
    ),
  ]);

  // Dates are relative to "now" so the This Week / This Month filters
  // always have something to show.
  static final ValueNotifier<List<GameSession>> sessions = ValueNotifier([
    _session(
      'Wingspan',
      1,
      14,
      30,
      75,
      ['Alex Mercer', 'Sarah Jenkins', 'John Doe', 'Emma Wilson'],
      'Alex',
      '82 pts',
    ),
    _session(
      'Terraforming Mars',
      5,
      20,
      0,
      120,
      ['Alex Mercer', 'Sarah Jenkins', 'John Doe'],
      'Sarah',
      '94 MC',
    ),
    _session(
      'Scythe',
      11,
      18,
      15,
      115,
      ['Alex Mercer', 'John Doe', 'Sarah Jenkins', 'Emma Wilson', 'Mike Chen'],
      'Alex',
      '89 pts',
    ),
    _session(
      'Pandemic',
      17,
      21,
      0,
      45,
      ['Alex Mercer', 'Sarah Jenkins', 'Emma Wilson', 'Mike Chen'],
      'Co-op Win',
      'Heroic',
    ),
    _session(
      'Catan',
      23,
      16,
      0,
      90,
      ['Alex Mercer', 'John Doe', 'Sarah Jenkins'],
      'John',
      '10 pts',
    ),
  ]);

  static GameSession _session(
    String game,
    int daysAgo,
    int hour,
    int minute,
    int duration,
    List<String> players,
    String winner,
    String result,
  ) {
    final day = DateTime.now().subtract(Duration(days: daysAgo));
    return GameSession(
      gameTitle: game,
      playedAt: DateTime(day.year, day.month, day.day, hour, minute),
      durationMinutes: duration,
      playerNames: players,
      winner: winner,
      result: result,
    );
  }

  // ---- Lookups ----

  static Player get you => players.value.firstWhere((p) => p.isYou);

  static BoardGame? gameByTitle(String title) {
    for (final game in games.value) {
      if (game.title == title) return game;
    }
    return null;
  }

  static Player? playerByName(String name) {
    for (final player in players.value) {
      if (player.name == name) return player;
    }
    return null;
  }

  // ---- Mutations ----

  static void addGame(BoardGame game) => games.value = [...games.value, game];

  static void replaceGame(BoardGame old, BoardGame updated) => games.value = [
    for (final g in games.value) identical(g, old) ? updated : g,
  ];

  static void addSession(GameSession session) =>
      sessions.value = [...sessions.value, session]
        ..sort((a, b) => b.playedAt.compareTo(a.playedAt));

  static void removeSession(GameSession session) => sessions.value = [
    for (final s in sessions.value)
      if (!identical(s, session)) s,
  ];

  static void addPlayer(Player player) =>
      players.value = [...players.value, player];

  /// Puts a player back at [index] (used by Undo after deleting).
  static void insertPlayer(int index, Player player) =>
      players.value = [...players.value]
        ..insert(index.clamp(0, players.value.length), player);

  static void removePlayer(Player player) => players.value = [
    for (final p in players.value)
      if (!identical(p, player)) p,
  ];

  static void replacePlayer(Player old, Player updated) => players.value = [
    for (final p in players.value) identical(p, old) ? updated : p,
  ];
}
