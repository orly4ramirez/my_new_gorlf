import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';
import 'game_row.dart';

class GameList extends StatefulWidget {
  final Future<List<Course>> golfCoursesFuture;
  final FirestoreService firestoreService;

  const GameList({
    super.key,
    required this.golfCoursesFuture,
    required this.firestoreService,
  });

  @override
  GameListState createState() => GameListState();
}

class GameListState extends State<GameList> {
  String _sortKey = 'date';
  bool _sortAscending = false;

  void _sortGames(String key) {
    setState(() {
      if (_sortKey == key) {
        _sortAscending = !_sortAscending;
      } else {
        _sortKey = key;
        _sortAscending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.firestoreService.getGames(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final games = snapshot.data!
          ..sort((a, b) {
            dynamic aValue = a.toMap()[_sortKey] ?? '';
            dynamic bValue = b.toMap()[_sortKey] ?? '';
            if (_sortKey == 'date') {
              aValue = DateTime.parse(aValue);
              bValue = DateTime.parse(bValue);
            }
            return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
          });

        return Column(
          children: [
            DataTable(
              columnSpacing: 20,
              columns: [
                DataColumn(label: const Text('Date'), onSort: (_, __) => _sortGames('date')),
                DataColumn(label: const Text('Course'), onSort: (_, __) => _sortGames('courseId')),
                DataColumn(label: const Text('Game Description'), onSort: (_, __) => _sortGames('title')),
                DataColumn(label: const Text('Score'), onSort: (_, __) => _sortGames('totalScore')),
                const DataColumn(label: Text('Actions')),
              ],
              rows: const [],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: SizedBox.shrink()),
                    DataColumn(label: SizedBox.shrink()),
                    DataColumn(label: SizedBox.shrink()),
                    DataColumn(label: SizedBox.shrink()),
                    DataColumn(label: SizedBox.shrink()),
                  ],
                  rows: games.map((game) => GameRow(
                    game: game,
                    golfCoursesFuture: widget.golfCoursesFuture,
                    firestoreService: widget.firestoreService,
                  ).build(context)).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}