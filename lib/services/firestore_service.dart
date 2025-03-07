import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game.dart';
import '../models/course.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Game>> getGames() {
    final user = _auth.currentUser!;
    return _firestore.collection('users').doc(user.uid).collection('games').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Game.fromSnapshot(doc)).toList();
    });
  }

  Future<Game> getGame(String gameId) async {
    final user = _auth.currentUser!;
    final doc = await _firestore.collection('users').doc(user.uid).collection('games').doc(gameId).get();
    return Game.fromSnapshot(doc);
  }

  Future<List<Course>> getCourses(String courseName) async {
    QuerySnapshot<Map<String, dynamic>> snapshot;
    if (courseName.isEmpty) {
      snapshot = await _firestore.collection('courses').get();
    } else {
      snapshot = await _firestore.collection('courses').where('name', isEqualTo: courseName).get();
    }
    return snapshot.docs.map((doc) => Course.fromMap(doc.data())).toList();
  }

  Future<List<String>> getGameTitles() async {
    final user = _auth.currentUser!;
    final snapshot = await _firestore.collection('users').doc(user.uid).collection('games').get();
    return snapshot.docs.map((doc) => doc['title'] as String).toSet().toList();
  }

  Future<List<String>> getTeamNames() async {
    final user = _auth.currentUser!;
    final snapshot = await _firestore.collection('users').doc(user.uid).collection('teams').get();
    return snapshot.docs.map((doc) => doc['name'] as String).toSet().toList();
  }

  Future<List<String>> getPlayerNames() async {
    final user = _auth.currentUser!;
    final snapshot = await _firestore.collection('users').doc(user.uid).collection('players').get();
    return snapshot.docs.map((doc) => doc['name'] as String).toSet().toList();
  }

  Future<void> addTeam(String teamName) async {
    final user = _auth.currentUser!;
    await _firestore.collection('users').doc(user.uid).collection('teams').doc().set({'name': teamName});
  }

  Future<void> updateGame(String gameId, Map<String, dynamic> data) async {
    final user = _auth.currentUser!;
    await _firestore.collection('users').doc(user.uid).collection('games').doc(gameId).update(data);
  }

  Future<void> addGame(Game game) async {
    final user = _auth.currentUser!;
    final docRef = _firestore.collection('users').doc(user.uid).collection('games').doc();
    final gameData = game.toMap()..['id'] = docRef.id;
    await docRef.set(gameData);
    if (game.teamId != null && game.teamId!.isNotEmpty) {
      await addTeam(game.teamId!);
    }
  }

  Future<void> deleteGame(String gameId) async {
    final user = _auth.currentUser!;
    await _firestore.collection('users').doc(user.uid).collection('games').doc(gameId).delete();
  }
}

Future<void> addCourse(Course course) async {
  await FirebaseFirestore.instance.collection('courses').doc(course.id).set(course.toMap());
}