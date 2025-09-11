import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;
import 'package:openai_dart/openai_dart.dart' as openai;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openai_dart/openai_dart.dart' hide Image;

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
  int responsesCount = 0;
  bool canRespond = true;
  bool _hasCheckedResponses = false;
  DateTime? _startTime;
  int _readMinutes = 0;
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;
  final client = OpenAIClient(apiKey: dotenv.env['OPENAI_API_KEY']!);

  String? _docId;
  Future<void> _initializeLesson() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('lessons')
        .where('sdgId', isEqualTo: widget.sdgNumber.toString())
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final lesson = snapshot.docs.first;
      _docId = lesson.id;
      _controllers.putIfAbsent(_docId!, () => TextEditingController());
      await _checkResponses(_docId!);
      setState(() {});
    }
  }

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

  Future<void> _checkResponses(String docId) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final answersSnapshot = await FirebaseFirestore.instance
        .collection('answers')
        .where('userId', isEqualTo: user.uid)
        .where('sdgId', isEqualTo: docId)
        .get();
  }

  Future<String> analyzeWithAI({
    required String question,
    required String userResponse,
  }) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      return "API key is missing. Please set your OpenAI API key in .env";
    }

    if (userResponse.trim().length < 20) {
      return "Good start! Try writing a more detailed answer for better feedback.";
    }

    // Check Firestore cache
    final cached = await FirebaseFirestore.instance
        .collection('feedbackCache')
        .where('question', isEqualTo: question)
        .where('response', isEqualTo: userResponse)
        .limit(1)
        .get();
    if (cached.docs.isNotEmpty) {
      return cached.docs.first['feedback'];
    }
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");
    final body = {
      "model": "gpt-3.5-turbo",
      "messages": [
        {"role": "system", "content": "You are an SDG learning assistant."},
        {
          "role": "user",
          // "content":
          //     "Question: $question\nAnswer: $userResponse\nPlease provide friendly feedback in JSON format."
          "content":
              "Question: $question\nAnswer: $userResponse\nPlease provide friendly feedback (short and clear, no JSON)."
        }
      ],
      "max_tokens": 150,
    };
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $apiKey",
    };

    try {
      final res =
          await http.post(url, headers: headers, body: jsonEncode(body));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded["choices"] != null && decoded["choices"].isNotEmpty) {
          final feedback = decoded["choices"][0]["message"]["content"];
          await FirebaseFirestore.instance.collection('feedbackCache').add({
            'question': question,
            'response': userResponse,
            'feedback': feedback,
            'timestamp': FieldValue.serverTimestamp(),
          });
          return feedback;
        } else {
          return "Unexpected response format from OpenAI.";
        }
      } else {
        return "Error ${res.statusCode}: ${res.body}";
      }
    } catch (e) {
      return "Network error: $e";
    }
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
            .where('status', isEqualTo: "Published") // 👈 only published
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No published lessons available for this SDG yet."),
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
                      hintText: "Write your answer here (min 20 characters)...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // ✅ Always green
                      foregroundColor:
                          Colors.white, // ✅ White text for contrast
                    ),
                    onPressed: (!_isSubmitting && canRespond)
                        ? () async {
                            String answer = _controllers[docId]!.text.trim();
                            firebase_auth.User? user =
                                firebase_auth.FirebaseAuth.instance.currentUser;

                            if (answer.isEmpty || user == null) return;

                            setState(() {
                              _isSubmitting = true;
                            });

                            final answersRef = FirebaseFirestore.instance
                                .collection('answers');

                            // Fetch existing answers
                            final existingSnapshot = await answersRef
                                .where('userId', isEqualTo: user.uid)
                                .where('sdgId', isEqualTo: docId)
                                .get();

                            if (existingSnapshot.docs.length < 2) {
                              if (existingSnapshot.docs.isNotEmpty) {
                                // Update the first existing answer
                                final docIdToUpdate =
                                    existingSnapshot.docs.first.id;
                                await answersRef.doc(docIdToUpdate).update({
                                  'response': answer,
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });
                              } else {
                                // Add new answer
                                await answersRef.add({
                                  'userId': user.uid,
                                  'sdgId': docId,
                                  'response': answer,
                                  'timestamp': FieldValue.serverTimestamp(),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });
                              }

                              // Call AI to analyze response
                              String feedback = await analyzeWithAI(
                                question: data['interactiveQuestion'],
                                userResponse: answer,
                              );

                              // --- classify quality based on AI feedback ---
                              String quality;
                              if (feedback.toLowerCase().contains("good")) {
                                quality = "good";
                              } else if (feedback
                                  .toLowerCase()
                                  .contains("partial")) {
                                quality = "partial";
                              } else {
                                quality = "poor";
                              }

                              // --- calculate dynamic percentage ---
                              int percentage = calculatePercentage(
                                opened: true,
                                readMinutes: _readMinutes, // ✅ real time
                                responded: true,
                                quality: quality,
                              );

                              // --- save progress in Firestore ---
                              final docRef = FirebaseFirestore.instance
                                  .collection('progress')
                                  .doc(user.uid);

                              await docRef.set({
                                'userId': user.uid,
                                'sdgs.$sdgId': {
                                  'opened': true,
                                  'readMinutes': _readMinutes, // ✅ real time
                                  'responded': true,
                                  'responseQuality': quality,
                                  'percentage': percentage,
                                  'updatedAt': FieldValue.serverTimestamp(),
                                }
                              }, SetOptions(merge: true));

                              // --- show feedback to user ---
                              if (!mounted) return;
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Feedback"),
                                  content: Text(feedback),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("OK"),
                                    )
                                  ],
                                ),
                              );

                              _controllers[docId]!.clear();
                            }

                            // Refresh responses count
                            await _checkResponses(docId);

                            setState(() {
                              _isSubmitting = false;
                            });
                          }
                        : null,
                    child: Text(_isSubmitting ? "Submitting..." : "Submit"),
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

