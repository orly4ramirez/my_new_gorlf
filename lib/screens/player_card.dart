import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'scorecard_widget.dart';
import '../models/game.dart';
import '../models/course.dart';
import '../services/firestore_service.dart';

class PlayerCard extends StatefulWidget {
  final String playerId;
  final Game game;
  final Course course;
  final FirestoreService firestoreService;
  final Map<String, int> skinsEarnings;
  final Future<void> Function(int, String, dynamic, String) onUpdateHole;
  final Future<void> Function(String) onRemovePlayer;
  final Future<void> Function(String) onSyncScorecard;
  final Map<String, Map<String, dynamic>> cachedStats;

  const PlayerCard({
    super.key,
    required this.playerId,
    required this.game,
    required this.course,
    required this.firestoreService,
    required this.skinsEarnings,
    required this.onUpdateHole,
    required this.onRemovePlayer,
    required this.onSyncScorecard,
    required this.cachedStats,
  });

  @override
  _PlayerCardState createState() => _PlayerCardState();
}

class _PlayerCardState extends State<PlayerCard> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getPlayerName() {
    final user = FirebaseAuth.instance.currentUser!;
    if (widget.playerId == user.uid) return user.displayName ?? (user.email?.split('@')[0] ?? 'Unknown');
    return widget.playerId.split('_').last;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final mainPlayerId = user.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              indicator: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, -2))],
              ),
              tabs: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Text(_getPlayerName()),
                  ),
                  onEnter: (_) => setState(() {}),
                  onExit: (_) => setState(() {}),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: const Text('Front 9'),
                  ),
                  onEnter: (_) => setState(() {}),
                  onExit: (_) => setState(() {}),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: const Text('Back 9'),
                  ),
                  onEnter: (_) => setState(() {}),
                  onExit: (_) => setState(() {}),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: widget.cachedStats[widget.playerId] != null
                        ? Text(
                      'Hcp: ${widget.cachedStats[widget.playerId]!['hcp'].toStringAsFixed(1)} | Score: ${widget.cachedStats[widget.playerId]!['score']} | '
                          'Stableford: ${widget.cachedStats[widget.playerId]!['stableford']} | GIR: ${widget.cachedStats[widget.playerId]!['gir'].toStringAsFixed(1)}% | '
                          'Putts: ${widget.cachedStats[widget.playerId]!['putts'].toStringAsFixed(1)} | Skins: ${widget.cachedStats[widget.playerId]!['skins']} | '
                          'F9: ${widget.cachedStats[widget.playerId]!['front9']} | B9: ${widget.cachedStats[widget.playerId]!['back9']}',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    )
                        : const SizedBox(height: 20, child: Center(child: CircularProgressIndicator())),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sync, size: 20),
                        tooltip: 'Sync Scorecard to Game',
                        onPressed: () => widget.onSyncScorecard(widget.playerId),
                      ),
                      if (widget.playerId != mainPlayerId)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          tooltip: 'Remove Player',
                          onPressed: () => widget.onRemovePlayer(widget.playerId),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: _tabController.index == 0 ? 0 : 450, // Adjusted for 9 holes
              child: _tabController.index == 0
                  ? const SizedBox.shrink()
                  : _tabController.index == 1
                  ? ScorecardWidget(
                player: widget.playerId,
                players: widget.game.players,
                skinsMode: widget.game.skinsMode,
                skinsEarnings: widget.skinsEarnings,
                courseHoles: widget.course.holes.map((h) => h.toMap()).toList(),
                startHole: 1,
                endHole: 9,
                onUpdateHole: widget.onUpdateHole,
                onRemovePlayer: widget.onRemovePlayer,
              )
                  : ScorecardWidget(
                player: widget.playerId,
                players: widget.game.players,
                skinsMode: widget.game.skinsMode,
                skinsEarnings: widget.skinsEarnings,
                courseHoles: widget.course.holes.map((h) => h.toMap()).toList(),
                startHole: 10,
                endHole: 18,
                onUpdateHole: widget.onUpdateHole,
                onRemovePlayer: widget.onRemovePlayer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}