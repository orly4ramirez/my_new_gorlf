import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/game.dart';
import '../../models/game_player.dart';
import '../../models/score.dart';
import '../../services/firestore_service.dart';
import '../../utils/game_utils.dart';

class StatsCard extends StatefulWidget {
  final FirestoreService firestoreService;

  const StatsCard({super.key, required this.firestoreService});

  @override
  StatsCardState createState() => StatsCardState();
}

class StatsCardState extends State<StatsCard> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Game>>(
      stream: widget.firestoreService.getGames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No games available', style: TextStyle(color: Colors.grey));
        }
        final games = snapshot.data!;
        return PopupMenuButton<String>(
          onSelected: (_) {},
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avg Score: ${calculateAvgScore(games).toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'GIR: ${calculateGirPercentage(games).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'Avg Putts: ${calculateAvgPuttsAcrossGames(games).toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
          child: Text(
            'Hcp: ${calculateHandicap(games).toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
        );
      },
    );
  }

  double calculateAvgPuttsAcrossGames(List<Game> games) {
    final playerId = FirebaseAuth.instance.currentUser!.uid;
    final allScores = games
        .map((g) => g.players[playerId]?.scores ?? <Score>[])
        .where((scores) => scores.isNotEmpty)
        .toList();
    if (allScores.isEmpty) return 0.0;
    final avgPuttsPerGame = allScores.map((scores) => calculateAvgPutts(scores));
    return avgPuttsPerGame.reduce((a, b) => a + b) / avgPuttsPerGame.length;
  }
}