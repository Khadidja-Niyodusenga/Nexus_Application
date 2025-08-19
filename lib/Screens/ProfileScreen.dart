import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEWUS APP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
  String names = "Uwiduhaye Yvette";
  String telephone = "0788996756";
  String email = "yvetteuwi@gmail.com";
  String address = "Kigali, Kicukiro";
  void _showChangeProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ChangeProfileDialog(
          names: names,
          telephone: telephone,
          email: email,
          address: address,
          onSave: (newNames, newTelephone, newEmail, newAddress) {
            setState(() {
              names = newNames;
              telephone = newTelephone;
              email = newEmail;
              address = newAddress;
            });
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
          "NEWUS APP",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Your Profile info",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Card(
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
                      _buildProfileInfoRow("Telephone:", telephone),
                      const Divider(),
                      _buildProfileInfoRow("Email or username:", email),
                      const Divider(),
                      _buildProfileInfoRow("Address:", address),
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
        ),
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

class ChangeProfileDialog extends StatefulWidget {
  final String names;
  final String telephone;
  final String email;
  final String address;
  final Function(String, String, String, String) onSave;

  const ChangeProfileDialog({
    super.key,
    required this.names,
    required this.telephone,
    required this.email,
    required this.address,
    required this.onSave,
  });
  @override
  State<ChangeProfileDialog> createState() => _ChangeProfileDialogState();
}

class _ChangeProfileDialogState extends State<ChangeProfileDialog> {
  late TextEditingController _namesController;
  late TextEditingController _telephoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _namesController = TextEditingController(text: widget.names);
    _telephoneController = TextEditingController(text: widget.telephone);
    _emailController = TextEditingController(text: widget.email);
    _addressController = TextEditingController(text: widget.address);
  }

  @override
  void dispose() {
    _namesController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
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
              _buildTextField("Username", _emailController),
              const SizedBox(height: 15),
              _buildTextField("Telephone", _telephoneController),
              const SizedBox(height: 15),
              _buildTextField("Address", _addressController),
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
                        _telephoneController.text,
                        _emailController.text,
                        _addressController.text,
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      keyboardType:
          label == "Telephone" ? TextInputType.phone : TextInputType.text,
      textInputAction: TextInputAction.next,
    );
  }
}
