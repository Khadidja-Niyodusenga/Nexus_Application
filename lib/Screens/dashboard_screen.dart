import 'package:flutter/material.dart';
import 'package:new_nexus_application/screens/LoginScreen.dart';
import 'FeedbackScreen.dart';
import 'NotificationScreen.dart';
import 'TrackProgressScreen.dart';
import 'LearnScreen.dart';
import 'UpdatesScreen.dart';
import 'ProfileScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  final PageController _pageController = PageController();
  int _pageViewIndex = 0; // For the PageView inside Home

  final List<String> bottomLabels = ["Home", "Learn", "Updates", "Profile"];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
                items: const [
                  PopupMenuItem(value: "track", child: Text("Track Progress")),
                  PopupMenuItem(
                      value: "feedback", child: Text("User Feedback")),
                  PopupMenuItem(value: "notif", child: Text("Notification")),
                  PopupMenuItem(value: "signout", child: Text("Sign Out")),
                ],
              ).then((value) async {
                if (value == "signout") {
                  // Sign out from Firebase Auth
                  await FirebaseAuth.instance.signOut();

                  // Sign out from GoogleSignIn to force account picker next time
                  final g = GoogleSignIn();
                  await g.signOut();

                  // Navigate back to login screen and remove all previous routes
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                } else if (value == "track") {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TrackProgressScreen()));
                } else if (value == "notif") {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => NotificationScreen()));
                } else if (value == "feedback") {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FeedbackScreen()));
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
        title: const Text(
          "NEXUS APP",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationScreen()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.notifications, color: Colors.blue),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeedbackScreen()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.chat_bubble, color: Colors.blue),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          homeContentWidget(),
          const LearnScreen(),
          const UpdatesScreen(),
          const ProfileScreen(),
          otherContentWidget("Updates"),
          otherContentWidget("Profile"),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF3B9DD2),
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
                    });
                  },
                  child: Text(
                    bottomLabels[index],
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                              fontSize: 16, fontFamily: 'Times New Roman'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Center(
                        child: Text(
                          "Second text: Promoting sustainable development and protecting the environment worldwide.",
                          style: TextStyle(
                              fontSize: 16, fontFamily: 'Times New Roman'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Center(
                        child: Text(
                          "Third text: Fostering international cooperation to solve global challenges together.",
                          style: TextStyle(
                              fontSize: 16, fontFamily: 'Times New Roman'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_pageController.hasClients) {
                      final nextPage = (_pageViewIndex + 1) % 3;
                      _pageController.animateToPage(
                        nextPage,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
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

  Widget otherContentWidget(String label) {
    return Center(
      child: Text(
        "$label page not implemented yet",
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
