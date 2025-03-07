import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/game.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';
import 'edit_popup.dart';
import '../simulation_screen.dart';

class GameRow {
  final Game game;
  final Future<List<Course>> golfCoursesFuture;
  final FirestoreService firestoreService;

  const GameRow({
    required this.game,
    required this.golfCoursesFuture,
    required this.firestoreService,
  });

  DataRow build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final mainPlayerId = user.uid;
    final isToday = game.date == DateTime.now().toIso8601String().substring(0, 10);

    return DataRow(
      color: WidgetStateProperty.resolveWith((_) => isToday ? Colors.blue[50] : null),
      cells: [
        DataCell(
          _HoverableField(
            text: game.date,
            onTap: () => EditPopup.show(context, game, 'Date', game.date, firestoreService),
          ),
        ),
        DataCell(
          _HoverableField(
            text: game.courseId,
            onTap: () => EditPopup.show(
              context,
              game,
              'Course',
              game.courseId,
              firestoreService,
              isCourse: true,
              golfCoursesFuture: golfCoursesFuture,
            ),
          ),
        ),
        DataCell(
          _HoverableField(
            text: game.title,
            onTap: () => EditPopup.show(context, game, 'Game Description', game.title, firestoreService),
          ),
        ),
        DataCell(
          _HoverableField(
            text: game.players[mainPlayerId]?.totalScore.toString() ?? '',
            onTap: () => EditPopup.show(
              context,
              game,
              'Score',
              game.players[mainPlayerId]?.totalScore.toString() ?? '',
              firestoreService,
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Edit Scorecard',
                onPressed: () => _navigateToSimulation(context),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                tooltip: 'Delete Game',
                onPressed: () async {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Game'),
                      content: Text('Are you sure you want to delete "${game.courseId} on ${game.date} - ${game.title}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (shouldDelete ?? false) await firestoreService.deleteGame(game.id);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToSimulation(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: _buildSimulationScreen));
  }

  Widget _buildSimulationScreen(BuildContext context) {
    return GorlfSimulationScreen(gameId: game.id);
  }
}

class _HoverableField extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _HoverableField({required this.text, required this.onTap});

  @override
  _HoverableFieldState createState() => _HoverableFieldState();
}

class _HoverableFieldState extends State<_HoverableField> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          color: _isHovered ? Colors.grey[800] : Colors.transparent,
          child: Text(
            widget.text,
            style: TextStyle(color: _isHovered ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }
}