int calculatePercentage({
  required bool opened,
  required int readMinutes,
  required bool responded,
  required String quality,
}) {
  int score = 0;

  if (opened) score += 10;

  if (readMinutes >= 5) {
    score += 30;
  } else if (readMinutes > 0) {
    score += 10;
  }

  if (responded) score += 20;

  if (quality == "good") {
    score += 40;
  } else if (quality == "partial") {
    score += 20;
  } else if (quality == "poor") {
    score += 10;
  }

  return score.clamp(0, 100);
}

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// import 'package:http/http.dart' as http;
// import 'package:openai_dart/openai_dart.dart' as openai;
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:openai_dart/openai_dart.dart' hide Image;

// class DetailsScreen extends StatefulWidget {
//   final int sdgNumber;
//   const DetailsScreen({
//     super.key,
//     required this.sdgNumber,
//   });
//   @override
//   State<DetailsScreen> createState() => _DetailsScreenState();
// }

// class _DetailsScreenState extends State<DetailsScreen> {
//   int responsesCount = 0;
//   bool canRespond = true;
//   bool _hasCheckedResponses = false;

//   // Track reading time
//   DateTime? _startTime;
//   int _readMinutes = 0;

//   final Map<String, TextEditingController> _controllers = {};
//   bool _isSubmitting = false;
//   final client = OpenAIClient(apiKey: dotenv.env['OPENAI_API_KEY']!);

//   String? _docId;

//   @override
//   void initState() {
//     super.initState();
//     _startTime = DateTime.now(); // ✅ start tracking reading time
//     _initializeLesson(); // ✅ make sure to call this
//   }

//   Future<void> markOpened(String sdgId) async {
//     final user = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final duration = DateTime.now().difference(_startTime ?? DateTime.now());
//     final readMinutes = duration.inMinutes;

//     final docRef =
//         FirebaseFirestore.instance.collection('progress').doc(user.uid);

//     int percentage = calculatePercentage(
//       opened: true,
//       readMinutes: readMinutes,
//       responded: false,
//       quality: 'none',
//     );

//     await docRef.set({
//       'userId': user.uid,
//       'sdgs.$sdgId': {
//         'opened': true,
//         'readMinutes': readMinutes,
//         'responded': false,
//         'responseQuality': 'none',
//         'percentage': percentage,
//         'updatedAt': FieldValue.serverTimestamp(),
//       }
//     }, SetOptions(merge: true));
//   }

//   Future<void> _initializeLesson() async {
//     final snapshot = await FirebaseFirestore.instance
//         .collection('lessons')
//         .where('sdgId', isEqualTo: widget.sdgNumber.toString())
//         .limit(1)
//         .get();
//     if (snapshot.docs.isNotEmpty) {
//       final lesson = snapshot.docs.first;
//       _docId = lesson.id;
//       _controllers.putIfAbsent(_docId!, () => TextEditingController());
//       await _checkResponses(_docId!);
//       setState(() {});
//     }
//     if (_docId != null) {
//       await markOpened(widget.sdgNumber.toString());
//     }
//   }

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

//   Future<void> _checkResponses(String docId) async {
//     final user = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final answersSnapshot = await FirebaseFirestore.instance
//         .collection('answers')
//         .where('userId', isEqualTo: user.uid)
//         .where('sdgId', isEqualTo: docId)
//         .get();
//   }

//   Future<String> analyzeWithAI({
//     required String question,
//     required String userResponse,
//   }) async {
//     final apiKey = dotenv.env['OPENAI_API_KEY'];

//     if (apiKey == null || apiKey.isEmpty) {
//       return "API key is missing. Please set your OpenAI API key in .env";
//     }

//     if (userResponse.trim().length < 20) {
//       return "Good start! Try writing a more detailed answer for better feedback.";
//     }

//     // Check Firestore cache
//     final cached = await FirebaseFirestore.instance
//         .collection('feedbackCache')
//         .where('question', isEqualTo: question)
//         .where('response', isEqualTo: userResponse)
//         .limit(1)
//         .get();
//     if (cached.docs.isNotEmpty) {
//       return cached.docs.first['feedback'];
//     }
//     final url = Uri.parse("https://api.openai.com/v1/chat/completions");
//     final body = {
//       "model": "gpt-3.5-turbo",
//       "messages": [
//         {"role": "system", "content": "You are an SDG learning assistant."},
//         {
//           "role": "user",
//           "content":
//               "Question: $question\nAnswer: $userResponse\nPlease provide friendly feedback (short and clear, no JSON)."
//         }
//       ],
//       "max_tokens": 150,
//     };
//     final headers = {
//       "Content-Type": "application/json",
//       "Authorization": "Bearer $apiKey",
//     };

//     try {
//       final res =
//           await http.post(url, headers: headers, body: jsonEncode(body));
//       if (res.statusCode == 200) {
//         final decoded = jsonDecode(res.body);
//         if (decoded["choices"] != null && decoded["choices"].isNotEmpty) {
//           final feedback = decoded["choices"][0]["message"]["content"];
//           await FirebaseFirestore.instance.collection('feedbackCache').add({
//             'question': question,
//             'response': userResponse,
//             'feedback': feedback,
//             'timestamp': FieldValue.serverTimestamp(),
//           });
//           return feedback;
//         } else {
//           return "Unexpected response format from OpenAI.";
//         }
//       } else {
//         return "Error ${res.statusCode}: ${res.body}";
//       }
//     } catch (e) {
//       return "Network error: $e";
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final String sdgId = widget.sdgNumber.toString();

//     return Scaffold(
//       appBar: AppBar(
//         title: Text("SDG $sdgId"),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//         backgroundColor: Colors.green[600],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('lessons')
//             .where('sdgId', isEqualTo: sdgId)
//             .where('status', isEqualTo: "Published") // 👈 only published
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text("No published lessons available for this SDG yet."),
//             );
//           }
//           var lesson = snapshot.data!.docs.first; // one lesson per SDG
//           var data = lesson.data() as Map<String, dynamic>;
//           String docId = lesson.id;

//           _controllers.putIfAbsent(docId, () => TextEditingController());

