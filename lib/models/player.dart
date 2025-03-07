import 'package:my_new_gorlf/models/game.dart';      // Import Game
import 'package:my_new_gorlf/models/game_player.dart'; // Import GamePlayer
import 'package:my_new_gorlf/models/course.dart';     // Import Course

class Player {
  final String id;           // Unique ID (e.g., Firestore doc ID or user UID)
  final String name;         // Player's display name
  final double? handicap;    // Persistent handicap (nullable)
  final List<GamePlayer>? gameHistory; // Optional: Links to game-specific data

  Player({
    required this.id,
    required this.name,
    this.handicap,
    this.gameHistory,
  });

  // Convert Player to a map for Firestore
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'handicap': handicap,
    'gameHistory': gameHistory?.map((g) => g.toMap()).toList(),
  };

  // Create Player from Firestore data
  factory Player.fromMap(Map<String, dynamic> map) => Player(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    handicap: (map['handicap'] as num?)?.toDouble(),
    gameHistory: (map['gameHistory'] as List<dynamic>?)
        ?.map((g) => GamePlayer.fromMap(g as Map<String, dynamic>))
        .toList(),
  );

  // Calculate handicap based on game history
  double calculateHandicap(List<Game> games, List<Course> courses) {
    if (games.isEmpty || courses.isEmpty) return handicap ?? 0.0;

    final playerGames = games.where((game) => game.players.containsKey(id)).toList();
    if (playerGames.isEmpty) return handicap ?? 0.0;

    final differentials = playerGames.map((game) {
      final playerData = game.players[id]; // Nullable GamePlayer
      if (playerData == null) return 0.0;  // Handle null player data

      final course = courses.firstWhere(
            (c) => c.id == game.courseId,
        orElse: () => Course(
          id: '',
          name: game.courseId,
          status: 'Unknown',
          slopeRating: 113,
          yardage: 0,
          totalPar: 72,
          holes: [], userId: '',
        ),
      );

      // Safely calculate differential
      final score = playerData.totalScore;
      final par = course.totalPar;
      final slope = course.slopeRating;
      return (score - par) * 113 / slope;
    }).toList()
      ..sort();

    final bestDifferentials = differentials.take(playerGames.length < 8 ? playerGames.length : 8).toList();
    if (bestDifferentials.isEmpty) return handicap ?? 0.0;

    // Safely calculate average with non-null values
    final avgDifferential = bestDifferentials.reduce((a, b) => a + b) / bestDifferentials.length;
    return (avgDifferential * 0.96).toDouble();
  }
}