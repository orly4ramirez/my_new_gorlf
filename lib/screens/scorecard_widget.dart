import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/score.dart';
import '../models/game_player.dart';

class ScorecardWidget extends StatefulWidget {
  final String player;
  final Map<String, GamePlayer> players;
  final bool skinsMode;
  final Map<String, int> skinsEarnings;
  final List<Map<String, dynamic>> courseHoles;
  final int startHole;
  final int endHole;
  final Future<void> Function(int, String, dynamic, String) onUpdateHole;
  final Future<void> Function(String) onRemovePlayer;

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
  @override
  Widget build(BuildContext context) {
    final playerData = widget.players[widget.player]!;
    final relevantHoles = widget.courseHoles
        .where((h) => h['holeNumber'] >= widget.startHole && h['holeNumber'] <= widget.endHole)
        .toList();
    print('ScorecardWidget: startHole=${widget.startHole}, endHole=${widget.endHole}, relevantHoles.length=${relevantHoles.length}');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 8.0,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 40,
        columns: [
          const DataColumn(label: Text('Hole', style: TextStyle(fontSize: 12))),
          const DataColumn(label: Text('Par', style: TextStyle(fontSize: 12))),
          const DataColumn(label: Text('Yards', style: TextStyle(fontSize: 12))),
          const DataColumn(label: Text('Score', style: TextStyle(fontSize: 12))),
          const DataColumn(label: Text('Putts', style: TextStyle(fontSize: 12))),
          const DataColumn(label: Text('GIR', style: TextStyle(fontSize: 12))),
          if (widget.skinsMode) const DataColumn(label: Text('Skins', style: TextStyle(fontSize: 12))),
        ],
        rows: relevantHoles.map((hole) {
          final holeNumber = hole['holeNumber'] as int;
          final par = hole['par'] as int;
          final yards = hole['yards'] as int;
          final score = playerData.scores.firstWhere(
                (s) => s.holeNumber == holeNumber,
            orElse: () => Score(holeNumber: holeNumber, gir: false, scoreValue: 0, putts: 0),
          );
          return DataRow(cells: [
            DataCell(Text('$holeNumber', style: const TextStyle(fontSize: 12))),
            DataCell(Text('$par', style: const TextStyle(fontSize: 12))),
            DataCell(Text('$yards', style: const TextStyle(fontSize: 12))),
            DataCell(
              DropdownButton<int>(
                value: score.scoreValue ?? 0,
                items: List.generate(11, (i) => i)
                    .map((i) => DropdownMenuItem(value: i, child: Text(i.toString(), style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (value) async {
                  await widget.onUpdateHole(holeNumber, 'scoreValue', value, widget.player);
                  setState(() {});
                },
                underline: const SizedBox(),
                isDense: true,
              ),
            ),
            DataCell(
              DropdownButton<int>(
                value: score.putts ?? 0,
                items: List.generate(6, (i) => i)
                    .map((i) => DropdownMenuItem(value: i, child: Text(i.toString(), style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (value) async {
                  await widget.onUpdateHole(holeNumber, 'putts', value, widget.player);
                  setState(() {});
                },
                underline: const SizedBox(),
                isDense: true,
              ),
            ),
            DataCell(
              Checkbox(
                value: score.gir ?? false,
                onChanged: (value) async {
                  await widget.onUpdateHole(holeNumber, 'gir', value, widget.player);
                  setState(() {});
                },
              ),
            ),
            if (widget.skinsMode)
              DataCell(
                Checkbox(
                  value: score.skinsWinner ?? false,
                  onChanged: (value) async {
                    await widget.onUpdateHole(holeNumber, 'skinsWinner', value, widget.player);
                    setState(() {});
                  },
                ),
              ),
          ]);
        }).toList(),
      ),
    );
  }
}