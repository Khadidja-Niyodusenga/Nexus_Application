import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your Profile info',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String names = "";
  String email = "";
  String username = "";
  String profilePicUrl = "";

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    if (user != null) {
      DocumentReference docRef =
          _firestore.collection('normal_users').doc(user!.uid);

      DocumentSnapshot doc = await docRef.get();

      if (doc.exists) {
        setState(() {
          names = doc['name'] ?? '';
          username = doc['username'] ?? '';
          email = doc['email'] ?? '';
          profilePicUrl = doc['profilePicture'] ?? '';
        });
      } else {
        // Create default document if not exists
        await docRef.set({
          'names': '',
          'username': '',
          'email': user!.email ?? '',
          'profilePicUrl': '',
        });
      }
    }
  }

  void _updateUserProfile(
      String newNames, String newUsername, String newEmail) async {
    if (user != null) {
      await _firestore.collection('normal_users').doc(user!.uid).update({
        'name': newNames,
        'username': newUsername,
        'email': newEmail,
        'profilePicture': profilePicUrl, // if you allow updating profile pic
      });

      setState(() {
        names = newNames;
        username = newUsername;
        email = newEmail;
      });
    }
  }

  void _showChangeProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ChangeProfileDialog(
          names: names,
          username: username,
          email: email,
          onSave: (newNames, newUsername, newEmail) {
            _updateUserProfile(newNames, newUsername, newEmail);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Your Profile Info",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 206, 202, 202),
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text("No user signed in"))
          : FutureBuilder<DocumentSnapshot>(
              future:
                  _firestore.collection('normal_users').doc(user!.uid).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("No profile data found"));
                }

                var data = snapshot.data!.data() as Map<String, dynamic>;

                names = data['name'] ?? '';
                username = data['username'] ?? '';
                email = data['email'] ?? '';

                profilePicUrl = data['profilePicture'] ?? '';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: profilePicUrl.isNotEmpty
                            ? NetworkImage(profilePicUrl)
                            : null,
                        child: profilePicUrl.isEmpty
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Profile picture",
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        color: const Color.fromARGB(
                            255, 243, 241, 241), // your background color
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildProfileInfoRow("Names:", names),
                              const Divider(),
                              _buildProfileInfoRow("Username:", username),
                              const Divider(),
                              _buildProfileInfoRow("Email:", email),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          onPressed: _showChangeProfileDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Change Profile",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

// ------------------ CHANGE PROFILE DIALOG ------------------

class ChangeProfileDialog extends StatefulWidget {
  final String names;
  final String username;
  final String email;

  final Function(String, String, String) onSave;

  const ChangeProfileDialog({
    super.key,
    required this.names,
    required this.username,
    required this.email,
    required this.onSave,
  });

  @override
  State<ChangeProfileDialog> createState() => _ChangeProfileDialogState();
}

class _ChangeProfileDialogState extends State<ChangeProfileDialog> {
  late TextEditingController _namesController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _namesController = TextEditingController(text: widget.names);
    _usernameController = TextEditingController(text: widget.username);
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _namesController.dispose();
    _usernameController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Change Profile",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "Profile picture:",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField("Names", _namesController),
              const SizedBox(height: 15),
              _buildTextField("Username", _usernameController),
              const SizedBox(height: 15),
              _buildTextField("Email", _emailController),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSave(
                        _namesController.text,
                        _usernameController.text,
                        _emailController.text,
                      );
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Save"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textInputAction: TextInputAction.next,
    );
  }
}
