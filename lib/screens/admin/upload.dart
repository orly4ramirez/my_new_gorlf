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
      final jsonData = jsonDecode(jsonString);

      if (jsonData is! List) {
        setState(() => _statusMessage = 'Invalid JSON: Must be a list');
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final existingCourses = await firestore.collection('courses').get();
      final existingNames = existingCourses.docs.map((doc) => doc['name'] as String).toSet();

      // Counters for tracking
      int totalCourses = jsonData.length; // Total courses in the JSON file
      int addedCount = 0; // Successfully added courses
      int skippedCount = 0; // Skipped courses (duplicates or invalid)

      for (var courseData in jsonData) {
        if (courseData is! Map<String, dynamic>) {
          print('Skipping invalid course data: $courseData');
          skippedCount++;
          continue;
        }
        final courseMap = courseData;
        final courseName = courseMap['name'] as String?;

        if (courseName == null || existingNames.contains(courseName)) {
          print('Skipping duplicate or invalid course: $courseName');
          skippedCount++;
          continue;
        }

        try {
          final docRef = firestore.collection('courses').doc();
          final course = Course(
            id: docRef.id,
            name: courseName,
            status: courseMap['status'] as String? ?? 'Unknown',
            slopeRating: courseMap['slope_rating'] as int? ?? 113,
            yardage: courseMap['yardage'] as int? ?? 0,
            totalPar: (courseMap['scorecard'] as Map<String, dynamic>?)?['total_par'] as int? ?? 72,
            holes: (courseMap['scorecard'] as Map<String, dynamic>?)?['holes'] is List
                ? (courseMap['scorecard']['holes'] as List<dynamic>)
                .map((h) => Hole.fromMap(h as Map<String, dynamic>))
                .toList()
                : [],
            userId: user.uid,
          );
          batch.set(docRef, course.toMap());
          addedCount++;
          existingNames.add(courseName); // Prevent duplicates within batch
        } catch (e) {
          print('Error processing course $courseName: $e');
          skippedCount++;
        }
      }

      if (addedCount == 0) {
        setState(() => _statusMessage = 'No new courses to upload. '
            'Processed: $totalCourses, Added: $addedCount, Skipped: $skippedCount');
        return;
      }

      await batch.commit();
      setState(() => _statusMessage = 'Upload complete. '
          'Processed: $totalCourses, Added: $addedCount, Skipped: $skippedCount');
    } catch (e) {
      print('Upload Error: $e');
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
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}