//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 data['image'] != null && data['image'].toString().isNotEmpty
//                     ? (() {
//                         try {
//                           final String imageData = data['image'].toString();

//                           // Check if it's a base64 string
//                           if (imageData.startsWith('data:image') ||
//                               !imageData.startsWith('http')) {
//                             String base64String = imageData;
//                             if (base64String.contains(',')) {
//                               base64String = base64String.split(',')[1];
//                             }

//                             Uint8List bytes = base64Decode(base64String);

//                             return Image.memory(
//                               bytes,
//                               height: 200,
//                               width: double.infinity,
//                               fit: BoxFit.cover,
//                             );
//                           } else {
//                             // Treat as normal URL
//                             return Image.network(
//                               imageData,
//                               height: 200,
//                               width: double.infinity,
//                               fit: BoxFit.cover,
//                               errorBuilder: (context, error, stackTrace) {
//                                 return const Icon(Icons.broken_image,
//                                     size: 100, color: Colors.grey);
//                               },
//                             );
//                           }
//                         } catch (e) {
//                           return const Icon(Icons.broken_image,
//                               size: 100, color: Colors.grey);
//                         }
//                       })()
//                     : const Icon(Icons.image, size: 100, color: Colors.grey),
//                 const SizedBox(height: 12),
//                 Text(
//                   data['title'] ?? '',
//                   style: const TextStyle(
//                       fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   data['description'] ?? '',
//                   style: const TextStyle(fontSize: 16),
//                   textAlign: TextAlign.left,
//                 ),
//                 const SizedBox(height: 12),
//                 if (data['activities'] != null && data['activities'] is List)
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         "Activities:",
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           fontStyle: FontStyle.normal,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       ...List<Widget>.generate(
//                         (data['activities'] as List).length,
//                         (index) {
//                           String activity = (data['activities'] as List)[index];
//                           List<String> parts = activity
//                               .split(RegExp(r'\s*:\s*', caseSensitive: false));
//                           String title = parts.isNotEmpty ? parts[0] : '';
//                           String description = parts.length > 1
//                               ? parts.sublist(1).join(': ')
//                               : '';

//                           return Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 2),
//                             child: RichText(
//                               textAlign: TextAlign.left,
//                               text: TextSpan(
//                                 style: const TextStyle(
//                                   fontSize: 15,
//                                   height: 1.5,
//                                   fontStyle: FontStyle.normal,
//                                   color: Colors.black,
//                                 ),
//                                 children: [
//                                   TextSpan(
//                                     text: "${index + 1}. $title: ",
//                                     style: const TextStyle(
//                                         fontWeight: FontWeight.bold),
//                                   ),
//                                   TextSpan(
//                                     text: description,
//                                     style: const TextStyle(
//                                         fontWeight: FontWeight.normal),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 const SizedBox(height: 16),
//                 if (data['interactiveQuestion'] != null) ...[
//                   Text(
//                     data['interactiveQuestion'],
//                     style: const TextStyle(
//                         fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: _controllers[docId],
//                     decoration: const InputDecoration(
//                       hintText: "Write your Answer here...",
//                       border: OutlineInputBorder(),
//                     ),
//                     maxLines: 3,
//                   ),
//                   const SizedBox(height: 8),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green, // ✅ Always green
//                       foregroundColor:
//                           Colors.white, // ✅ White text for contrast
//                     ),
//                     onPressed: (!_isSubmitting && canRespond)
//                         ? () async {
//                             String answer = _controllers[docId]!.text.trim();
//                             firebase_auth.User? user =
//                                 firebase_auth.FirebaseAuth.instance.currentUser;

//                             if (answer.isEmpty || user == null) return;

//                             setState(() {
//                               _isSubmitting = true;
//                             });

//                             final answersRef = FirebaseFirestore.instance
//                                 .collection('answers');

//                             // Fetch existing answers
//                             final existingSnapshot = await answersRef
//                                 .where('userId', isEqualTo: user.uid)
//                                 .where('sdgId', isEqualTo: sdgId)
//                                 .get();

//                             if (_startTime != null) {
//                               final duration =
//                                   DateTime.now().difference(_startTime!);
//                               _readMinutes = duration.inMinutes;
//                             }

//                             if (existingSnapshot.docs.length < 2) {
//                               if (existingSnapshot.docs.isNotEmpty) {
//                                 // Update the first existing answer
//                                 final docIdToUpdate =
//                                     existingSnapshot.docs.first.id;
//                                 await answersRef.doc(docIdToUpdate).update({
//                                   'response': answer,
//                                   'updatedAt': FieldValue.serverTimestamp(),
//                                 });
//                               } else {
//                                 // Add new answer
//                                 await answersRef.add({
//                                   'userId': user.uid,
//                                   // 'sdgId': docId,
//                                   'sdgId': sdgId,
//                                   'response': answer,
//                                   'timestamp': FieldValue.serverTimestamp(),
//                                   'updatedAt': FieldValue.serverTimestamp(),
//                                 });
//                               }

//                               // Call AI to analyze response
//                               String feedback = await analyzeWithAI(
//                                 question: data['interactiveQuestion'],
//                                 userResponse: answer,
//                               );

//                               // --- classify quality based on AI feedback ---
//                               String quality;
//                               if (feedback.toLowerCase().contains("good")) {
//                                 quality = "good";
//                               } else if (feedback
//                                   .toLowerCase()
//                                   .contains("partial")) {
//                                 quality = "partial";
//                               } else {
//                                 quality = "poor";
//                               }

//                               // --- calculate dynamic percentage ---
//                               int percentage = calculatePercentage(
//                                 opened: true, // user opened this SDG
//                                 readMinutes: _readMinutes,
//                                 responded: true, // user submitted an answer
//                                 quality: quality, // from AI
//                               );

//                               // --- save progress in Firestore ---
//                               final docRef = FirebaseFirestore.instance
//                                   .collection('progress')
//                                   .doc(user.uid);

//                               await docRef.set({
//                                 'userId': user.uid,
//                                 'sdgs.$sdgId': {
//                                   'opened': true,
//                                   'readMinutes': _readMinutes,
//                                   'responded': true,
//                                   'responseQuality': quality,
//                                   'percentage': percentage,
//                                   'updatedAt': FieldValue.serverTimestamp(),
//                                 }
//                               }, SetOptions(merge: true));

//                               // --- show feedback to user ---
//                               if (!mounted) return;
//                               showDialog(
//                                 context: context,
//                                 builder: (context) => AlertDialog(
//                                   title: const Text("Feedback"),
//                                   content: Text(feedback),
//                                   actions: [
//                                     TextButton(
//                                       onPressed: () => Navigator.pop(context),
//                                       child: const Text("OK"),
//                                     )
//                                   ],
//                                 ),
//                               );

//                               _controllers[docId]!.clear();
//                             }

//                             // Refresh responses count
//                             await _checkResponses(docId);

//                             setState(() {
//                               _isSubmitting = false;
//                             });
//                           }
//                         : null,
//                     child: Text(_isSubmitting ? "Submitting..." : "Submit"),
//                   ),
//                 ],
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// int calculatePercentage({
//   required bool opened,
//   required int readMinutes,
//   required bool responded,
//   required String quality, // "good", "poor", "partial", "none"
// }) {
//   int score = 0;

//   if (opened) score += 10;

//   if (readMinutes >= 5) {
//     score += 25;
//   } else if (readMinutes > 0) {
//     score += 10;
//   }

//   if (responded) score += 25;

//   if (responded) {
//     if (quality.toLowerCase() == "good")
//       score += 40;
//     else if (quality.toLowerCase() == "partial")
//       score += 30;
//     else if (quality.toLowerCase() == "poor") score += 20;
//   }

//   // ✅ Give minimum 10% if user opened, even without submitting
//   if (!responded && opened && score == 0) score = 10;

//   return score.clamp(0, 100);
// }

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// import 'package:http/http.dart' as http;
// import 'package:openai_dart/openai_dart.dart' as openai;
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:openai_dart/openai_dart.dart' hide Image;

// class DetailsScreen extends StatefulWidget {
//   final int sdgNumber;
//   const DetailsScreen({
//     super.key,
//     required this.sdgNumber,
//   });
//   @override
//   State<DetailsScreen> createState() => _DetailsScreenState();
// }

// class _DetailsScreenState extends State<DetailsScreen> {
//   int responsesCount = 0;
//   bool canRespond = true;
//   bool _hasCheckedResponses = false;
//   DateTime? _startTime;
//   int _readMinutes = 0;
//   final Map<String, TextEditingController> _controllers = {};
//   bool _isSubmitting = false;
//   final client = OpenAIClient(apiKey: dotenv.env['OPENAI_API_KEY']!);

//   String? _docId;
//   Future<void> _initializeLesson() async {
//     final snapshot = await FirebaseFirestore.instance
//         .collection('lessons')
//         .where('sdgId', isEqualTo: widget.sdgNumber.toString())
//         .limit(1)
//         .get();
//     if (snapshot.docs.isNotEmpty) {
//       final lesson = snapshot.docs.first;
//       _docId = lesson.id;
//       _controllers.putIfAbsent(_docId!, () => TextEditingController());
//       await _checkResponses(_docId!);
//       setState(() {});
//     }
//   }

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

//   Future<void> _checkResponses(String docId) async {
//     final user = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final answersSnapshot = await FirebaseFirestore.instance
//         .collection('answers')
//         .where('userId', isEqualTo: user.uid)
//         .where('sdgId', isEqualTo: docId)
//         .get();
//   }

//   Future<String> analyzeWithAI({
//     required String question,
//     required String userResponse,
//   }) async {
//     final apiKey = dotenv.env['OPENAI_API_KEY'];

//     if (apiKey == null || apiKey.isEmpty) {
//       return "API key is missing. Please set your OpenAI API key in .env";
//     }

//     if (userResponse.trim().length < 20) {
//       return "Good start! Try writing a more detailed answer for better feedback.";
//     }

//     // Check Firestore cache
//     final cached = await FirebaseFirestore.instance
//         .collection('feedbackCache')
//         .where('question', isEqualTo: question)
//         .where('response', isEqualTo: userResponse)
//         .limit(1)
//         .get();
//     if (cached.docs.isNotEmpty) {
//       return cached.docs.first['feedback'];
//     }
//     final url = Uri.parse("https://api.openai.com/v1/chat/completions");
//     final body = {
//       "model": "gpt-3.5-turbo",
//       "messages": [
//         {"role": "system", "content": "You are an SDG learning assistant."},
//         {
//           "role": "user",
//           // "content":
//           //     "Question: $question\nAnswer: $userResponse\nPlease provide friendly feedback in JSON format."
//           "content":
//               "Question: $question\nAnswer: $userResponse\nPlease provide friendly feedback (short and clear, no JSON)."
//         }
//       ],
//       "max_tokens": 150,
//     };
//     final headers = {
//       "Content-Type": "application/json",
//       "Authorization": "Bearer $apiKey",
//     };

//     try {
//       final res =
//           await http.post(url, headers: headers, body: jsonEncode(body));
//       if (res.statusCode == 200) {
//         final decoded = jsonDecode(res.body);
//         if (decoded["choices"] != null && decoded["choices"].isNotEmpty) {
//           final feedback = decoded["choices"][0]["message"]["content"];
//           await FirebaseFirestore.instance.collection('feedbackCache').add({
//             'question': question,
//             'response': userResponse,
//             'feedback': feedback,
//             'timestamp': FieldValue.serverTimestamp(),
//           });
//           return feedback;
//         } else {
//           return "Unexpected response format from OpenAI.";
//         }
//       } else {
//         return "Error ${res.statusCode}: ${res.body}";
//       }
//     } catch (e) {
//       return "Network error: $e";
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final String sdgId = widget.sdgNumber.toString();

//     return Scaffold(
//       appBar: AppBar(
//         title: Text("SDG $sdgId"),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//         backgroundColor: Colors.green[600],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('lessons')
//             .where('sdgId', isEqualTo: sdgId)
//             .where('status', isEqualTo: "Published") // 👈 only published
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text("No published lessons available for this SDG yet."),
//             );
//           }
//           var lesson = snapshot.data!.docs.first; // one lesson per SDG
//           var data = lesson.data() as Map<String, dynamic>;
//           String docId = lesson.id;

//           _controllers.putIfAbsent(docId, () => TextEditingController());

//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 data['image'] != null && data['image'].toString().isNotEmpty
//                     ? (() {
//                         try {
//                           final String imageData = data['image'].toString();

//                           // Check if it's a base64 string
//                           if (imageData.startsWith('data:image') ||
//                               !imageData.startsWith('http')) {
//                             String base64String = imageData;
//                             if (base64String.contains(',')) {
//                               base64String = base64String.split(',')[1];
//                             }

//                             Uint8List bytes = base64Decode(base64String);

//                             return Image.memory(
//                               bytes,
//                               height: 200,
//                               width: double.infinity,
//                               fit: BoxFit.cover,
//                             );
//                           } else {
//                             // Treat as normal URL
//                             return Image.network(
//                               imageData,
//                               height: 200,
//                               width: double.infinity,
//                               fit: BoxFit.cover,
//                               errorBuilder: (context, error, stackTrace) {
//                                 return const Icon(Icons.broken_image,
//                                     size: 100, color: Colors.grey);
//                               },
//                             );
//                           }
//                         } catch (e) {
//                           return const Icon(Icons.broken_image,
//                               size: 100, color: Colors.grey);
//                         }
//                       })()
//                     : const Icon(Icons.image, size: 100, color: Colors.grey),
//                 const SizedBox(height: 12),
//                 Text(
//                   data['title'] ?? '',
//                   style: const TextStyle(
//                       fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   data['description'] ?? '',
//                   style: const TextStyle(fontSize: 16),
//                   textAlign: TextAlign.left,
//                 ),
//                 const SizedBox(height: 12),
//                 if (data['activities'] != null && data['activities'] is List)
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         "Activities:",
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           fontStyle: FontStyle.normal,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       ...List<Widget>.generate(
//                         (data['activities'] as List).length,
//                         (index) {
//                           String activity = (data['activities'] as List)[index];
//                           List<String> parts = activity
//                               .split(RegExp(r'\s*:\s*', caseSensitive: false));
//                           String title = parts.isNotEmpty ? parts[0] : '';
//                           String description = parts.length > 1
//                               ? parts.sublist(1).join(': ')
//                               : '';

//                           return Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 2),
//                             child: RichText(
//                               textAlign: TextAlign.left,
//                               text: TextSpan(
//                                 style: const TextStyle(
//                                   fontSize: 15,
//                                   height: 1.5,
//                                   fontStyle: FontStyle.normal,
//                                   color: Colors.black,
//                                 ),
//                                 children: [
//                                   TextSpan(
//                                     text: "${index + 1}. $title: ",
//                                     style: const TextStyle(
//                                         fontWeight: FontWeight.bold),
//                                   ),
//                                   TextSpan(
//                                     text: description,
//                                     style: const TextStyle(
//                                         fontWeight: FontWeight.normal),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 const SizedBox(height: 16),
//                 if (data['interactiveQuestion'] != null) ...[
//                   Text(
//                     data['interactiveQuestion'],
//                     style: const TextStyle(
//                         fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: _controllers[docId],
//                     decoration: const InputDecoration(
//                       hintText: "Write your Answer here...",
//                       border: OutlineInputBorder(),
//                     ),
//                     maxLines: 3,
//                   ),
//                   const SizedBox(height: 8),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green, // ✅ Always green
//                       foregroundColor:
//                           Colors.white, // ✅ White text for contrast
//                     ),
//                     onPressed: (!_isSubmitting && canRespond)
//                         ? () async {
//                             String answer = _controllers[docId]!.text.trim();
//                             firebase_auth.User? user =
//                                 firebase_auth.FirebaseAuth.instance.currentUser;

//                             if (answer.isEmpty || user == null) return;

//                             setState(() {
//                               _isSubmitting = true;
//                             });

//                             final answersRef = FirebaseFirestore.instance
//                                 .collection('answers');

//                             // Fetch existing answers
//                             final existingSnapshot = await answersRef
//                                 .where('userId', isEqualTo: user.uid)
//                                 .where('sdgId', isEqualTo: docId)
//                                 .get();

//                             if (existingSnapshot.docs.length < 2) {
//                               if (existingSnapshot.docs.isNotEmpty) {
//                                 // Update the first existing answer
//                                 final docIdToUpdate =
//                                     existingSnapshot.docs.first.id;
//                                 await answersRef.doc(docIdToUpdate).update({
//                                   'response': answer,
//                                   'updatedAt': FieldValue.serverTimestamp(),
//                                 });
//                               } else {
//                                 // Add new answer
//                                 await answersRef.add({
//                                   'userId': user.uid,
//                                   'sdgId': docId,
//                                   'response': answer,
//                                   'timestamp': FieldValue.serverTimestamp(),
//                                   'updatedAt': FieldValue.serverTimestamp(),
//                                 });
//                               }

//                               // Call AI to analyze response
//                               String feedback = await analyzeWithAI(
//                                 question: data['interactiveQuestion'],
//                                 userResponse: answer,
//                               );

//                               // --- classify quality based on AI feedback ---
//                               String quality;
//                               if (feedback.toLowerCase().contains("good")) {
//                                 quality = "good";
//                               } else if (feedback
//                                   .toLowerCase()
//                                   .contains("partial")) {
//                                 quality = "partial";
//                               } else {
//                                 quality = "poor";
//                               }

//                               // --- calculate dynamic percentage ---
//                               int percentage = calculatePercentage(
//                                 opened: true, // user opened this SDG
//                                 readMinutes:
//                                     6, // TODO: replace with real reading time
//                                 responded: true, // user submitted an answer
//                                 quality: quality, // from AI
//                               );

//                               // --- save progress in Firestore ---
//                               final docRef = FirebaseFirestore.instance
//                                   .collection('progress')
//                                   .doc(user.uid);

//                               await docRef.set({
//                                 'userId': user.uid,
//                                 'sdgs.$sdgId': {
//                                   'opened': true,
//                                   'readMinutes':
//                                       6, // TODO: replace with real timer
//                                   'responded': true,
//                                   'responseQuality': quality,
//                                   'percentage': percentage,
//                                   'updatedAt': FieldValue.serverTimestamp(),
//                                 }
//                               }, SetOptions(merge: true));

//                               // --- show feedback to user ---
//                               if (!mounted) return;
//                               showDialog(
//                                 context: context,
//                                 builder: (context) => AlertDialog(
//                                   title: const Text("Feedback"),
//                                   content: Text(feedback),
//                                   actions: [
//                                     TextButton(
//                                       onPressed: () => Navigator.pop(context),
//                                       child: const Text("OK"),
//                                     )
//                                   ],
//                                 ),
//                               );

//                               _controllers[docId]!.clear();
//                             }

//                             // Refresh responses count
//                             await _checkResponses(docId);

//                             setState(() {
//                               _isSubmitting = false;
//                             });
//                           }
//                         : null,
//                     child: Text(_isSubmitting ? "Submitting..." : "Submit"),
//                   ),
//                 ],
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// int calculatePercentage({
//   required bool opened,
//   required int readMinutes,
//   required bool responded,
//   required String quality,
// }) {
//   int score = 0;

//   if (opened) score += 10;

//   if (readMinutes >= 5) {
//     score += 30;
//   } else if (readMinutes > 0) {
//     score += 10;
//   }

//   if (responded) score += 20;

//   if (quality == "good") {
//     score += 40;
//   } else if (quality == "partial") {
//     score += 20;
//   } else if (quality == "poor") {
//     score += 10;
//   }

//   return score.clamp(0, 100);
// }

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// import 'package:http/http.dart' as http;
// import 'package:openai_dart/openai_dart.dart' as openai;
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:openai_dart/openai_dart.dart' hide Image;
// import 'Services/lesson_service.dart';

// class DetailsScreen extends StatefulWidget {
//   final int sdgNumber;
//   const DetailsScreen({
//     super.key,
//     required this.sdgNumber,
//   });
//   @override
//   State<DetailsScreen> createState() => _DetailsScreenState();
// }

// class _DetailsScreenState extends State<DetailsScreen> {
//   int responsesCount = 0;
//   bool canRespond = true;
//   bool _hasCheckedResponses = false;

//   // Track reading time
//   DateTime? _startTime;
//   int _readMinutes = 0;

//   final Map<String, TextEditingController> _controllers = {};
//   bool _isSubmitting = false;
//   final client = OpenAIClient(apiKey: dotenv.env['OPENAI_API_KEY']!);

//   String? _docId;

//   @override
//   void initState() {
//     super.initState();
//     _startTime = DateTime.now(); // ✅ start tracking reading time
//     _initializeLesson(); // ✅ make sure to call this
//   }

//   Future<void> markOpened(String sdgId) async {
//     final user = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final duration = DateTime.now().difference(_startTime ?? DateTime.now());
//     _readMinutes = duration.inMinutes;

//     // 🔹 1) Update global lesson counters
//     await LessonService.updateLessonCounts(
//       sdgNumber: widget.sdgNumber,
//       updates: {
//         'accessCount': FieldValue.increment(1),
//         if (_readMinutes >= 5) 'read5minCount': FieldValue.increment(1),
//         'updatedAt': FieldValue.serverTimestamp(),
//       },
//     );
//   }

//   Future<void> _initializeLesson() async {
//     final snapshot = await FirebaseFirestore.instance
//         .collection('lessons')
//         .where('sdgId', isEqualTo: widget.sdgNumber.toString())
//         .limit(1)
//         .get();
//     if (snapshot.docs.isNotEmpty) {
//       final lesson = snapshot.docs.first;
//       _docId = lesson.id;
//       _controllers.putIfAbsent(_docId!, () => TextEditingController());
//       await _checkResponses(_docId!);
//       setState(() {});
//     }
//     if (_docId != null) {
//       await markOpened(widget.sdgNumber.toString());
//     }
//   }

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

//   Future<void> _checkResponses(String docId) async {
//     final user = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final answersSnapshot = await FirebaseFirestore.instance
//         .collection('answers')
//         .where('userId', isEqualTo: user.uid)
//         .where('sdgId', isEqualTo: docId)
//         .get();
//   }

//   Future<String> analyzeWithAI({
//     required String question,
//     required String userResponse,
//   }) async {
//     final apiKey = dotenv.env['OPENAI_API_KEY'];

//     if (apiKey == null || apiKey.isEmpty) {
//       return "API key is missing. Please set your OpenAI API key in .env";
//     }

//     if (userResponse.trim().length < 20) {
//       return "Good start! Try writing a more detailed answer for better feedback.";
//     }

//     // Check Firestore cache
//     final cached = await FirebaseFirestore.instance
//         .collection('feedbackCache')
//         .where('question', isEqualTo: question)
//         .where('response', isEqualTo: userResponse)
//         .limit(1)
//         .get();
//     if (cached.docs.isNotEmpty) {
//       return cached.docs.first['feedback'];
//     }

//     final url = Uri.parse("https://api.openai.com/v1/chat/completions");
//     final body = {
//       "model": "gpt-3.5-turbo",
//       "messages": [
//         {
//           "role": "system",
//           "content": """
// You are an SDG learning assistant for Rwandan users.
// 1) Give clear feedback if the answer is good, partial, or poor.
// 2) Always provide encouragement, tips, or local examples related to Rwanda to help the user learn.
// 3) If the user's answer is partial or poor, motivate them to reflect, study, or improve their understanding for next time.
// 4) Do NOT ask the user any new question.
// Keep feedback friendly, concise, and actionable.
// """
//         },
//         {
//           "role": "user",
//           "content":
//               "Question: $question\nAnswer: $userResponse\nProvide feedback following the instructions above."
//         }
//       ],
//       "max_tokens": 250,
//     };

//     final headers = {
//       "Content-Type": "application/json",
//       "Authorization": "Bearer $apiKey",
//     };

//     try {
//       final res =
//           await http.post(url, headers: headers, body: jsonEncode(body));
//       if (res.statusCode == 200) {
//         final decoded = jsonDecode(res.body);
//         if (decoded["choices"] != null && decoded["choices"].isNotEmpty) {
//           final feedback = decoded["choices"][0]["message"]["content"];
//           await FirebaseFirestore.instance.collection('feedbackCache').add({
//             'question': question,
//             'response': userResponse,
//             'feedback': feedback,
//             'timestamp': FieldValue.serverTimestamp(),
//           });
//           return feedback;
//         } else {
//           return "Unexpected response format from OpenAI.";
//         }
//       } else {
//         return "Error ${res.statusCode}: ${res.body}";
//       }
//     } catch (e) {
//       return "Network error: $e";
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final String sdgId = widget.sdgNumber.toString();

//     return Scaffold(
//       appBar: AppBar(
//         title: Text("SDG $sdgId"),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//         backgroundColor: Colors.green[600],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('lessons')
//             .where('sdgId', isEqualTo: sdgId)
//             .where('status', isEqualTo: "Published") // 👈 only published
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text("No published lessons available for this SDG yet."),
//             );
//           }
//           var lesson = snapshot.data!.docs.first; // one lesson per SDG
//           var data = lesson.data() as Map<String, dynamic>;
//           String docId = lesson.id;

//           _controllers.putIfAbsent(docId, () => TextEditingController());

//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 data['image'] != null && data['image'].toString().isNotEmpty
//                     ? (() {
//                         try {
//                           final String imageData = data['image'].toString();

//                           // Check if it's a base64 string
//                           if (imageData.startsWith('data:image') ||
//                               !imageData.startsWith('http')) {
//                             String base64String = imageData;
//                             if (base64String.contains(',')) {
//                               base64String = base64String.split(',')[1];
//                             }

//                             Uint8List bytes = base64Decode(base64String);

//                             return Image.memory(
//                               bytes,
//                               height: 200,
//                               width: double.infinity,
//                               fit: BoxFit.cover,
//                             );
//                           } else {
//                             // Treat as normal URL
//                             return Image.network(
//                               imageData,
//                               height: 200,
//                               width: double.infinity,
//                               fit: BoxFit.cover,
//                               errorBuilder: (context, error, stackTrace) {
//                                 return const Icon(Icons.broken_image,
//                                     size: 100, color: Colors.grey);
//                               },
//                             );
//                           }
//                         } catch (e) {
//                           return const Icon(Icons.broken_image,
//                               size: 100, color: Colors.grey);
//                         }
//                       })()
//                     : const Icon(Icons.image, size: 100, color: Colors.grey),
//                 const SizedBox(height: 12),
//                 Text(
//                   data['title'] ?? '',
//                   style: const TextStyle(
//                       fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   data['description'] ?? '',
//                   style: const TextStyle(fontSize: 16),
//                   textAlign: TextAlign.left,
//                 ),
//                 const SizedBox(height: 12),
//                 if (data['activities'] != null && data['activities'] is List)
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         "Activities:",
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           fontStyle: FontStyle.normal,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       ...List<Widget>.generate(
//                         (data['activities'] as List).length,
//                         (index) {
//                           String activity = (data['activities'] as List)[index];
//                           List<String> parts = activity
//                               .split(RegExp(r'\s*:\s*', caseSensitive: false));
//                           String title = parts.isNotEmpty ? parts[0] : '';
//                           String description = parts.length > 1
//                               ? parts.sublist(1).join(': ')
//                               : '';

//                           return Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 2),
//                             child: RichText(
//                               textAlign: TextAlign.left,
//                               text: TextSpan(
//                                 style: const TextStyle(
//                                   fontSize: 15,
//                                   height: 1.5,
//                                   fontStyle: FontStyle.normal,
//                                   color: Colors.black,
//                                 ),
//                                 children: [
//                                   TextSpan(
//                                     text: "${index + 1}. $title: ",
//                                     style: const TextStyle(
//                                         fontWeight: FontWeight.bold),
//                                   ),
//                                   TextSpan(
//                                     text: description,
//                                     style: const TextStyle(
//                                         fontWeight: FontWeight.normal),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 const SizedBox(height: 16),
//                 if (data['interactiveQuestion'] != null) ...[
//                   Text(
//                     data['interactiveQuestion'],
//                     style: const TextStyle(
//                         fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: _controllers[docId],
//                     decoration: const InputDecoration(
//                       hintText: "Write your Answer here...",
//                       border: OutlineInputBorder(),
//                     ),
//                     maxLines: 3,
//                   ),
//                   const SizedBox(height: 8),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green, // ✅ Always green
//                       foregroundColor:
//                           Colors.white, // ✅ White text for contrast
//                     ),
//                     onPressed: (!_isSubmitting && canRespond)
//                         ? () async {
//                             String answer = _controllers[docId]!.text.trim();
//                             firebase_auth.User? user =
//                                 firebase_auth.FirebaseAuth.instance.currentUser;

//                             if (answer.isEmpty || user == null) return;

//                             setState(() {
//                               _isSubmitting = true;
//                             });

//                             final answersRef = FirebaseFirestore.instance
//                                 .collection('answers');

//                             // Fetch existing answers
//                             final existingSnapshot = await answersRef
//                                 .where('userId', isEqualTo: user.uid)
//                                 .where('sdgId', isEqualTo: sdgId)
//                                 .get();

//                             if (_startTime != null) {
//                               final duration =
//                                   DateTime.now().difference(_startTime!);
//                               _readMinutes = duration.inMinutes;
//                             }

//                             if (existingSnapshot.docs.length < 2) {
//                               if (existingSnapshot.docs.isNotEmpty) {
//                                 // Update the first existing answer
//                                 final docIdToUpdate =
//                                     existingSnapshot.docs.first.id;
//                                 await answersRef.doc(docIdToUpdate).update({
//                                   'response': answer,
//                                   'updatedAt': FieldValue.serverTimestamp(),
//                                 });
//                               } else {
//                                 // Add new answer
//                                 await answersRef.add({
//                                   'userId': user.uid,
//                                   // 'sdgId': docId,
//                                   'sdgId': sdgId,
//                                   'response': answer,
//                                   'timestamp': FieldValue.serverTimestamp(),
//                                   'updatedAt': FieldValue.serverTimestamp(),
//                                 });
//                               }

//                               // Call AI to analyze response
//                               String feedback = await analyzeWithAI(
//                                 question: data['interactiveQuestion'],
//                                 userResponse: answer,
//                               );

//                               // --- classify quality based on AI feedback ---
//                               String quality;
//                               if (feedback.toLowerCase().contains("good")) {
//                                 quality = "good";
//                               } else if (feedback
//                                   .toLowerCase()
//                                   .contains("partial")) {
//                                 quality = "partial";
//                               } else {
//                                 quality = "poor";
//                               }

//                               // --- calculate dynamic percentage ---
//                               int percentage = calculatePercentage(
//                                 opened: true, // user opened this SDG
//                                 readMinutes: _readMinutes,
//                                 responded: true, // user submitted an answer
//                                 quality: quality, // from AI
//                               );

//                               final docRef = FirebaseFirestore.instance
//                                   .collection('progress')
//                                   .doc(user.uid);

//                               await docRef.set({
//                                 'userId': user.uid,
//                                 'sdgs.$sdgId': {
//                                   'opened': true,
//                                   'readMinutes': _readMinutes,
//                                   'responded': true,
//                                   'responseQuality': quality,
//                                   'percentage': percentage,
//                                   'updatedAt': FieldValue.serverTimestamp(),
//                                 }
//                               }, SetOptions(merge: true));
//                               // When lesson is opened
//                               await LessonService.updateLessonCounts(
//                                 sdgNumber: widget.sdgNumber,
//                                 updates: {
//                                   'accessCount': FieldValue.increment(1),
//                                   'updatedAt': FieldValue.serverTimestamp(),
//                                 },
//                               );
//                               await LessonService.updateLessonCounts(
//                                 sdgNumber: widget.sdgNumber,
//                                 updates: {
//                                   'read5minCount': FieldValue.increment(1),
//                                   'updatedAt': FieldValue.serverTimestamp(),
//                                 },
//                               );
//                               await LessonService.updateLessonCounts(
//                                 sdgNumber: widget.sdgNumber,
//                                 updates: {
//                                   'respondedCount': FieldValue.increment(1),
//                                   'goodResponseCount': FieldValue.increment(
//                                       quality == "good" ? 1 : 0),
//                                   'poorResponseCount': FieldValue.increment(
//                                       quality == "poor" ? 1 : 0),
//                                   'updatedAt': FieldValue.serverTimestamp(),
//                                 },
//                               );

//                               // await LessonService.updateLessonCounts(
//                               //   sdgNumber: widget.sdgNumber,
//                               //   updates: {
//                               //     'respondedCount': FieldValue.increment(1),
//                               //     if (quality == 'good')
//                               //       'goodResponseCount':
//                               //           FieldValue.increment(1),
//                               //     if (quality == 'poor')
//                               //       'poorResponseCount':
//                               //           FieldValue.increment(1),
//                               //     if (quality == 'partial')
//                               //       'partialResponseCount':
//                               //           FieldValue.increment(1),
//                               //     'updatedAt': FieldValue.serverTimestamp(),
//                               //   },
//                               // );
//                               await LessonService.updateLessonCounts(
//                                 sdgNumber: widget.sdgNumber,
//                                 updates: {
//                                   'respondedCount': FieldValue.increment(1),
//                                   if (quality == 'good')
//                                     'goodResponseCount':
//                                         FieldValue.increment(1),
//                                   if (quality == 'poor')
//                                     'poorResponseCount':
//                                         FieldValue.increment(1),
//                                   if (quality == 'partial')
//                                     'partialResponseCount':
//                                         FieldValue.increment(1),
//                                   'updatedAt': FieldValue.serverTimestamp(),
//                                 },
//                               );

//                               // Update per-user progress (inside progress/{uid})

//                               // --- show feedback to user ---
//                               if (!mounted) return;
//                               showDialog(
//                                 context: context,
//                                 builder: (context) => AlertDialog(
//                                   title: const Text("Feedback"),
//                                   content: Text(feedback),
//                                   actions: [
//                                     TextButton(
//                                       onPressed: () => Navigator.pop(context),
//                                       child: const Text("OK"),
//                                     )
//                                   ],
//                                 ),
//                               );

//                               _controllers[docId]!.clear();
//                             }

//                             // Refresh responses count
//                             await _checkResponses(docId);

//                             setState(() {
//                               _isSubmitting = false;
//                             });
//                           }
//                         : null,
//                     child: Text(_isSubmitting ? "Submitting..." : "Submit"),
//                   ),
//                 ],
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// int calculatePercentage({
//   required bool opened,
//   required int readMinutes,
//   required bool responded,
//   required String quality, // "good", "poor", "partial", "none"
// }) {
//   int score = 0;

//   if (opened) score += 10;

//   if (readMinutes >= 5) {
//     score += 25;
//   } else if (readMinutes > 0) {
//     score += 10;
//   }

//   if (responded) score += 25;

//   if (responded) {
//     if (quality.toLowerCase() == "good")
//       score += 40;
//     else if (quality.toLowerCase() == "partial")
//       score += 30;
//     else if (quality.toLowerCase() == "poor") score += 20;
//   }

//   // ✅ Give minimum 10% if user opened, even without submitting
//   if (!responded && opened && score == 0) score = 10;

//   return score.clamp(0, 100);
// }
