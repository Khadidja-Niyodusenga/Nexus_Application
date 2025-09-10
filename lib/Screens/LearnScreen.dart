import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'DetailsScreen.dart'; // import your DetailsScreen
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

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
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('progress')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            double average = 0.0;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;

              final sdgs = <String, dynamic>{};
              // Loop through SDGs 1-17
              for (var i = 1; i <= 17; i++) {
                final key = 'sdgs.$i';
                if (data.containsKey(key)) {
                  sdgs[i.toString()] = data[key];
                }
              }

              // Calculate average
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
              average = allSdgs.isNotEmpty ? (total / allSdgs.length) : 0.0;
            }

            // Now rebuild your original Scaffold with the updated `average`
            int percentage = (average * 100).toInt();

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
                          "$percentage%", // show percentage
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailsScreen(
                              sdgNumber: index + 1,
                            ),
                          ),
                        );

                        setState(() {
                          openedSDGs.add(index);
                        });
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
          },
        );
      },
    );
  }
}
