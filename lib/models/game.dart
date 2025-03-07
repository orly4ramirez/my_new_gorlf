import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_player.dart';

class Game {
  final String id;
  final String date;
  final String title;
  final String courseId;
  final String? teamId;
  final String? tournamentId;
  final String gameType;
  final bool skinsMode;
  final int skinsBet;
  final Map<String, GamePlayer> players;
  final Map<String, dynamic>? teamStats;
  final bool useHandicap;

  Game({
    required this.id,
    required this.date,
    required this.title,
    required this.courseId,
    this.teamId,
    this.tournamentId,
    required this.gameType,
    required this.skinsMode,
    required this.skinsBet,
    required this.players,
    this.teamStats,
    required this.useHandicap,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date,
    'title': title,
    'courseId': courseId,
    'teamId': teamId,
    'tournamentId': tournamentId,
    'gameType': gameType,
    'skinsMode': skinsMode,
    'skinsBet': skinsBet,
    'players': players.map((k, v) => MapEntry(k, v.toMap())),
    'teamStats': teamStats,
    'useHandicap': useHandicap,
  };

  factory Game.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Game(
      id: data['id'] ?? doc.id,
      date: data['date'] ?? '',
      title: data['title'] ?? '',
      courseId: data['courseId'] ?? data['course'] ?? '',
      teamId: data['teamId'],
      tournamentId: data['tournamentId'],
      gameType: data['gameType'] ?? 'stroke_gross',
      skinsMode: data['skinsMode'] ?? false,
      skinsBet: data['skinsBet'] ?? 0,
      players: (data['players'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, GamePlayer.fromMap(v as Map<String, dynamic>)),
      ) ?? {},
      teamStats: data['teamStats'],
      useHandicap: data['useHandicap'] ?? true,
    );
  }
}