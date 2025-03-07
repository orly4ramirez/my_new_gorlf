import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/game.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';

class EditPopup {
  static Future<void> show(
      BuildContext context,
      Game game,
      String field,
      String initialValue,
      FirestoreService firestoreService, {
        bool isCourse = false,
        Future<List<Course>>? golfCoursesFuture,
      }) async {
    final controller = TextEditingController(text: initialValue);
    String? newValue;

    final title = field == 'Score' ? 'What is your score' : field == 'Date' ? 'Play Date' : field == 'Course' ? 'Where are you playing' : 'Describe this game';

    if (field == 'Score') {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Score', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                newValue = controller.text;
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (result != true || newValue == null || newValue == initialValue) return;
      final newScore = int.tryParse(newValue!);
      if (newScore != null) {
        await firestoreService.updateGame(game.id, {
          'players.${game.players.keys.first}.totalScore': newScore,
        });
      }
    } else if (field == 'Date') {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.parse(initialValue),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        newValue = DateFormat('yyyy-MM-dd').format(picked);
        if (newValue != initialValue) await firestoreService.updateGame(game.id, {'date': newValue});
      }
    } else {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: isCourse && golfCoursesFuture != null
              ? FutureBuilder<List<Course>>(
            future: golfCoursesFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final courses = snapshot.data!;
              return Autocomplete<String>(
                optionsBuilder: (textEditingValue) => courses
                    .map((c) => c.name)
                    .where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase())),
                onSelected: (selection) => controller.text = selection,
                fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) => TextField(
                  controller: textController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Course', border: OutlineInputBorder()),
                ),
              );
            },
          )
              : TextField(
            controller: controller,
            decoration: InputDecoration(labelText: field, border: const OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                newValue = controller.text;
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (result != true || newValue == null || newValue == initialValue) return;
      await firestoreService.updateGame(game.id, {field.toLowerCase(): newValue});
    }
  }
}