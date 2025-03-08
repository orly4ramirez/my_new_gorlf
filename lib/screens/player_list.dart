import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/score.dart';
import 'player_card.dart';
import '../utils/game_utils.dart';
import '../models/game.dart';
import '../models/course.dart';
import '../services/firestore_service.dart';
import '../models/game_player.dart';

class PlayerList extends StatefulWidget {
  final Game game;
  final Course course;
  final FirestoreService firestoreService;

  const PlayerList({
    super.key,
    required this.game,
    required this.course,
    required this.firestoreService,
  });

  @override
  PlayerListState createState() => PlayerListState();
}

class PlayerListState extends State<PlayerList> {
  final Map<String, int> _skinsEarnings = {};
  final TextEditingController _playerIdController = TextEditingController();
  final Set<String> _previousPlayers = {};
  Map<String, Map<String, dynamic>> _cachedStats = {};
  late ValueNotifier<Game> _gameNotifier;

  @override
  void initState() {
    super.initState();
    _previousPlayers.addAll(widget.game.players.keys);
    _gameNotifier = ValueNotifier<Game>(widget.game);
    for (var playerId in widget.game.players.keys) {
      _preloadStats(playerId);
    }
  }

  @override
  void dispose() {
    _playerIdController.dispose();
    _gameNotifier.dispose();
    super.dispose();
  }

  Future<void> _preloadStats(String playerId) async {
    _cachedStats[playerId] = await _getPlayerStats(playerId);
    if (mounted) setState(() {});
  }

  Future<double> _getUserHandicap() async {
    final games = await widget.firestoreService.getGames().first;
    return calculateHandicap(games);
  }

  Future<void> _updateHole(int holeNumber, String field, dynamic value, String playerId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final player = _gameNotifier.value.players[playerId]!;
    final scores = List<Score>.from(player.scores);
    final scoreIndex = scores.indexWhere((s) => s.holeNumber == holeNumber);
    Score score;

    if (scoreIndex == -1) {
      score = Score(holeNumber: holeNumber, gir: false, scoreValue: 0, putts: 0, skinsWinner: false); // Ensure skinsWinner defaults false
      scores.add(score);
      final newIndex = scores.length - 1;
      score = Score(
        holeNumber: holeNumber,
        scoreValue: field == 'scoreValue' ? value as int? : score.scoreValue,
        putts: field == 'putts' ? value as int? : score.putts,
        gir: field == 'gir' ? value as bool? ?? false : score.gir,
        skinsWinner: field == 'skinsWinner' ? value as bool? ?? false : score.skinsWinner,
      );
      scores[newIndex] = score;
    } else {
      score = scores[scoreIndex];
      scores[scoreIndex] = Score(
        holeNumber: holeNumber,
        scoreValue: field == 'scoreValue' ? value as int? : score.scoreValue,
        putts: field == 'putts' ? value as int? : score.putts,
        gir: field == 'gir' ? value as bool? ?? false : score.gir,
        skinsWinner: field == 'skinsWinner' ? value as bool? ?? false : score.skinsWinner,
      );
    }

    final updatedPlayer = player.copyWith(
      scores: scores,
      girPercentage: scores.isEmpty ? 0.0 : (scores.where((s) => s.gir ?? false).length / scores.length) * 100,
    );
    _gameNotifier.value.players[playerId] = updatedPlayer;

    if (field == 'skinsWinner' && value == true) {
      for (var otherPlayerId in _gameNotifier.value.players.keys) {
        if (otherPlayerId != playerId) {
          final otherPlayer = _gameNotifier.value.players[otherPlayerId]!;
          final otherScores = List<Score>.from(otherPlayer.scores);
          final otherScoreIndex = otherScores.indexWhere((s) => s.holeNumber == holeNumber);
          if (otherScoreIndex == -1) {
            otherScores.add(Score(holeNumber: holeNumber, gir: false, scoreValue: 0, putts: 0, skinsWinner: false));
          }
          _gameNotifier.value.players[otherPlayerId] = otherPlayer.copyWith(scores: otherScores);
        }
      }
    }

    calculateSkins(holeNumber, _gameNotifier.value.players, _gameNotifier.value.skinsMode, _skinsEarnings, _gameNotifier.value.skinsBet);

    await widget.firestoreService.updateGame(_gameNotifier.value.id, {
      'players': _gameNotifier.value.players.map((k, v) => MapEntry(k, v.toMap())),
    });
    _cachedStats[playerId] = await _getPlayerStats(playerId);
    _gameNotifier.notifyListeners();
  }

  Future<void> _syncScorecardToGame(String playerId) async {
    final player = _gameNotifier.value.players[playerId]!;
    final scorecardTotal = player.scores.fold<int>(0, (sum, score) => sum + (score.scoreValue ?? 0));
    final updatedPlayer = player.copyWith(totalScore: scorecardTotal);
    _gameNotifier.value.players[playerId] = updatedPlayer;

    await widget.firestoreService.updateGame(_gameNotifier.value.id, {
      'players': _gameNotifier.value.players.map((k, v) => MapEntry(k, v.toMap())),
    });
    _gameNotifier.notifyListeners();
  }

