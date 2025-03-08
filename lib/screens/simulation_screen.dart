import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game.dart';
import '../models/course.dart';
import '../services/firestore_service.dart';
import '../utils/game_utils.dart';
import 'game_header.dart';
import 'player_list.dart';

class GorlfSimulationScreen extends StatefulWidget {
  final String gameId;

  const GorlfSimulationScreen({super.key, required this.gameId});

  @override
  GorlfSimulationScreenState createState() => GorlfSimulationScreenState();
}

class GorlfSimulationScreenState extends State<GorlfSimulationScreen> {
  final FirestoreService firestoreService = FirestoreService();
  final GlobalKey<PlayerListState> _playerListKey = GlobalKey<PlayerListState>();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scorecard'),
        // Removed the entire actions block
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: FutureBuilder<Game>(
          future: firestoreService.getGame(widget.gameId),
          builder: (context, gameSnapshot) {
            if (!gameSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final game = gameSnapshot.data!;
            return FutureBuilder<List<Course>>(
              future: firestoreService.getCourses(''),
              builder: (context, coursesSnapshot) {
                if (!coursesSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                final course = coursesSnapshot.data!.firstWhere(
                      (c) => c.name == game.courseId,
                  orElse: () => Course(
                    id: game.courseId,
                    name: game.courseId,
                    status: 'Unknown',
                    slopeRating: 113,
                    yardage: 0,
                    totalPar: 72,
                    holes: List.generate(18, (i) => Hole(holeNumber: i + 1, par: 4, yards: 400)),
                    userId: user.uid,
                  ),
                );
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GameHeader(
                        game: game,
                        course: course,
                        userName: user.displayName ?? user.email ?? 'Unknown',
                        firestoreService: firestoreService,
                      ),
                      const SizedBox(height: 16),
                      PlayerList(
                        key: _playerListKey,
                        game: game,
                        course: course,
                        firestoreService: firestoreService,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}