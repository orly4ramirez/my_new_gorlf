import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'stats_card.dart';

class DashboardHeader extends StatelessWidget {
  final VoidCallback onAddGame;
  final FirestoreService firestoreService;
  final AuthService authService;

  const DashboardHeader({
    super.key,
    required this.onAddGame,
    required this.firestoreService,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final playerName = user.displayName ?? user.email!.split('@')[0];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('G🏐rlf', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle, size: 28, color: Colors.blueAccent),
                        tooltip: 'Add Game',
                        onPressed: onAddGame,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      StatsCard(firestoreService: firestoreService),
                    ],
                  ),
                  Text('Track Your Game $playerName', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 24, color: Colors.grey),
                tooltip: 'Logout',
                onPressed: () async {
                  try {
                    await authService.signOut();
                    if (context.mounted) Navigator.pushReplacementNamed(context, '/auth');
                  } catch (e) {
                    print('Logout Error: $e');
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}