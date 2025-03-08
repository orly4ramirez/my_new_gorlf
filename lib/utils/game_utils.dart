import 'package:firebase_auth/firebase_auth.dart';
import '../models/game.dart';
import '../models/game_player.dart';
import '../models/score.dart';
import '../models/course.dart';

double calculateHandicap(List<Game> games) {
  if (games.isEmpty) return 0.0;
  final playerId = FirebaseAuth.instance.currentUser!.uid;
  final differentials = games.where((game) => game.players.containsKey(playerId)).map((game) {
    final score = game.players[playerId]!.totalScore;
    final course = Course(
      id: '',
      name: game.courseId,
      status: 'Unknown',
      slopeRating: 113,
      yardage: 0,
      totalPar: 72,
      holes: [],
      userId: '',
    );
    return (score - course.totalPar) * 113 / course.slopeRating;
  }).toList()..sort();
  final bestDifferentials = differentials.take(games.length < 8 ? games.length : 8).toList();
  return bestDifferentials.isEmpty ? 0.0 : (bestDifferentials.reduce((a, b) => a + b) / bestDifferentials.length * 0.96);
}

double calculateAvgScore(List<Game> games) {
  if (games.isEmpty) return 0.0;
  final playerId = FirebaseAuth.instance.currentUser!.uid;
  final validGames = games.where((game) => game.players.containsKey(playerId)).toList();
  if (validGames.isEmpty) return 0.0;
  return validGames.fold<int>(0, (sum, game) => sum + game.players[playerId]!.totalScore) / validGames.length;
}

double calculateGirPercentage(List<Game> games) {
  if (games.isEmpty) return 0.0;
  final playerId = FirebaseAuth.instance.currentUser!.uid;
  final validGames = games.where((game) => game.players.containsKey(playerId)).toList();
  if (validGames.isEmpty) return 0.0;
  final totalGir = validGames.fold<int>(0, (sum, game) => sum + game.players[playerId]!.scores.where((s) => s.gir ?? false).length);
  final totalHoles = validGames.fold<int>(0, (sum, game) => sum + game.players[playerId]!.scores.length);
  return totalHoles > 0 ? (totalGir / totalHoles) * 100 : 0.0;
}

double calculateAvgPutts(List<Score> scores) {
  if (scores.isEmpty) return 0.0;
  return scores.fold<int>(0, (sum, score) => sum + (score.putts ?? 0)) / scores.length;
}

Map<String, dynamic> calculateTeamTotals(Map<String, GamePlayer> players) {
  return {'totalScore': players.values.fold<int>(0, (sum, player) => sum + player.totalScore)};
}

Map<String, dynamic> calculateTeamAvgStats(Map<String, GamePlayer> players, List<Hole> courseHoles) {
  if (players.isEmpty) return {'stablefordPoints': 0, 'girPercentage': 0.0, 'avgPutts': 0.0};
  final totalHoles = players.values.fold<int>(0, (sum, p) => sum + p.scores.length);
  final girCount = players.values.fold<int>(0, (sum, p) => sum + p.scores.where((s) => s.gir ?? false).length);
  final avgPutts = players.values.fold<double>(0, (sum, p) => sum + calculateAvgPutts(p.scores)) / players.length;
  final stablefordPoints = players.values.fold<int>(0, (sum, p) {
    return sum + p.scores.fold<int>(0, (s, score) {
      final par = courseHoles.firstWhere((h) => h.holeNumber == score.holeNumber).par;
      final diff = par - (score.scoreValue ?? par) + 2;
      return s + (diff > 0 ? diff : 0);
    });
  }) ~/ players.length;
  return {
    'stablefordPoints': stablefordPoints,
    'girPercentage': totalHoles > 0 ? (girCount / totalHoles) * 100 : 0.0,
    'avgPutts': avgPutts,
  };
}

Map<String, dynamic> calculatePlayerStats(GamePlayer player, List<Hole> courseHoles) {
  final holesPlayed = player.scores.length;
  final totalScore = player.scores.fold<int>(0, (sum, score) => sum + (score.scoreValue ?? 0));
  final girCount = player.scores.where((score) => score.gir ?? false).length;
  final girPercentage = holesPlayed > 0 ? (girCount / holesPlayed) * 100 : 0.0;
  final stablefordPoints = player.scores.fold<int>(0, (sum, score) {
    final par = courseHoles.firstWhere((h) => h.holeNumber == score.holeNumber, orElse: () => Hole(holeNumber: score.holeNumber, par: 4, yards: 400)).par;
    final diff = par - (score.scoreValue ?? par) + 2;
    return sum + (diff > 0 ? diff : 0);
  });
  return {
    'totalScore': totalScore,
    'stablefordPoints': stablefordPoints,
    'girPercentage': girPercentage,
  };
}

void calculateStats(String playerId, Map<String, GamePlayer> players, int totalPar, List<Hole> courseHoles) {
  final player = players[playerId]!;
  final stats = calculatePlayerStats(player, courseHoles);
  players[playerId] = player.copyWith(
    totalScore: stats['totalScore'] as int,
    girPercentage: stats['girPercentage'] as double,
  );
}

void calculateSkins(int holeNumber, Map<String, GamePlayer> players, bool skinsMode, Map<String, int> skinsEarnings, int skinsBet) {
  if (!skinsMode) return;
  final scores = players.map((k, v) => MapEntry(k, v.scores.firstWhere((s) => s.holeNumber == holeNumber, orElse: () => Score(holeNumber: holeNumber, gir: false)).scoreValue ?? 999));
  final minScore = scores.values.reduce((a, b) => a < b ? a : b);
  final winners = scores.entries.where((e) => e.value == minScore).map((e) => e.key).toList();
  if (winners.length == 1) {
    skinsEarnings[winners.first] = (skinsEarnings[winners.first] ?? 0) + skinsBet;
    final winnerScore = players[winners.first]!.scores.firstWhere((s) => s.holeNumber == holeNumber);
    players[winners.first] = players[winners.first]!.copyWith(
      scores: players[winners.first]!.scores.map((s) => s.holeNumber == holeNumber ? Score(holeNumber: s.holeNumber, scoreValue: s.scoreValue, putts: s.putts, gir: s.gir, skinsWinner: true) : s).toList(),
    );
  }
}