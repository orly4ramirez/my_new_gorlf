import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import 'stats_card.dart';

class DashboardHeader extends StatelessWidget {
  final VoidCallback onAddGame;
  final FirestoreService firestoreService;

  const DashboardHeader({
    super.key,
    required this.onAddGame,
    required this.firestoreService,
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
              Row(
                children: [
                  const Text(
                    'G🏐rlf',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle, size: 28, color: Colors.blueAccent),
                            tooltip: 'Add Game',
                            onPressed: onAddGame,
                          ),
                          const SizedBox(width: 12),
                          StatsCard(firestoreService: firestoreService),
                        ],
                      ),
                      Text('Track Your Game $playerName', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 24, color: Colors.grey),
                tooltip: 'Logout',
                onPressed: () async => await FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}