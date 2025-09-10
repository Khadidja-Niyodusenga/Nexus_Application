import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class TrackProgressScreen extends StatelessWidget {
  const TrackProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> sdgProgress = {
      'SDG 1': 0.6,
      'SDG 2': 0.2,
      'SDG 3': 0.0,
      'SDG 4': 0.0,
      'SDG 5': 0.0,
      'SDG 6': 0.0,
      'SDG 7': 0.0,
      'SDG 8': 0.0,
      'SDG 9': 0.0,
      'SDG 10': 0.0,
      'SDG 11': 0.0,
      'SDG 12': 0.0,
      'SDG 13': 0.0,
      'SDG 14': 0.0,
      'SDG 15': 0.0,
      'SDG 16': 0.0,
      'SDG 17': 0.0,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Progress tracking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey[300],
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your learning Progress',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: sdgProgress.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: entry.value,
                          color: Colors.green,
                          backgroundColor: Colors.grey.shade300,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(entry.value * 100).toInt()}%'),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const Text(
              "You're 25% on your journey",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Keep learning, keep growing the world needs your light.",
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "You're not just aware of SDGs — you're becoming a force behind them.",
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
