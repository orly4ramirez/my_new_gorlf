import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../utils/game_utils.dart';

class StatsCard extends StatefulWidget {
  final FirestoreService firestoreService;

  const StatsCard({super.key, required this.firestoreService});

  @override
  StatsCardState createState() => StatsCardState();
}

class StatsCardState extends State<StatsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.firestoreService.getGames(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final games = snapshot.data!;
        final handicap = calculateHandicap(games);
        return GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hcp: ${handicap.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Avg Score: ${calculateAvgScore(games).toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'GIR: ${calculateGirPercentage(games).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}