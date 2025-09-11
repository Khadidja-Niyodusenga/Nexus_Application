import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
// import 'DetailsSdgs.dart'; // Uncomment when you have this screen
import 'package:marquee/marquee.dart';
import 'DetailsScreen.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final int _currentIndex = 1;

  // Track opened SDGs using a Set (prevents duplicates)
  final Set<int> openedSDGs = {};
  final int totalSDGs = 17; // Learn menu is index 1

  final List<String> bottomLabels = ["Home", "Learn", "Updates", "Profile"];

  final List<int> sdgNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 13, 17];
  final List<String> sdgImages = [
    "assets/sdg1.jpeg",
    "assets/sdg2.jpeg",
    "assets/sdg3.jpeg",
    "assets/sdg4.png",
    "assets/sdg5.png",
    "assets/sdg6.png",
    "assets/sdg7.png",
    "assets/sdg8.png",
    "assets/sdg13.png",
    "assets/sdg17.png",
  ];

  @override
  Widget build(BuildContext context) {
    int learnedSDGs = openedSDGs.length; // dynamic count
    double progress = learnedSDGs / totalSDGs; // dynamic progress

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // remove default back arrow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          },
        ),
        title: SizedBox(
          height: 30, // control marquee height
          child: Marquee(
            text:
                "Learn About SDGs Rwanda Focus on \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ),
        backgroundColor: Colors.grey[300],
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 35,
                  height: 35,
                  // child: CircularProgressIndicator(
                  //   value: progress, // dynamic progress
                  //   strokeWidth: 3,
                  //   valueColor:
                  //       const AlwaysStoppedAnimation<Color>(Colors.green),
                  //   backgroundColor: Colors.white,
                  // ),
                ),
                Text(
                  "$learnedSDGs", // number of SDGs opened
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
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
            final List<int> sdgOrder = [1, 2, 3, 4, 5, 6, 7, 8, 13, 17];

            final sdgNumber = sdgOrder[index]; // ✅ Use mapping
            return GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailsScreen(sdgNumber: sdgNumber),
                  ),
                );

                setState(() {
                  openedSDGs.add(sdgNumber); // ✅ Mark by SDG number
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
