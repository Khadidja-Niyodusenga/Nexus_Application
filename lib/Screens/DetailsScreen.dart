// import 'package:flutter/material.dart';

// class DetailsScreen extends StatefulWidget {
//   final int sdgNumber;
//   final String sdgTitle;
//   final String sdgDescription;

//   const DetailsScreen({
//     super.key,
//     required this.sdgNumber,
//     required this.sdgTitle,
//     required this.sdgDescription,
//   });

//   @override
//   State<DetailsScreen> createState() => _DetailsScreenState();
// }

// class _DetailsScreenState extends State<DetailsScreen> {
//   final TextEditingController _answerController = TextEditingController();

//   void _showThankYouDialog() {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Thank you!"),
//         content: const Text(
//             "We appreciate your response and your commitment to learning about this SDG."),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text("Close"),
//           ),
//         ],
//       ),
//     );
//   }

//   // Get the image path based on SDG number
//   String getSdgImagePath() {
//     // Ensure the number is between 1 and 17
//     int number = widget.sdgNumber.clamp(1, 17);
//     return "assets/photo$number.png"; // photo1.png, photo2.png, ...
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.sdgTitle),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//         backgroundColor: Colors.green[600],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Image.asset(
//               getSdgImagePath(), // Use local image based on SDG number
//               height: 200,
//               width: double.infinity,
//               fit: BoxFit.cover,
//             ),
//             const SizedBox(height: 12),
//             Text(
//               widget.sdgTitle,
//               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               widget.sdgDescription,
//               style: const TextStyle(fontSize: 16),
//               textAlign: TextAlign.justify,
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               "Question?",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 4),
//             const Text(
//               "What practical actions can you take or inspire others to take to support this goal in your community?",
//               style: TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: _answerController,
//               decoration: const InputDecoration(
//                 hintText: "Write your Answer here...",
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 3,
//             ),
//             const SizedBox(height: 12),
//             ElevatedButton(
//               onPressed: () {
//                 if (_answerController.text.isNotEmpty) {
//                   _showThankYouDialog();
//                 }
//               },
//               child: const Text("Submit"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class DetailsScreen extends StatefulWidget {
  final int sdgNumber;

  const DetailsScreen({
    super.key,
    required this.sdgNumber,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final Map<String, TextEditingController> _controllers = {};

  void _showThankYouDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thank you!"),
        content: const Text(
            "We appreciate your response and your commitment to learning about this SDG."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String sdgId = widget.sdgNumber.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text("SDG $sdgId"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.green[600],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lessons')
            .where('sdgId', isEqualTo: sdgId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No lessons available for this SDG yet."),
            );
          }

          var lesson = snapshot.data!.docs.first; // one lesson per SDG
          var data = lesson.data() as Map<String, dynamic>;
          String docId = lesson.id;

          _controllers.putIfAbsent(docId, () => TextEditingController());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                data['image'] != null && data['image'].toString().isNotEmpty
                    ? (() {
                        try {
                          final String imageData = data['image'].toString();

                          // Check if it's a base64 string
                          if (imageData.startsWith('data:image') ||
                              !imageData.startsWith('http')) {
                            String base64String = imageData;
                            if (base64String.contains(',')) {
                              base64String = base64String.split(',')[1];
                            }

                            Uint8List bytes = base64Decode(base64String);

                            return Image.memory(
                              bytes,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          } else {
                            // Treat as normal URL
                            return Image.network(
                              imageData,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image,
                                    size: 100, color: Colors.grey);
                              },
                            );
                          }
                        } catch (e) {
                          return const Icon(Icons.broken_image,
                              size: 100, color: Colors.grey);
                        }
                      })()
                    : const Icon(Icons.image, size: 100, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  data['title'] ?? '',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  data['description'] ?? '',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 12),
                if (data['activities'] != null && data['activities'] is List)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Activities:",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...List<Widget>.generate(
                        (data['activities'] as List).length,
                        (index) {
                          String activity = (data['activities'] as List)[index];
                          // Split title and description at first colon
                          List<String> parts = activity
                              .split(RegExp(r'\s*:\s*', caseSensitive: false));
                          String title = parts.isNotEmpty ? parts[0] : '';
                          String description = parts.length > 1
                              ? parts.sublist(1).join(': ')
                              : '';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: RichText(
                              textAlign: TextAlign.left,
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  fontStyle: FontStyle.normal,
                                  color: Colors.black,
                                ),
                                children: [
                                  TextSpan(
                                    text: "${index + 1}. $title: ",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: description,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.normal),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                if (data['interactiveQuestion'] != null) ...[
                  Text(
                    data['interactiveQuestion'],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controllers[docId],
                    decoration: const InputDecoration(
                      hintText: "Write your Answer here...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      String answer = _controllers[docId]!.text.trim();
                      if (answer.isNotEmpty) {
                        await FirebaseFirestore.instance
                            .collection('lessons')
                            .doc(docId)
                            .collection('answers')
                            .add({
                          'answer': answer,
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        _showThankYouDialog();
                        _controllers[docId]!.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // ✅ green background
                      foregroundColor: Colors.white, // optional: text color
                    ),
                    child: const Text("Submit"),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
