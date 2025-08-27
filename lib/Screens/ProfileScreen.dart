// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Your Profile Info",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: const Color.fromARGB(255, 206, 202, 202),
//         foregroundColor: Colors.white,
//       ),
//       body: StreamBuilder<User?>(
//         stream: FirebaseAuth.instance.authStateChanges(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data == null) {
//             return const Center(child: Text("No user signed in"));
//           }

//           User currentUser = snapshot.data!;

//           return StreamBuilder<DocumentSnapshot>(
//             stream: _firestore
//                 .collection('normal_users')
//                 .doc(currentUser.uid)
//                 .snapshots(),
//             builder: (context, docSnapshot) {
//               if (docSnapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
//                 return const Center(child: Text("No profile data found"));
//               }

//               var data = docSnapshot.data!.data() as Map<String, dynamic>;

//               return _buildProfileUI(
//                 displayName: data['name'] ?? '',
//                 address: data['address'] ?? '',
//                 telephone: data['telephone'] ?? '',
//                 email: data['email'] ?? '',
//                 profilePicUrl: data['profilePicture'] ?? '',
//                 user: currentUser,
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildProfileUI({
//     required String displayName,
//     required String address,
//     required String telephone,
//     required String email,
//     required String profilePicUrl,
//     required User user,
//   }) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           CircleAvatar(
//             radius: 50,
//             backgroundImage:
//                 profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
//             child: profilePicUrl.isEmpty
//                 ? const Icon(Icons.person, size: 50)
//                 : null,
//           ),
//           const SizedBox(height: 20),
//           Card(
//             color: const Color.fromARGB(255, 243, 241, 241),
//             elevation: 3,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   _buildProfileInfoRow("Names:", displayName),
//                   const Divider(),
//                   _buildProfileInfoRow("Address:", address),
//                   const Divider(),
//                   _buildProfileInfoRow("Telephone:", telephone),
//                   const Divider(),
//                   _buildProfileInfoRow("Email:", email),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 30),
//           Center(
//             child: ElevatedButton(
//               onPressed: () {
//                 _showChangeProfileDialog(
//                   context,
//                   displayName,
//                   address,
//                   telephone,
//                   email,
//                   profilePicUrl,
//                   user,
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: const Text(
//                 "Change Profile",
//                 style: TextStyle(fontSize: 16),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 130,
//             child: Text(
//               label,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(value),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showChangeProfileDialog(
//       BuildContext context,
//       String names,
//       String address,
//       String telephone,
//       String email,
//       String profilePicUrl,
//       User user) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return ChangeProfileDialog(
//           names: names,
//           address: address,
//           telephone: telephone,
//           email: email,
//           profilePicUrl: profilePicUrl,
//           user: user,
//         );
//       },
//     );
//   }
// }

// // ------------------ CHANGE PROFILE DIALOG ------------------

// class ChangeProfileDialog extends StatefulWidget {
//   final String names;
//   final String address;
//   final String telephone;
//   final String email;
//   final String profilePicUrl;
//   final User user;

//   const ChangeProfileDialog({
//     super.key,
//     required this.names,
//     required this.address,
//     required this.telephone,
//     required this.email,
//     required this.profilePicUrl,
//     required this.user,
//   });

//   @override
//   State<ChangeProfileDialog> createState() => _ChangeProfileDialogState();
// }

// class _ChangeProfileDialogState extends State<ChangeProfileDialog> {
//   late TextEditingController _namesController;
//   late TextEditingController _addressController;
//   late TextEditingController _telephoneController;
//   late TextEditingController _emailController;
//   File? _newImageFile;
//   bool _saving = false;

//   @override
//   void initState() {
//     super.initState();
//     _namesController = TextEditingController(text: widget.names);
//     _addressController = TextEditingController(text: widget.address);
//     _telephoneController = TextEditingController(text: widget.telephone);
//     _emailController = TextEditingController(text: widget.email);
//   }

//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final picked = await picker.pickImage(source: ImageSource.gallery);

//     if (picked != null) {
//       setState(() {
//         _newImageFile = File(picked.path);
//       });
//     }
//   }

//   Future<String?> _uploadImage(File imageFile) async {
//     try {
//       final ref = FirebaseStorage.instance
//           .ref()
//           .child("profile_pictures")
//           .child("${widget.user.uid}.jpg");

//       await ref.putFile(imageFile);
//       return await ref.getDownloadURL();
//     } catch (e) {
//       debugPrint("Image upload failed: $e");
//       return null;
//     }
//   }

//   File? _imageFile;
//   Map<String, dynamic>? userData;
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 "Change Profile",
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 20),
//               GestureDetector(
//                 onTap: _pickImage,
//                 child: CircleAvatar(
//                   radius: 50,
//                   backgroundImage: _newImageFile != null
//                       ? FileImage(_newImageFile!) as ImageProvider
//                       : (widget.profilePicUrl.isNotEmpty
//                           ? NetworkImage(widget.profilePicUrl)
//                           : null), // if no profilePicUrl, show empty avatar
//                   child: Align(
//                     alignment: Alignment.bottomRight,
//                     child: CircleAvatar(
//                       backgroundColor: Colors.white,
//                       radius: 18,
//                       child:
//                           Icon(Icons.camera_alt, color: Colors.black, size: 20),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               _buildTextField("Names", _namesController),
//               const SizedBox(height: 15),
//               _buildTextField("Address", _addressController),
//               const SizedBox(height: 15),
//               _buildTextField("Telephone", _telephoneController),
//               const SizedBox(height: 15),
//               _buildTextField("Email", _emailController),
//               const SizedBox(height: 25),
//               if (_saving) const CircularProgressIndicator(),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   ElevatedButton(
//                     onPressed: () => Navigator.of(context).pop(),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.grey,
//                       foregroundColor: Colors.white,
//                     ),
//                     child: const Text("Cancel"),
//                   ),
//                   ElevatedButton(
//                     onPressed: () async {
//                       setState(() => _saving = true);

//                       String? profilePicUrl;

//                       if (_newImageFile != null) {
//                         profilePicUrl = await _uploadImage(_newImageFile!);
//                         if (profilePicUrl == null) {
//                           // Upload failed
//                           setState(() => _saving = false);
//                           return; // stop here
//                         }
//                       } else if (widget.profilePicUrl.isNotEmpty) {
//                         profilePicUrl = widget.profilePicUrl;
//                       } else {
//                         profilePicUrl = null;
//                       }

//                       await FirebaseFirestore.instance
//                           .collection('normal_users')
//                           .doc(widget.user.uid)
//                           .update({
//                         'name': _namesController.text,
//                         'address': _addressController.text,
//                         'telephone': _telephoneController.text,
//                         'email': _emailController.text,
//                         'profilePicture': profilePicUrl,
//                       });

//                       setState(() => _saving = false);
//                       Navigator.of(context).pop();
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue,
//                       foregroundColor: Colors.white,
//                     ),
//                     child: const Text("Save"),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(String label, TextEditingController controller) {
//     return TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//       textInputAction: TextInputAction.next,
//     );
//   }
// }

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ImageProvider? _getProfileImage(String profilePicBase64) {
    if (profilePicBase64.isEmpty) return null;

    // Check if it's a Data URL
    if (profilePicBase64.startsWith('data:image')) {
      try {
        // Remove "data:image/png;base64," prefix
        final base64Str = profilePicBase64.split(',')[1];
        return MemoryImage(base64Decode(base64Str));
      } catch (e) {
        debugPrint("Invalid Base64 string: $e");
        return null;
      }
    } else if (_isBase64(profilePicBase64)) {
      try {
        return MemoryImage(base64Decode(profilePicBase64));
      } catch (e) {
        debugPrint("Invalid Base64 string: $e");
        return null;
      }
    } else if (profilePicBase64.startsWith('http')) {
      return NetworkImage(profilePicBase64);
    }

    return null;
  }

  bool _isBase64(String str) {
    try {
      final decoded = base64Decode(str);
      return decoded.isNotEmpty;
    } catch (e) {
      return false;
    }
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
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No user signed in"));
          }
          User currentUser = snapshot.data!;
          return StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection('normal_users')
                .doc(currentUser.uid)
                .snapshots(),
            builder: (context, docSnapshot) {
              if (docSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
                return const Center(child: Text("No profile data found"));
              }
              var data = docSnapshot.data!.data() as Map<String, dynamic>;
              return _buildProfileUI(
                displayName: data['name'] ?? '',
                address: data['address'] ?? '',
                telephone: data['telephone'] ?? '',
                email: data['email'] ?? '',
                profilePicBase64: data['profilePicture'] ?? '',
                user: currentUser,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileUI({
    required String displayName,
    required String address,
    required String telephone,
    required String email,
    required String profilePicBase64,
    required User user,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Inside _buildProfileUI: update CircleAvatar to handle new users
          CircleAvatar(
            radius: 50,
            backgroundImage: _getProfileImage(profilePicBase64),
            child: (profilePicBase64.isEmpty)
                ? Stack(
                    children: [
                      const Center(
                        child:
                            Icon(Icons.person, size: 50, color: Colors.black54),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 18,
                          child: const Icon(Icons.camera_alt,
                              color: Colors.black, size: 20),
                        ),
                      ),
                    ],
                  )
                : null,
          ),

          const SizedBox(height: 20),
          Card(
            color: const Color.fromARGB(255, 243, 241, 241),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfileInfoRow("Names:", displayName),
                  const Divider(),
                  _buildProfileInfoRow("Address:", address),
                  const Divider(),
                  _buildProfileInfoRow("Telephone:", telephone),
                  const Divider(),
                  _buildProfileInfoRow("Email:", email),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton(
              onPressed: () {
                _showChangeProfileDialog(
                  context,
                  displayName,
                  address,
                  telephone,
                  email,
                  profilePicBase64,
                  user,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
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

  void _showChangeProfileDialog(
      BuildContext context,
      String names,
      String address,
      String telephone,
      String email,
      String profilePicBase64,
      User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ChangeProfileDialog(
          names: names,
          address: address,
          telephone: telephone,
          email: email,
          profilePicBase64: profilePicBase64,
          user: user,
        );
      },
    );
  }
}

// ------------------ CHANGE PROFILE DIALOG ------------------

class ChangeProfileDialog extends StatefulWidget {
  final String names;
  final String address;
  final String telephone;
  final String email;
  final String profilePicBase64;
  final User user;

  const ChangeProfileDialog({
    super.key,
    required this.names,
    required this.address,
    required this.telephone,
    required this.email,
    required this.profilePicBase64,
    required this.user,
  });

  @override
  State<ChangeProfileDialog> createState() => _ChangeProfileDialogState();
}

class _ChangeProfileDialogState extends State<ChangeProfileDialog> {
  late TextEditingController _namesController;
  late TextEditingController _addressController;
  late TextEditingController _telephoneController;
  late TextEditingController _emailController;
  File? _newImageFile;
  bool _saving = false;

  ImageProvider? _getProfileImage(String profilePicBase64, File? newImageFile) {
    if (newImageFile != null) {
      return FileImage(newImageFile);
    } else if (profilePicBase64.isNotEmpty) {
      if (profilePicBase64.startsWith('data:image')) {
        try {
          final base64Str = profilePicBase64.split(',')[1];
          return MemoryImage(base64Decode(base64Str));
        } catch (e) {
          debugPrint("Invalid Base64 Data URL: $e");
          return null;
        }
      } else if (_isBase64(profilePicBase64)) {
        try {
          return MemoryImage(base64Decode(profilePicBase64));
        } catch (e) {
          debugPrint("Invalid Base64 string: $e");
          return null;
        }
      } else if (profilePicBase64.startsWith('http')) {
        return NetworkImage(profilePicBase64);
      }
    }
    return null; // fallback: CircleAvatar will show Icon(Icons.person)
  }

// Helper to check if string is Base64
  bool _isBase64(String str) {
    try {
      final decoded = base64Decode(str);
      return decoded.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _namesController = TextEditingController(text: widget.names);
    _addressController = TextEditingController(text: widget.address);
    _telephoneController = TextEditingController(text: widget.telephone);
    _emailController = TextEditingController(text: widget.email);
  }

  Future<String> _convertToDataUrl(File file) async {
    final bytes = await file.readAsBytes();
    final base64Str = base64Encode(bytes);

    // Detect MIME type (basic, you can expand for jpg, png, etc.)
    String mimeType = 'image/png'; // default
    final extension = file.path.split('.').last.toLowerCase();
    if (extension == 'jpg' || extension == 'jpeg') {
      mimeType = 'image/jpeg';
    } else if (extension == 'gif') {
      mimeType = 'image/gif';
    }

    return 'data:$mimeType;base64,$base64Str';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final file = File(picked.path);
      final fileSize = await file.length();
      if (fileSize > 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Selected image exceeds 1 MB. Please choose a smaller file.",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _newImageFile = file;
      });
    }
  }

  Future<String> _convertToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
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
            children: [
              const Text(
                "Change Profile",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: Builder(builder: (_) {
                  ImageProvider? imageProvider;

                  if (_newImageFile != null) {
                    imageProvider = FileImage(_newImageFile!);
                  } else if (_isBase64(widget.profilePicBase64)) {
                    try {
                      imageProvider =
                          MemoryImage(base64Decode(widget.profilePicBase64));
                    } catch (e) {
                      imageProvider = null; // invalid Base64, fallback to null
                    }
                  } else if (widget.profilePicBase64.isNotEmpty) {
                    imageProvider = NetworkImage(widget.profilePicBase64);
                  } else {
                    imageProvider = null;
                  }

                  // return CircleAvatar(
                  //   radius: 50,
                  //   backgroundImage: _getProfileImage(
                  //       widget.profilePicBase64, _newImageFile),
                  //   child: (_newImageFile == null &&
                  //           widget.profilePicBase64.isEmpty)
                  //       ? const Icon(Icons.person, size: 50)

                  //       : Align(
                  //           alignment: Alignment.bottomRight,
                  //           child: CircleAvatar(
                  //             backgroundColor: Colors.white,
                  //             radius: 18,
                  //             child: Icon(Icons.camera_alt,
                  //                 color: Colors.black, size: 20),
                  //           ),
                  //         ),
                  // );

                  return CircleAvatar(
                    radius: 50,
                    backgroundImage: _getProfileImage(
                        widget.profilePicBase64, _newImageFile),
                    child: (_newImageFile == null &&
                            widget.profilePicBase64.isEmpty)
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.person, size: 50),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  radius: 18,
                                  child: Icon(Icons.camera_alt,
                                      color: Colors.black, size: 20),
                                ),
                              ),
                            ],
                          )
                        : Align(
                            alignment: Alignment.bottomRight,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 18,
                              child: Icon(Icons.camera_alt,
                                  color: Colors.black, size: 20),
                            ),
                          ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              _buildTextField("Names", _namesController),
              const SizedBox(height: 15),
              _buildTextField("Address", _addressController),
              const SizedBox(height: 15),
              _buildTextField("Telephone", _telephoneController),
              const SizedBox(height: 15),
              _buildTextField("Email", _emailController),
              const SizedBox(height: 25),
              if (_saving) const CircularProgressIndicator(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() => _saving = true);

                      String profilePicBase64 = widget.profilePicBase64;

                      if (_newImageFile != null) {
                        profilePicBase64 =
                            await _convertToDataUrl(_newImageFile!);
                      }

                      await FirebaseFirestore.instance
                          .collection('normal_users')
                          .doc(widget.user.uid)
                          .update({
                        'name': _namesController.text,
                        'address': _addressController.text,
                        'telephone': _telephoneController.text,
                        'email': _emailController.text,
                        'profilePicture': profilePicBase64,
                      });

                      setState(() => _saving = false);
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
      textInputAction: TextInputAction.next,
    );
  }
}
