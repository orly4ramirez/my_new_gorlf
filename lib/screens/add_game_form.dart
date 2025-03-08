import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/game.dart';
import '../../models/game_player.dart';
import '../../services/firestore_service.dart';
import '../../models/course.dart';

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
  String? _selectedCourseName;
  DateTime _selectedDate = DateTime.now();
  double? _slopeRating;
  final _slopeController = TextEditingController();
  String? _gameDescription;
  int? _defaultScore;
  List<String> _previousDescriptions = [];
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadPreviousDescriptions();
  }

  Future<void> _loadCourses() async {
    _courses = await widget.golfCoursesFuture;
    setState(() {});
  }

  Future<void> _loadPreviousDescriptions() async {
    final games = await widget.firestoreService.getGames().first;
    _previousDescriptions = games.map((g) => g.title).toSet().toList();
    setState(() {});
  }

  void _onCourseSelected(String value) {
    final course = _courses.firstWhere(
          (c) => c.name == value,
      orElse: () => Course(
        id: '',
        name: value,
        userId: FirebaseAuth.instance.currentUser!.uid,
        status: 'Unknown',
        slopeRating: 113,
        yardage: 0,
        totalPar: 72,
        holes: List.generate(18, (index) => Hole(holeNumber: index + 1, par: 4, yards: 400)), // Default 18 holes
      ),
    );
    setState(() {
      _selectedCourseName = value;
      _slopeRating = course.slopeRating.toDouble();
      _slopeController.text = _slopeRating.toString();
      if (!_courses.any((c) => c.name == value)) {
        widget.firestoreService.addCourse(course);
        _courses.add(course);
      }
    });
  }

  Future<void> _saveGame() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser!;
      final playerId = user.uid;
      final players = {
        playerId: GamePlayer(
          playerId: playerId,
          scores: [],
          totalScore: _defaultScore ?? 0,
          girPercentage: 0.0,
          holeInOneCount: 0,
          handicapAdjustment: 0.0,
        ),
      };
      final game = Game(
        id: '',
        date: _selectedDate.toString().split(' ')[0],
        title: _gameDescription ?? '',
        courseId: _selectedCourseName!,
        gameType: 'stroke_gross',
        skinsMode: false,
        skinsBet: 0,
        players: players,
        useHandicap: true,
      );

      try {
        await widget.firestoreService.addGame(game);
        widget.onSave();
      } catch (e) {
        print('Error saving game: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save game: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Game', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return _courses.map((c) => c.name);
                return _courses
                    .map((c) => c.name)
                    .where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: _onCourseSelected,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Golf Course Name *',
                    labelStyle: TextStyle(fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _selectedCourseName = value,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a course' : null,
                );
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Date *',
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                border: OutlineInputBorder(),
              ),
              initialValue: _selectedDate.toString().split(' ')[0],
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              readOnly: true,
              validator: (value) => value!.isEmpty ? 'Please select a date' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _slopeController,
              decoration: const InputDecoration(
                labelText: 'Slope Rating',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _slopeRating = double.tryParse(value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Score (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _defaultScore = int.tryParse(value),
            ),
            const SizedBox(height: 12),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                return _previousDescriptions.where((desc) => desc.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (value) => _gameDescription = value,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Game Description',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _gameDescription = value,
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(onPressed: _saveGame, child: const Text('Save Game')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}