  Future<void> _removePlayer(String playerId) async {
    final user = FirebaseAuth.instance.currentUser!;
    final userId = user.uid;
    if (playerId == userId) return;

    setState(() {
      _gameNotifier.value.players.remove(playerId);
      _skinsEarnings.remove(playerId);
      _cachedStats.remove(playerId);
    });
    await widget.firestoreService.updateGame(_gameNotifier.value.id, {
      'players': _gameNotifier.value.players.map((k, v) => MapEntry(k, v.toMap())),
    });
    _gameNotifier.notifyListeners();
  }

  Future<void> _addPlayer(String playerId, double handicapAdjustment) async {
    if (playerId.isEmpty || _gameNotifier.value.players.containsKey(playerId)) return;

    final newPlayer = GamePlayer(
      playerId: playerId,
      scores: List.generate(18, (i) => Score(holeNumber: i + 1, gir: false, scoreValue: 0, putts: 0, skinsWinner: false)), // Pre-fill scores
      totalScore: 0,
      girPercentage: 0.0,
      holeInOneCount: 0,
      handicapAdjustment: handicapAdjustment,
    );

    final updatedPlayers = Map<String, GamePlayer>.from(_gameNotifier.value.players);
    updatedPlayers[playerId] = newPlayer;
    _gameNotifier.value.players.clear();
    _gameNotifier.value.players.addAll(updatedPlayers);

    await widget.firestoreService.updateGame(_gameNotifier.value.id, {
      'players': _gameNotifier.value.players.map((k, v) => MapEntry(k, v.toMap())),
    });

    setState(() {
      _previousPlayers.add(playerId);
      _preloadStats(playerId);
    });
    _gameNotifier.notifyListeners();
  }

  void showAddPlayerDialog() {
    double handicapAdjustment = 0.0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Player'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _previousPlayers;
                  }
                  return _previousPlayers.where((player) =>
                      player.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  _playerIdController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  _playerIdController.text = controller.text;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Player ID or Name'),
                    onSubmitted: (_) => onFieldSubmitted(),
                  );
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Handicap Adjustment'),
                keyboardType: TextInputType.number,
                onChanged: (value) => handicapAdjustment = double.tryParse(value) ?? 0.0,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _addPlayer(_playerIdController.text.trim(), handicapAdjustment);
              _playerIdController.clear();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getPlayerStats(String playerId) async {
    final playerData = _gameNotifier.value.players[playerId]!;
    final stats = calculatePlayerStats(playerData, widget.course.holes);
    final avgPutts = calculateAvgPutts(playerData.scores);
    final skinsWon = playerData.scores.where((s) => s.skinsWinner == true).length;
    final hcp = playerId == FirebaseAuth.instance.currentUser!.uid ? await _getUserHandicap() : playerData.handicapAdjustment;
    final front9Total = playerData.scores.where((s) => s.holeNumber <= 9).fold<int>(0, (sum, s) => sum + (s.scoreValue ?? 0));
    final back9Total = playerData.scores.where((s) => s.holeNumber > 9).fold<int>(0, (sum, s) => sum + (s.scoreValue ?? 0));
    final scoredHoles = playerData.scores.where((s) => s.scoreValue != null && s.scoreValue! > 0).length;
    final girPercentage = scoredHoles > 0 ? (playerData.scores.where((s) => s.gir ?? false).length / scoredHoles) * 100 : 0.0;

    return {
      'hcp': hcp,
      'score': stats['totalScore'],
      'stableford': stats['stablefordPoints'],
      'gir': girPercentage,
      'putts': avgPutts,
      'skins': skinsWon,
      'front9': front9Total,
      'back9': back9Total,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final mainPlayerId = user.uid;

    return StreamBuilder<Game>(
      stream: widget.firestoreService.streamGame(widget.game.id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _gameNotifier.value = snapshot.data!;
          print('Stream update: ${_gameNotifier.value.players.keys}');
        }

        return ValueListenableBuilder<Game>(
          valueListenable: _gameNotifier,
          builder: (context, game, _) {
            final sortedPlayers = game.players.keys.toList()
              ..sort((a, b) => a == mainPlayerId ? -1 : b == mainPlayerId ? 1 : a.compareTo(b));

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sortedPlayers.map((playerId) => PlayerCard(
                  playerId: playerId,
                  game: game,
                  course: widget.course,
                  firestoreService: widget.firestoreService,
                  skinsEarnings: _skinsEarnings,
                  onUpdateHole: _updateHole,
                  onRemovePlayer: _removePlayer,
                  onSyncScorecard: _syncScorecardToGame,
                  cachedStats: _cachedStats,
                )).toList(),
              ),
            );
          },
        );
      },
    );
  }
}