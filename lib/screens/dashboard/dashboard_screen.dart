import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart'; // Import AuthService
import '../add_game_form.dart';
import '../game_list/game_list.dart';
import 'header.dart';

class GorlfDashboard extends StatefulWidget {
  const GorlfDashboard({super.key});

  @override
  GorlfDashboardState createState() => GorlfDashboardState();
}

class GorlfDashboardState extends State<GorlfDashboard> {
  late Future<List<Course>> _golfCoursesFuture;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService(); // Add AuthService instance

  @override
  void initState() {
    super.initState();
    _golfCoursesFuture = _firestoreService.getCourses('');
  }

  void _addGame() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: AddGameForm(
          golfCoursesFuture: _golfCoursesFuture,
          firestoreService: _firestoreService,
          onSave: () {
            Navigator.pop(context);
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/auth');
      });
      return const SizedBox();
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            DashboardHeader(
              onAddGame: _addGame,
              firestoreService: _firestoreService,
              authService: _authService, // Pass authService
            ),
            Expanded(
              child: GameList(
                golfCoursesFuture: _golfCoursesFuture,
                firestoreService: _firestoreService,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/upload');
                },
                child: const Text('Go to Upload Screen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}