import 'package:flutter/material.dart';

class BoardGame {
  const BoardGame({
    required this.title,
    required this.category,
    required this.minPlayers,
    required this.maxPlayers,
    required this.playTimeMinutes,
    required this.rating,
    required this.color,
    this.description = '',
  });

  final String title;
  final String category;
  final int minPlayers;
  final int maxPlayers;
  final int playTimeMinutes;

  /// BoardGameGeek-style rating on a 0–10 scale; 0 means "not rated".
  final double rating;

  /// Placeholder cover color until real cover images are available.
  final Color color;
  final String description;

  String get playersLabel =>
      minPlayers == maxPlayers ? '$minPlayers' : '$minPlayers-$maxPlayers';
}

class Player {
  const Player({
    required this.name,
    required this.color,
    required this.winRate,
    required this.gamesPlayed,
    this.isFavorite = false,
    this.isYou = false,
  });

  final String name;
  final Color color;

  /// Share of games won, 0.0–1.0.
  final double winRate;
  final int gamesPlayed;
  final bool isFavorite;

  /// The signed-in user.
  final bool isYou;

  String get firstName => name.split(' ').first;
  String get displayName => isYou ? '$name (You)' : name;

  Player copyWith({bool? isFavorite}) => Player(
    name: name,
    color: color,
    winRate: winRate,
    gamesPlayed: gamesPlayed,
    isFavorite: isFavorite ?? this.isFavorite,
    isYou: isYou,
  );
}

class GameSession {
  const GameSession({
    required this.gameTitle,
    required this.playedAt,
    required this.durationMinutes,
    required this.playerNames,
    required this.winner,
    required this.result,
  });

  final String gameTitle;
  final DateTime playedAt;
  final int durationMinutes;
  final List<String> playerNames;

  /// Winner's first name, or a label such as "Co-op Win".
  final String winner;

  /// Winning result, e.g. "82 pts" or "Heroic".
  final String result;

  /// Numeric score parsed from [result], if it starts with a number.
  int? get score => int.tryParse(result.split(' ').first);
}
