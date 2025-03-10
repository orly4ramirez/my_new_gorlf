import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart'; // Adjust path if needed

Future<void> main() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final db = FirebaseFirestore.instance;

    // Backup all data to one file
    final backup = <String, dynamic>{};

    // Export /users (with subcollections)
    print('Exporting /users...');
    final usersSnapshot = await db.collection('users').get();
    for (var userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;
      final games = await db.collection('users').doc(userId).collection('games').get();
      final courses = await db.collection('users').doc(userId).collection('courses').get();
      backup['users/$userId'] = {
        ...userDoc.data(),
        'games': {for (var g in games.docs) g.id: g.data()},
        'courses': {for (var c in courses.docs) c.id: c.data()},
      };
    }

    // Export /courses
    print('Exporting /courses...');
    final coursesSnapshot = await db.collection('courses').get();
    backup['courses'] = {for (var doc in coursesSnapshot.docs) doc.id: doc.data()};

    // Export /golfCourses (optional)
    print('Exporting /golfCourses...');
    try {
      final golfCoursesSnapshot = await db.collection('golfCourses').get();
      backup['golfCourses'] = {for (var doc in golfCoursesSnapshot.docs) doc.id: doc.data()};
    } catch (e) {
      print('No golfCourses found, skipping: $e');
    }

    // Save to file
    final timestamp = DateTime.now().toIso8601String().split('.').first.replaceAll(':', '-');
    File('backup-$timestamp.json').writeAsStringSync(jsonEncode(backup));
    print('Backup saved to backup-$timestamp.json');
  } catch (e) {
    print('Error during backup: $e');
  }
}