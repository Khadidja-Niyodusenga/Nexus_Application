import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'DetailsScreen.dart'; // import your DetailsScreen

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
    int learnedSDGs = openedSDGs.length;
    double progress = learnedSDGs / totalSDGs;

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
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
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
                    value: progress,
                    strokeWidth: 3,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                    backgroundColor: Colors.white,
                  ),
                ),
                Text(
                  "$learnedSDGs",
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
                      sdgNumber: index + 1, // only pass SDG number now ✅
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
  }
}
