import 'package:flutter/material.dart';
import '../models/game_player.dart';
import '../models/score.dart';
// ... (previous imports remain the same)

class ScorecardWidget extends StatefulWidget {
  final String player;
  final Map<String, GamePlayer> players;
  final bool skinsMode;
  final Map<String, int> skinsEarnings;
  final List<Map<String, dynamic>> courseHoles;
  final int startHole;
  final int endHole;
  final Function(int, String, dynamic, String) onUpdateHole;
  final Function(String) onRemovePlayer;

  const ScorecardWidget({
    super.key,
    required this.player,
    required this.players,
    required this.skinsMode,
    required this.skinsEarnings,
    required this.courseHoles,
    required this.startHole,
    required this.endHole,
    required this.onUpdateHole,
    required this.onRemovePlayer,
  });

  @override
  ScorecardWidgetState createState() => ScorecardWidgetState();
}

class ScorecardWidgetState extends State<ScorecardWidget> {
  String _getScoreLabel(int par, int? score) {
    if (score == null) return '-';
    final diff = score - par;
    switch (diff) {
      case -3: return 'Albatross';
      case -2: return 'Eagle';
      case -1: return 'Birdie';
      case 0: return 'Par';
      case 1: return 'Bogey';
      case 2: return 'Double Bogey';
      case 3: return 'Triple Bogey';
      default: return score.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerScores = widget.players[widget.player]!.scores;
    final hasMultiplePlayers = widget.players.length > 1;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(widget.endHole - widget.startHole + 1, (index) {
                final holeNumber = widget.startHole + index;
                final holeData = widget.courseHoles.firstWhere((h) => h['holeNumber'] == holeNumber);
                final playerScore = playerScores.firstWhere(
                      (s) => s.holeNumber == holeNumber,
                  orElse: () => Score(holeNumber: holeNumber, gir: false),
                );
                final par = holeData['par'] as int;
                final yardage = holeData['yards'] as int;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Hole $holeNumber\nPar $par\n$yardage yds',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<int?>(
                        value: playerScore.scoreValue,
                        items: List.generate(10, (i) => i + par - 2)
                            .map((score) => DropdownMenuItem(value: score, child: Text(_getScoreLabel(par, score))))
                            .toList(),
                        onChanged: (value) async {
                          await widget.onUpdateHole(holeNumber, 'scoreValue', value, widget.player);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<int?>(
                        value: playerScore.putts,
                        items: List.generate(6, (i) => i)
                            .map((putts) => DropdownMenuItem(value: putts, child: Text(putts.toString())))
                            .toList(),
                        onChanged: (value) async {
                          await widget.onUpdateHole(holeNumber, 'putts', value, widget.player);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('GIR', style: TextStyle(fontSize: 12)),
                          Checkbox(
                            value: playerScore.gir,
                            onChanged: (value) async {
                              await widget.onUpdateHole(holeNumber, 'gir', value ?? false, widget.player);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      if (widget.skinsMode && hasMultiplePlayers)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Skins', style: TextStyle(fontSize: 12)),
                            Checkbox(
                              value: playerScore.skinsWinner ?? false,
                              onChanged: (value) async {
                                await widget.onUpdateHole(holeNumber, 'skinsWinner', value ?? false, widget.player);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => widget.onRemovePlayer(widget.player),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remove Player'),
            ),
          ),
        ],
      ),
    );
  }
}