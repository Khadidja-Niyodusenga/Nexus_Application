import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class TrackProgressScreen extends StatelessWidget {
  const TrackProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to see progress")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Progress Tracking',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('progress')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading progress"));
          }

          // Handle empty or missing progress document
          Map<String, dynamic> sdgs = {};
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // Initialize default SDGs map for display
          } else {
            // Extract document data
            final docData =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;
            // Initialize all 17 SDGs with defaults if not present
            for (var i = 1; i <= 17; i++) {
              final key = i.toString();
              sdgs[key] =
                  docData['sdgs'] != null && docData['sdgs'][key] != null
                      ? Map<String, dynamic>.from(docData['sdgs'][key])
                      : {
                          'percentage': 0,
                          'opened': false,
                          'readMinutes': 0,
                          'responded': false,
                          'responseQuality': 'none',
                        };
            }
          }

          // Generate allSdgs for display
          final allSdgs = List.generate(17, (index) {
            final id = (index + 1).toString();
            final sdgData = sdgs[id] ?? {};

            final rawPercentage = sdgData['percentage'] ?? 0;
            double percent = 0.0;
            if (rawPercentage is int) {
              percent = rawPercentage.toDouble() / 100;
            } else if (rawPercentage is double) {
              percent = rawPercentage / 100;
            } else if (rawPercentage is String) {
              percent = double.tryParse(rawPercentage) ?? 0.0;
            }

            return {
              'title': 'SDG $id',
              'percent': percent,
              'percentage': rawPercentage,
            };
          });

          // Calculate average
          double total = allSdgs.fold(
            0.0,
            (sum, e) => sum + (e['percent'] as double),
          );
          double average = allSdgs.isNotEmpty ? (total / allSdgs.length) : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Learning Progress',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Chart for SDG progress
                // SizedBox(
                //   height: 200,
                //   child: CustomChart(allSdgs: allSdgs),
                // ),
                const SizedBox(height: 16),
                // Progress bars
                Column(
                  children: allSdgs.map((entry) {
                    final percent = entry['percent'] as double;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              entry['title'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percent,
                              color: percent > 0 ? Colors.green : Colors.grey,
                              backgroundColor: Colors.grey.shade300,
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${(percent * 100).toInt()}%'),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                Text(
                  "You're ${(average * 100).toInt()}% on your journey",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Keep learning, keep growing — the world needs your light.",
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
          );
        },
      ),
    );
  }
}

// Custom Chart Widget (Placeholder - replace with Chart.js or similar)
class CustomChart extends StatelessWidget {
  final List<Map<String, dynamic>> allSdgs;

  const CustomChart({super.key, required this.allSdgs});

  @override
  Widget build(BuildContext context) {
    // Placeholder for Chart.js integration
    // Use the chart configuration provided below
    return Container(
      height: 200,
      color: Colors.grey[200],
      child: const Center(
        child: Text(
          "Chart placeholder - Implement Chart.js here",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }
}
