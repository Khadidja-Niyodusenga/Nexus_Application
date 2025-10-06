import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'DetailsScreen.dart'; // import your DetailsScreen
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'LoginScreen.dart';
import 'Services/user_service.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final int _currentIndex = 1;
  final Set<int> openedSDGs = {};
  final int totalSDGs = 17;

  final List<String> bottomLabels = ["Home", "Learn", "Updates", "Profile"];

  final List<String> sdgImages = [
    "assets/sdg1.jpeg",
    "assets/sdg2.jpeg",
    "assets/sdg3.jpeg",
    "assets/sdg4.png",
    "assets/sdg5.png",
    "assets/sdg6.png",
    "assets/sdg7.png",
    "assets/sdg8.png",
    "assets/sdg9.png",
    "assets/sdg10.png",
    "assets/sdg11.png",
    "assets/sdg12.png",
    "assets/sdg13.png",
    "assets/sdg14.png",
    "assets/sdg15.png",
    "assets/sdg16.png",
    "assets/sdg17.png",
  ];
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<firebase_auth.User?>(
        stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          final user = authSnapshot.data;

          if (user == null) {
            // User logged out
            return const Scaffold(
              body: Center(
                child: Text("Please log in to see your learning progress."),
              ),
            );
          }

          // User is logged in — fetch their progress from Firestore
          return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('progress')
                  .where('userId', isEqualTo: user.uid)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                double average = 0.0;

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final data =
                      snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  final sdgs = <String, dynamic>{};
                  for (var i = 1; i <= 17; i++) {
                    final key = i.toString();
                    if (data.containsKey(key)) {
                      sdgs[i.toString()] = data[key];
                    }
                  }

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

                    return percent;
                  });

                  final total = allSdgs.fold(0.0, (sum, e) => sum + e);
                  //   average = allSdgs.isNotEmpty ? (total / allSdgs.length) : 0.0;
                  // }

                  // int percentage = (average * 100).toInt();

                  average = allSdgs.isNotEmpty
                      ? (total / allSdgs.length).clamp(0.0, 1.0)
                      : 0.0;
                }
                int percentage = (average * 100).round();

                return Scaffold(
                  appBar: AppBar(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DashboardScreen()),
                        );
                      },
                    ),
                    title: const Text(
                      "Learn through 17 SDGs",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 35,
                              height: 35,
                              child: CircularProgressIndicator(
                                value: average, // ✅ use Firestore percentage
                                strokeWidth: 3,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.green),
                                backgroundColor: Colors.white,
                              ),
                            ),
                            Text(
                              "",
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      itemCount: sdgImages.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () async {
                            final user =
                                firebase_auth.FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                              );
                              return;
                            }
                            await UserService.updateLastActive(user.uid);
                            final firestore = FirebaseFirestore.instance;
                            final sdgId = (index + 1).toString();

                            try {
                              // Query progress document for user
                              final progressQuery = await firestore
                                  .collection('progress')
                                  .where('userId', isEqualTo: user.uid)
                                  .limit(1)
                                  .get();
                              DocumentReference userDoc;
                              if (progressQuery.docs.isEmpty) {
                                userDoc =
                                    firestore.collection('progress').doc();
                              } else {
                                userDoc = progressQuery.docs.first.reference;
                              }

                              await firestore.runTransaction((txn) async {
                                final userSnap = await txn.get(userDoc);
                                final userData = userSnap.exists
                                    ? userSnap.data() as Map<String, dynamic>
                                    : {};
                                final sdgsMap = Map<String, dynamic>.from(
                                    userData['sdgs'] ?? {});

                                final sdgData = Map<String, dynamic>.from(
                                    sdgsMap[sdgId] ?? {});

                                bool hasAccessed = sdgData['opened'] == true;

                                if (!hasAccessed) {
                                  sdgData['opened'] = true;
                                  sdgData['readCounted'] = false;
                                  sdgData['readMinutes'] = 0;
                                  sdgData['responded'] = false;
                                  sdgData['responseQuality'] = 'none';
                                  sdgData['percentage'] = 0;
                                  sdgData['updatedAt'] =
                                      FieldValue.serverTimestamp();

                                  // Increment lessons accessCount
                                  final lessonQuery = await firestore
                                      .collection('lessons')
                                      .where('sdgId', isEqualTo: sdgId)
                                      .where('status', isEqualTo: 'Published')
                                      .limit(1)
                                      .get();
                                  if (lessonQuery.docs.isNotEmpty) {
                                    final lessonRef =
                                        lessonQuery.docs.first.reference;
                                    txn.update(lessonRef, {
                                      'accessCount': FieldValue.increment(1)
                                    });
                                  } else {
                                    print('No lesson found for sdgId: $sdgId');
                                  }
                                } else {
                                  // Update existing sdgData
                                  sdgData['opened'] = sdgData['opened'] ?? true;
                                  sdgData['readCounted'] =
                                      sdgData['readCounted'] ?? false;
                                  sdgData['readMinutes'] =
                                      sdgData['readMinutes'] ?? 0;
                                  sdgData['responded'] =
                                      sdgData['responded'] ?? false;
                                  sdgData['responseQuality'] =
                                      sdgData['responseQuality'] ?? 'none';
                                  sdgData['percentage'] =
                                      sdgData['percentage'] ?? 0;
                                  sdgData['updatedAt'] =
                                      FieldValue.serverTimestamp();
                                }

                                sdgsMap[sdgId] = sdgData;

                                txn.set(
                                  userDoc,
                                  {
                                    'userId': user.uid,
                                    'sdgs': sdgsMap,
                                  },
                                  SetOptions(merge: true),
                                );
                              });

                              setState(() {
                                openedSDGs.add(index);
                              });

                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DetailsScreen(sdgNumber: index + 1),
                                ),
                              );
                            } catch (e) {
                              print('Error in LearnScreen onTap: $e');
                              if (!mounted) return;
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Error"),
                                  content: const Text(
                                      "Failed to access SDG. Please try again."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("OK"),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: AssetImage(sdgImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              });
        });
  }
}
