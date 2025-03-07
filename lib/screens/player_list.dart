import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/score.dart';
import 'scorecard_widget.dart';
import '../utils/game_utils.dart';
import '../models/game.dart';
import '../models/course.dart';
import '../services/firestore_service.dart';

class PlayerList extends StatefulWidget {
  final Game game;
  final Course course;
  final FirestoreService firestoreService;

  const PlayerList({
    super.key,
    required this.game,
    required this.course,
    required this.firestoreService,
  });

  @override
  PlayerListState createState() => PlayerListState();
}

class PlayerListState extends State<PlayerList> {
  final Map<String, int> _skinsEarnings = {};

  Future<void> _updateHole(int holeNumber, String field, dynamic value, String playerId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final player = widget.game.players[playerId]!;
    final scores = player.scores;
    final scoreIndex = scores.indexWhere((s) => s.holeNumber == holeNumber);
    final score = scoreIndex != -1
        ? scores[scoreIndex]
        : Score(holeNumber: holeNumber, gir: false);

    if (scoreIndex == -1) scores.add(score);
    scores[scoreIndex] = Score(
      holeNumber: holeNumber,
      scoreValue: field == 'scoreValue' ? value as int? : score.scoreValue,
      putts: field == 'putts' ? value as int? : score.putts,
      gir: field == 'gir' ? value as bool : score.gir,
      skinsWinner: field == 'skinsWinner' ? value as bool : score.skinsWinner,
    );

    final updatedPlayer = player.copyWith(
      scores: scores,
      totalScore: scores.fold(0, (sum, s) => sum! + (s.scoreValue ?? 0)),
      girPercentage: scores.isEmpty ? 0.0 : (scores.where((s) => s.gir).length / scores.length) * 100,
    );
    widget.game.players[playerId] = updatedPlayer;

    calculateSkins(holeNumber, widget.game.players, widget.game.skinsMode, _skinsEarnings, widget.game.skinsBet);

    await widget.firestoreService.updateGame(widget.game.id, {
      'players': widget.game.players.map((k, v) => MapEntry(k, v.toMap())),
      'skinsMode': widget.game.skinsMode,
      'skinsBet': widget.game.skinsBet,
    });

    if (mounted) setState(() {});
  }

  Future<void> _removePlayer(String playerId) async {
    final user = FirebaseAuth.instance.currentUser!;
    final userId = user.uid;
    if (playerId == userId) return;

    setState(() {
      widget.game.players.remove(playerId);
      _skinsEarnings.remove(playerId);
    });
    await widget.firestoreService.updateGame(widget.game.id, {
      'players': widget.game.players.map((k, v) => MapEntry(k, v.toMap())),
    });
  }

  String _getPlayerStats(String playerId) {
    final playerData = widget.game.players[playerId]!;
    final stats = calculatePlayerStats(playerData, widget.course.holes); // Changed CourseHole to Hole
    final avgPutts = calculateAvgPutts(playerData.scores);
    final skinsWon = playerData.scores.where((s) => s.skinsWinner == true).length;
    return 'Hcp: ${playerData.handicapAdjustment} | Score: ${playerData.totalScore} | GIR: ${stats['girPercentage'].toStringAsFixed(1)}% | Avg Putts: ${avgPutts.toStringAsFixed(1)} | Skins: $skinsWon';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final mainPlayerId = user.uid;
    final sortedPlayers = widget.game.players.keys.toList()
      ..sort((a, b) => a == mainPlayerId ? -1 : b == mainPlayerId ? 1 : a.compareTo(b));

    return Column(
      children: sortedPlayers.map((playerId) => ExpansionTile(
        title: Row(
          children: [
            Text(playerId, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text(
              _getPlayerStats(playerId),
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
        children: [
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black,
                  indicator: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tabs: const [
                    Tab(child: Text('Front 9')),
                    Tab(child: Text('Back 9')),
                  ],
                ),
                SizedBox(
                  height: 250,
                  child: TabBarView(
                    children: [
                      ScorecardWidget(
                        player: playerId,
                        players: widget.game.players,
                        skinsMode: widget.game.skinsMode,
                        skinsEarnings: _skinsEarnings,
                        courseHoles: widget.course.holes.map((h) => h.toMap()).toList(),
                        startHole: 1,
                        endHole: 9,
                        onUpdateHole: _updateHole,
                        onRemovePlayer: _removePlayer,
                      ),
                      ScorecardWidget(
                        player: playerId,
                        players: widget.game.players,
                        skinsMode: widget.game.skinsMode,
                        skinsEarnings: _skinsEarnings,
                        courseHoles: widget.course.holes.map((h) => h.toMap()).toList(),
                        startHole: 10,
                        endHole: 18,
                        onUpdateHole: _updateHole,
                        onRemovePlayer: _removePlayer,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      )).toList(),
    );
  }
}