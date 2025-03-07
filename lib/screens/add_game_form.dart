import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added import
import '../models/course.dart';
import '../models/game.dart';
import '../models/game_player.dart';
import '../services/firestore_service.dart';

class AddGameForm extends StatefulWidget {
  final Future<List<Course>> golfCoursesFuture;
  final FirestoreService firestoreService;
  final VoidCallback onSave;

  const AddGameForm({
    super.key,
    required this.golfCoursesFuture,
    required this.firestoreService,
    required this.onSave,
  });

  @override
  AddGameFormState createState() => AddGameFormState();
}

class AddGameFormState extends State<AddGameForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  final _scoreController = TextEditingController();
  final _courseController = TextEditingController();
  final _teamNameController = TextEditingController();
  final _playerNameController = TextEditingController();
  String _gameType = 'stroke_gross';
  bool _useHandicap = true;
  final Map<String, GamePlayer> _players = {};
  List<String> _previousTitles = [];
  List<String> _previousCourses = [];
  List<String> _previousTeams = [];
  List<String> _previousPlayers = [];

  @override
  void initState() {
    super.initState();
    _loadAutocompleteData();
    final user = FirebaseAuth.instance.currentUser!;
    _players[user.uid] = GamePlayer(
      playerId: user.uid,
      scores: [],
      totalScore: 0,
      girPercentage: 0.0,
      stablefordPoints: null,
      holeInOneCount: 0,
      handicapAdjustment: 0.0,
    );
  }

  Future<void> _loadAutocompleteData() async {
    final titles = await widget.firestoreService.getGameTitles();
    final courses = (await widget.golfCoursesFuture).map((c) => c.name).toList();
    final teams = await widget.firestoreService.getTeamNames();
    final players = await widget.firestoreService.getPlayerNames();
    setState(() {
      _previousTitles = titles;
      _previousCourses = courses;
      _previousTeams = teams;
      _previousPlayers = players;
    });
  }

  void _addPlayer() async {
    final name = _playerNameController.text.trim();
    if (name.isNotEmpty && !_players.containsKey(name)) {
      final userDoc = await FirebaseFirestore.instance.collection('players').where('name', isEqualTo: name).get();
      String playerId = userDoc.docs.isEmpty
          ? (await FirebaseFirestore.instance.collection('players').doc().set({'name': name}).then((_) => FirebaseFirestore.instance.collection('players').where('name', isEqualTo: name).get())).docs.first.id
          : userDoc.docs.first.id;
      setState(() {
        _players[playerId] = GamePlayer(
          playerId: playerId,
          scores: [],
          totalScore: 0,
          girPercentage: 0.0,
          stablefordPoints: null,
          holeInOneCount: 0,
          handicapAdjustment: 0.0,
        );
        _previousPlayers = [..._previousPlayers, name]..toSet().toList();
        _playerNameController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final mainPlayerId = user.uid;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<String>(
                optionsBuilder: (textEditingValue) => _previousTitles.where((t) => t.toLowerCase().contains(textEditingValue.text.toLowerCase())),
                onSelected: (selection) => _titleController.text = selection,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  _titleController.text = controller.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Game Description'),
                    validator: (value) => value!.isEmpty ? 'Enter a description' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                validator: (value) => DateTime.tryParse(value!) == null ? 'Invalid date' : null,
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                optionsBuilder: (textEditingValue) => _previousCourses.where((c) => c.toLowerCase().contains(textEditingValue.text.toLowerCase())),
                onSelected: (selection) => _courseController.text = selection,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  _courseController.text = controller.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Course Name'),
                    validator: (value) => value!.isEmpty ? 'Enter a course' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gameType,
                items: [
                  'stroke_gross', 'stroke_net', 'match', 'stableford', 'best_ball', 'scramble',
                  'shamble', 'alternate_shot', 'greensome', 'skins', 'bingo_bango_bongo', 'nassau'
                ].map((type) => DropdownMenuItem(value: type, child: Text(type.replaceAll('_', ' ').toUpperCase()))).toList(),
                onChanged: (value) => setState(() => _gameType = value!),
                decoration: const InputDecoration(labelText: 'Game Format'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scoreController,
                decoration: const InputDecoration(labelText: 'Your Total Score'),
                keyboardType: TextInputType.number,
                validator: (value) => int.tryParse(value!) == null ? 'Enter a valid score' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Use Handicap'),
                value: _useHandicap,
                onChanged: (value) => setState(() => _useHandicap = value),
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                optionsBuilder: (textEditingValue) => _previousTeams.where((t) => t.toLowerCase().contains(textEditingValue.text.toLowerCase())),
                onSelected: (selection) => _teamNameController.text = selection,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  _teamNameController.text = controller.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Team Name (Optional)'),
                  );
                },
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                optionsBuilder: (textEditingValue) => _previousPlayers.where((p) => p.toLowerCase().contains(textEditingValue.text.toLowerCase())),
                onSelected: (selection) {
                  _playerNameController.text = selection;
                  _addPlayer();
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  _playerNameController.text = controller.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Add Player'),
                    onFieldSubmitted: (_) => _addPlayer(),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text('Players: ${_players.length}'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final courseName = _courseController.text;
                    final courses = await widget.golfCoursesFuture;
                    final course = courses.firstWhere((c) => c.name == courseName, orElse: () => Course(
                      id: '',
                      name: courseName,
                      status: 'Custom',
                      slopeRating: 113, // Default slope
                      yardage: 0,
                      totalPar: 72, // Default par
                      holes: List.generate(18, (i) => Hole(holeNumber: i + 1, par: 4, yards: 400)), userId: '',
                    ));
                    _players[mainPlayerId] = _players[mainPlayerId]!.copyWith(totalScore: int.parse(_scoreController.text));
                    final game = Game(
                      id: '',
                      date: _dateController.text,
                      title: _titleController.text,
                      courseId: course.id.isEmpty ? courseName : course.id,
                      teamId: _teamNameController.text.isNotEmpty ? _teamNameController.text : null,
                      tournamentId: null,
                      gameType: _gameType,
                      skinsMode: false,
                      skinsBet: 0,
                      players: _players,
                      teamStats: _players.length > 1 ? {'totalScore': _players.values.map((p) => p.totalScore).reduce((a, b) => a + b)} : null,
                      useHandicap: _useHandicap,
                    );
                    await widget.firestoreService.addGame(game);
                    widget.onSave();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Game'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}