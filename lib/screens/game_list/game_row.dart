import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/game.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';
import 'edit_popup.dart';
import '../simulation_screen.dart';

class GameRow extends StatelessWidget {
  final Game game;
  final FirestoreService firestoreService;
  final Future<List<Course>> golfCoursesFuture;

  const GameRow({
    super.key,
    required this.game,
    required this.firestoreService,
    required this.golfCoursesFuture,
  });

  bool _isToday(String date) {
    final today = DateTime.now();
    final gameDate = DateTime.parse(date);
    return today.year == gameDate.year && today.month == gameDate.month && today.day == gameDate.day;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final playerScore = game.players[user.uid]?.totalScore.toString() ?? 'N/A';
    final isToday = _isToday(game.date);

    return FutureBuilder<List<Course>>(
      future: golfCoursesFuture,
      builder: (context, snapshot) {
        String courseDisplay = game.courseId;
        if (snapshot.hasData) {
          final course = snapshot.data!.firstWhere((c) => c.name == game.courseId, orElse: () => Course(id: '', name: game.courseId, userId: '', status: 'Unknown', slopeRating: 113, yardage: 0, totalPar: 72, holes: []));
          courseDisplay = '${course.name}${course.slopeRating != 113 ? ' (Slope: ${course.slopeRating})' : ''}';
        }
        return Card(
          elevation: 2,
          color: isToday ? Colors.blue[50] : null, // Mild highlight
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => EditPopup.show(context, game, 'Date', game.date, firestoreService),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(game.date, style: TextStyle(fontSize: 12, color: isToday ? Colors.blue : Colors.black)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => EditPopup.show(context, game, 'Course', game.courseId, firestoreService, isCourse: true, golfCoursesFuture: golfCoursesFuture),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(courseDisplay, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => EditPopup.show(context, game, 'Score', playerScore == 'N/A' ? '' : playerScore, firestoreService),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(playerScore, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => EditPopup.show(context, game, 'Description', game.title, firestoreService),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(game.title.isNotEmpty ? game.title : '', style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.golf_course, size: 20),
                      tooltip: 'View Scorecard',
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GorlfSimulationScreen(gameId: game.id))),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      tooltip: 'Delete Game',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Game'),
                            content: Text('Are you sure you want to delete the game on ${game.date} at ${game.courseId}?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await firestoreService.deleteGame(game.id);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}