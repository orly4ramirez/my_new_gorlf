import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game.dart';
import '../models/game_player.dart';
import '../models/course.dart';
import '../services/firestore_service.dart';
import '../utils/game_utils.dart';

class GameHeader extends StatefulWidget {
  final Game game;
  final Course course;
  final String userName;
  final FirestoreService firestoreService;

  const GameHeader({
    super.key,
    required this.game,
    required this.course,
    required this.userName,
    required this.firestoreService,
  });

  @override
  GameHeaderState createState() => GameHeaderState();
}

class GameHeaderState extends State<GameHeader> {
  late TextEditingController _skinsBetController;

  @override
  void initState() {
    super.initState();
    _skinsBetController = TextEditingController(text: widget.game.skinsBet.toString());
    _loadUserHandicap();
  }

  Future<void> _loadUserHandicap() async {
    final user = FirebaseAuth.instance.currentUser!;
    final playerDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('players').doc(widget.userName).get();
    if (playerDoc.exists && mounted) {
      final data = playerDoc.data()!;
      final handicap = (data['handicap'] as num?)?.toDouble() ?? 0.0;
      setState(() {
        widget.game.players[user.uid] = widget.game.players[user.uid]!.copyWith(handicapAdjustment: handicap);
      });
      await widget.firestoreService.updateGame(widget.game.id, {
        'players': widget.game.players.map((k, v) => MapEntry(k, v.toMap())),
      });
    }
  }

  Future<void> _addPlayer(BuildContext dialogContext) async {
    final newPlayerData = await _showAddPlayerDialog(dialogContext);
    if (!mounted || newPlayerData == null) return;

    final newPlayerName = newPlayerData['name'] as String;
    final newPlayerHandicap = (newPlayerData['handicap'] as num?)?.toDouble() ?? 0.0;

    final user = FirebaseAuth.instance.currentUser!;
    final playerId = '${user.uid}_$newPlayerName';

    final newPlayer = GamePlayer(
      playerId: playerId,
      scores: [],
      totalScore: 0,
      girPercentage: 0.0,
      holeInOneCount: 0,
      handicapAdjustment: newPlayerHandicap,
    );

    setState(() {
      widget.game.players[playerId] = newPlayer;
    });

    await widget.firestoreService.updateGame(widget.game.id, {
      'players': widget.game.players.map((k, v) => MapEntry(k, v.toMap())),
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalYardage = widget.course.holes.fold<int>(0, (acc, h) => acc + h.yards);
    final teamStats = calculateTeamTotals(widget.game.players);
    final teamAvgStats = calculateTeamAvgStats(widget.game.players, widget.course.holes);

    return StreamBuilder<Game>(
      stream: widget.firestoreService.streamGame(widget.game.id),
      builder: (context, snapshot) {
        final game = snapshot.hasData ? snapshot.data! : widget.game;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${game.date} (${game.courseId}/$totalYardage yards)',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Row(
                    children: [
                      Row(
                        children: [
                          const Text('Skins', style: TextStyle(fontSize: 12)),
                          Checkbox(
                            value: game.skinsMode,
                            onChanged: game.players.length > 1
                                ? (value) async {
                              await widget.firestoreService.updateGame(widget.game.id, {'skinsMode': value ?? false});
                            }
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _skinsBetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '\$ Bet', border: OutlineInputBorder()),
                          onChanged: (value) async {
                            final newBet = int.tryParse(value) ?? 5;
                            await widget.firestoreService.updateGame(widget.game.id, {'skinsBet': newBet});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.person_add, size: 20),
                        tooltip: 'Add Player',
                        onPressed: () => _addPlayer(context),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: 'Close Scorecard',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              if (game.players.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Team - Score: ${teamStats['totalScore']} | Stableford: ${teamAvgStats['stablefordPoints']} | '
                        'GIR: ${teamAvgStats['girPercentage'].toStringAsFixed(1)}% | Avg Putts: ${teamAvgStats['avgPutts'].toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _showAddPlayerDialog(BuildContext dialogContext) async {
    final nameController = TextEditingController();
    final handicapController = TextEditingController();
    return showDialog<Map<String, dynamic>>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: const Text('Add Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Player Name'),
            ),
            TextField(
              controller: handicapController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Handicap (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'name': nameController.text,
              'handicap': double.tryParse(handicapController.text),
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}