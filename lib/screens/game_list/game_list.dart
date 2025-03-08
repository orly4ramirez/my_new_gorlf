import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/game.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';
import 'game_row.dart';

class GameList extends StatelessWidget {
  final FirestoreService firestoreService;
  final Future<List<Course>> golfCoursesFuture;

  const GameList({
    super.key,
    required this.firestoreService,
    required this.golfCoursesFuture,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Game>>(
      stream: firestoreService.getGames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No games available', style: TextStyle(color: Colors.grey)));
        }
        final games = snapshot.data!;
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: games.map((game) => GameRow(
              game: game,
              firestoreService: firestoreService,
              golfCoursesFuture: golfCoursesFuture,
            )).toList(),
          ),
        );
      },
    );
  }
}