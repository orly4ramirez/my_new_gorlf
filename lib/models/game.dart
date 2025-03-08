import 'package:my_new_gorlf/models/game_player.dart';

class Game {
  final String id;
  final String date;
  final String title;
  final String courseId;
  final String gameType;
  final bool skinsMode;
  final int skinsBet;
  final Map<String, GamePlayer> players;
  final bool useHandicap;

  Game({
    required this.id,
    required this.date,
    required this.title,
    required this.courseId,
    required this.gameType,
    required this.skinsMode,
    required this.skinsBet,
    required this.players,
    required this.useHandicap,
  });

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] ?? '',
      date: map['date'] ?? '',
      title: map['title'] ?? '',
      courseId: map['courseId'] ?? '',
      gameType: map['gameType'] ?? 'stroke_gross',
      skinsMode: map['skinsMode'] ?? false,
      skinsBet: map['skinsBet'] ?? 0,
      players: (map['players'] as Map<String, dynamic>? ?? {}).map(
            (key, value) => MapEntry(key, GamePlayer.fromMap(value as Map<String, dynamic>)),
      ),
      useHandicap: map['useHandicap'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'courseId': courseId,
      'gameType': gameType,
      'skinsMode': skinsMode,
      'skinsBet': skinsBet,
      'players': players.map((key, value) => MapEntry(key, value.toMap())),
      'useHandicap': useHandicap,
    };
  }

  Game copyWith({
    String? id,
    String? date,
    String? title,
    String? courseId,
    String? gameType,
    bool? skinsMode,
    int? skinsBet,
    Map<String, GamePlayer>? players,
    bool? useHandicap,
  }) {
    return Game(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      courseId: courseId ?? this.courseId,
      gameType: gameType ?? this.gameType,
      skinsMode: skinsMode ?? this.skinsMode,
      skinsBet: skinsBet ?? this.skinsBet,
      players: players ?? Map.from(this.players),
      useHandicap: useHandicap ?? this.useHandicap,
    );
  }
}