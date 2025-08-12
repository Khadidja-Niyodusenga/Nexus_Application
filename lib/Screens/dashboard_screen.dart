import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final PageController _pageController = PageController();
  int _pageViewIndex = 0; // For the PageView inside Home content

  final List<String> bottomLabels = ["Home", "Learn", "Updates", "Profile"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 9.0),
          child: InkWell(
            onTap: () {
              showMenu(
                context: context,
                position: const RelativeRect.fromLTRB(0, 80, 0, 0),
                items: [
                  const PopupMenuItem(
                    value: "track",
                    child: Text("Track Progress"),
                  ),
                  const PopupMenuItem(
                    value: "feedback",
                    child: Text("User Feedback"),
                  ),
                  const PopupMenuItem(
                    value: "notif",
                    child: Text("Notification"),
                  ),
                  const PopupMenuItem(
                    value: "signout",
                    child: Text("Sign Out"),
                  ),
                ],
              ).then((value) {
                if (value != null) {
                  // Handle menu click
                  if (value == "signout") {
                    // Sign out code here
                  } else if (value == "track") {
                    // Navigate to track progress page
                  }
                }
              });
            },
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.menu,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
        ),
        title: Transform.translate(
          offset: const Offset(-13, 1),
          child: const Text(
            "NEXUS APP",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        actions: const [
          Icon(Icons.notifications, color: Colors.blue),
          SizedBox(width: 10),
          Icon(Icons.chat_bubble, color: Colors.blue),
          SizedBox(width: 10),
        ],
      ),
      body: _currentIndex == 0
          ? homeContentWidget()
          : otherContentWidget(_currentIndex),
      bottomNavigationBar: Container(
        color: const Color(0xFF3B9DD2), // Blue background
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(bottomLabels.length, (index) {
            final isSelected = _currentIndex == index;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: isSelected
                        ? const Color(0xFF58C958)
                        : Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _currentIndex = index;
                      if (_currentIndex == 0 && _pageController.hasClients) {
                        // Reset internal pageview index when returning Home
                        _pageController.jumpToPage(0);
                        _pageViewIndex = 0;
                      }
                    });
                  },
                  child: Text(
                    bottomLabels[index],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget homeContentWidget() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            children: [
              Image.asset(
                'assets/welcome2.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 250,
              ),
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Welcome to Nexus App ",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontFamily: 'Times New Roman',
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Empowering Youth. Enriching Communities.\n Igniting Change",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Times New Roman',
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(20),
            height: 200,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _pageViewIndex = index;
                            });
                          },
                          children: const [
                            Center(
                              child: Text(
                                "The United Nations is a global organization that works to keep peace, protect human rights, fight poverty, and build a better future for all.",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Times New Roman',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Center(
                              child: Text(
                                "Second text: Promoting sustainable development and protecting the environment worldwide.",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Times New Roman',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Center(
                              child: Text(
                                "Third text: Fostering international cooperation to solve global challenges together.",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Times New Roman',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final nextPage = (_pageViewIndex + 1) % 3;
                          _pageController.animateToPage(
                            nextPage,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.blueGrey,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: const WormEffect(
                    activeDotColor: Colors.blueGrey,
                    dotHeight: 10,
                    dotWidth: 10,
                    spacing: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              const Text(
                "Partnership",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Image.asset(
                'assets/logounarwanda.jpg',
                height: 80,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget otherContentWidget(int index) {
    return Center(
      child: Text(
        '${bottomLabels[index]} page not implemented yet',
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
