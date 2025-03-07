import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/course.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  UploadScreenState createState() => UploadScreenState();
}

class UploadScreenState extends State<UploadScreen> {
  String? _statusMessage;

  Future<void> _uploadGolfCourses() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _statusMessage = 'No file selected');
        return;
      }
      final user = FirebaseAuth.instance.currentUser!;

      final file = result.files.first;
      final jsonString = utf8.decode(file.bytes!);
      final jsonData = jsonDecode(jsonString) as List<dynamic>;

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final existingCourses = await firestore.collection('courses').get();
      final existingNames = existingCourses.docs.map((doc) => doc['name'] as String).toSet();

      int addedCount = 0;
      for (var courseData in jsonData) {
        final courseMap = courseData as Map<String, dynamic>;
        final courseName = courseMap['name'] as String;

        if (existingNames.contains(courseName)) continue;

        final docRef = firestore.collection('courses').doc();
        final course = Course(
          id: docRef.id,
          name: courseName,
          status: courseMap['status'] as String,
          slopeRating: courseMap['slope_rating'] as int,
          yardage: courseMap['yardage'] as int,
          totalPar: courseMap['scorecard']['total_par'] as int,
          holes: (courseMap['scorecard']['holes'] as List<dynamic>)
              .map((h) => Hole.fromMap(h as Map<String, dynamic>))
              .toList(),
          userId: user.uid,
        );
        batch.set(docRef, course.toMap());
        addedCount++;
      }

      await batch.commit();
      setState(() => _statusMessage = 'Uploaded $addedCount courses successfully');
    } catch (e) {
      setState(() => _statusMessage = 'Error uploading courses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Golf Courses')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _uploadGolfCourses,
              child: const Text('Select JSON File to Upload'),
            ),
            const SizedBox(height: 20),
            if (_statusMessage != null)
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.contains('Error') ? Colors.red : Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}