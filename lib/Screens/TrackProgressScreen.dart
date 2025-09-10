// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

// class TrackProgressScreen extends StatelessWidget {
//   const TrackProgressScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final Map<String, double> sdgProgress = {
//       'SDG 1': 0.6,
//       'SDG 2': 0.2,
//       'SDG 3': 0.0,
//       'SDG 4': 0.0,
//       'SDG 5': 0.0,
//       'SDG 6': 0.0,
//       'SDG 7': 0.0,
//       'SDG 8': 0.0,
//       'SDG 9': 0.0,
//       'SDG 10': 0.0,
//       'SDG 11': 0.0,
//       'SDG 12': 0.0,
//       'SDG 13': 0.0,
//       'SDG 14': 0.0,
//       'SDG 15': 0.0,
//       'SDG 16': 0.0,
//       'SDG 17': 0.0,
//     };

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Progress tracking',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.grey[300],
//         foregroundColor: Colors.black,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Your learning Progress',
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Column(
//               children: sdgProgress.entries.map((entry) {
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 6),
//                   child: Row(
//                     children: [
//                       SizedBox(
//                         width: 60,
//                         child: Text(
//                           entry.key,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: LinearProgressIndicator(
//                           value: entry.value,
//                           color: Colors.green,
//                           backgroundColor: Colors.grey.shade300,
//                           minHeight: 10,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Text('${(entry.value * 100).toInt()}%'),
//                     ],
//                   ),
//                 );
//               }).toList(),
//             ),
//             const SizedBox(height: 32),
//             const Text(
//               "You're 25% on your journey",
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//             const SizedBox(height: 12),
//             const Text(
//               "Keep learning, keep growing the world needs your light.",
//               style: TextStyle(
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 12),
//             const Text(
//               "You're not just aware of SDGs — you're becoming a force behind them.",
//               style: TextStyle(
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('progress')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No progress recorded yet."),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No progress recorded yet."),
            );
          }

//
          // ✅ Extract document data
          final docData =
              snapshot.data!.docs.first.data() as Map<String, dynamic>;

          // ✅ Convert separate SDG fields (sdgs.1, sdgs.2, ...) into a map
          final Map<String, dynamic> sdgs = {};
          for (var i = 1; i <= 17; i++) {
            final key = 'sdgs.$i';
            if (docData.containsKey(key)) {
              sdgs[i.toString()] = docData[key];
            }
          }

          print('SDGs map after conversion: $sdgs');

// 2️⃣ Extract the userId string
          final String userId = docData['userId'] ?? '';

// 🔹 Generate allSdgs
          final allSdgs = List.generate(17, (index) {
            final id = (index + 1).toString();
            final sdgData = sdgs[id] != null && sdgs[id] is Map
                ? Map<String, dynamic>.from(sdgs[id] as Map)
                : <String, dynamic>{};

            final rawPercentage = sdgData['percentage'] ?? 0;
            double percent = 0.0;

            if (rawPercentage is int) {
              percent = rawPercentage.toDouble() / 100;
            } else if (rawPercentage is double) {
              percent = rawPercentage / 100;
            } else if (rawPercentage is String) {
              percent = double.tryParse(rawPercentage) != null
                  ? double.parse(rawPercentage) / 100
                  : 0.0;
            }

            return {
              'title': 'SDG $id',
              'percent': percent,
              'percentage': rawPercentage,
            };
          });

// 🔹 Print allSdgs to debug
          print('All SDGs: $allSdgs');

// ✅ Calculate average
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
                  'Your learning Progress',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
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
                          Text('${entry['percentage']}%'),
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
