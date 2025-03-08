import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game.dart';
import '../models/course.dart';
import '../models/game_player.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  Stream<List<Game>> getGames() {
    return _db.collection('users').doc(userId).collection('games').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add ID to the data map
        return Game.fromMap(data);
      }).toList(),
    );
  }

  Future<Game> getGame(String gameId) async {
    final doc = await _db.collection('users').doc(userId).collection('games').doc(gameId).get();
    final data = doc.data()!;
    data['id'] = doc.id; // Add ID to the data map
    return Game.fromMap(data);
  }

  Stream<Game> streamGame(String gameId) {
    return _db.collection('users').doc(userId).collection('games').doc(gameId).snapshots().map(
          (snapshot) {
        final data = snapshot.data()!;
        data['id'] = snapshot.id; // Add ID to the data map
        return Game.fromMap(data);
      },
    );
  }

  Future<void> addGame(Game game) async {
    final docRef = _db.collection('users').doc(userId).collection('games').doc();
    final gameWithId = game.copyWith(id: docRef.id);
    await docRef.set(gameWithId.toMap());
  }

  Future<void> updateGame(String gameId, Map<String, dynamic> updates) async {
    await _db.collection('users').doc(userId).collection('games').doc(gameId).update(updates);
  }

  Future<void> deleteGame(String gameId) async {
    await _db.collection('users').doc(userId).collection('games').doc(gameId).delete();
  }

  Future<List<Course>> getCourses(String status) async {
    QuerySnapshot snapshot;
    if (status.isEmpty) {
      snapshot = await _db.collection('users').doc(userId).collection('courses').get();
    } else {
      snapshot = await _db.collection('users').doc(userId).collection('courses').where('status', isEqualTo: status).get();
    }
    return snapshot.docs.map((doc) => Course.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<void> addCourse(Course course) async {
    final docRef = _db.collection('users').doc(userId).collection('courses').doc();
    final courseWithId = course.copyWith(id: docRef.id);
    await docRef.set(courseWithId.toMap());
  }
}