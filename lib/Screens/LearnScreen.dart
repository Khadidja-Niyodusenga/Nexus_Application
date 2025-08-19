import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'DetailsScreen.dart'; // import your DetailsScreenm

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  int _currentIndex = 1;
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

  // Example SDG titles and descriptions (replace with full SDG info)
  final List<String> sdgTitles = [
    "SDG 1: No Poverty",
    "SDG 2: Zero Hunger",
    "SDG 3: Good Health and Well-being",
    "SDG 4: Quality Education",
    "SDG 5: Gender Equality",
    "SDG 6: Clean Water and Sanitation",
    "SDG 7: Affordable and Clean Energy",
    "SDG 8: Decent Work and Economic Growth",
    "SDG 9: Industry, Innovation and Infrastructure",
    "SDG 10: Reduced Inequalities",
    "SDG 11: Sustainable Cities and Communities",
    "SDG 12: Responsible Consumption and Production",
    "SDG 13: Climate Action",
    "SDG 14: Life Below Water",
    "SDG 15: Life on Land",
    "SDG 16: Peace, Justice and Strong Institutions",
    "SDG 17: Partnerships for the Goals",
  ];

  final List<String> sdgDescriptions = [
    "End poverty in all its forms everywhere.",
    "End hunger, achieve food security and improved nutrition.",
    "Ensure healthy lives and promote well-being for all.",
    "Ensure inclusive and equitable quality education.",
    "Achieve gender equality and empower all women and girls.",
    "Ensure availability and sustainable management of water.",
    "Ensure access to affordable, reliable, sustainable energy.",
    "Promote sustained, inclusive economic growth and decent work.",
    "Build resilient infrastructure, promote inclusive industrialization.",
    "Reduce inequality within and among countries.",
    "Make cities inclusive, safe, resilient and sustainable.",
    "Ensure sustainable consumption and production patterns.",
    "Take urgent action to combat climate change and its impacts.",
    "Conserve and sustainably use the oceans, seas and marine resources.",
    "Protect, restore and promote sustainable use of terrestrial ecosystems.",
    "Promote peaceful and inclusive societies for sustainable development.",
    "Strengthen the means of implementation and revitalize the global partnership.",
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
                // Navigate to our new DetailsScreenm
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailsScreen(
                      sdgNumber: index + 1, // 1-based SDG number
                      sdgTitle: sdgTitles[index], // Title of the SDG
                      sdgDescription:
                          sdgDescriptions[index], // Description of the SDG
                    ),
                  ),
                );

                // Mark SDG as opened
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
