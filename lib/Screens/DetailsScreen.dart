// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// import 'package:http/http.dart' as http;

// import 'package:flutter_dotenv/flutter_dotenv.dart';

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

//   final Map<String, TextEditingController> _controllers = {};
//   bool _isSubmitting = false;
//   // final client = OpenAIClient(apiKey: dotenv.env['OPENAI_API_KEY']!);

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

//     // setState(() {
//     //   responsesCount = answersSnapshot.docs.length;
//     //   canRespond = responsesCount < 2; // max 2 responses allowed
//     // });
//   }

//   Future<String> analyzeWithAI({
//     required String question,
//     required String userResponse,
//   }) async {
//     final apiKey =
//         dotenv.env['HUGGINGFACE_API_KEY']; // Your Hugging Face API key

//     if (apiKey == null || apiKey.isEmpty) {
//       return "API key is missing. Please set your Hugging Face API key.";
//     }

//     // Quick tip for very short responses
//     if (userResponse.trim().length < 20) {
//       return "Good start! Try adding more details to get better feedback.";
//     }

//     final url = Uri.parse(
//         "https://api-inference.huggingface.co/models/openai/gpt-oss-20b");

//     final prompt = """
// You are an SDG learning assistant.
// Always be encouraging, clear, and give friendly suggestions for improvement.
// Never just say 'needs improvement'; explain why and suggest improvements in a friendly way.

// Question: $question
// User Response: $userResponse

// Give feedback as a friendly message: highlight if it is good, partially good, or needs improvement, but embed this inside a message with suggestions for improvement.
// """;

//     final headers = {
//       "Authorization": "Bearer $apiKey",
//       "Content-Type": "application/json",
//     };

//     final body = jsonEncode({
//       "inputs": prompt,
//       "parameters": {"max_new_tokens": 250, "temperature": 0.7}
//     });

//     int retryCount = 0;
//     int delaySeconds = 2;

//     while (retryCount < 3) {
//       try {
//         final res = await http.post(url, headers: headers, body: body);

//         if (res.statusCode == 200) {
//           final decoded = jsonDecode(res.body);

//           final feedback = decoded is List && decoded.isNotEmpty
//               ? (decoded[0]['generated_text'] ??
//                   decoded[0]['summary_text'] ??
//                   decoded[0].values.first ??
//                   "AI response format not recognized.")
//               : "Could not parse AI response.";

//           // Save feedback in Firestore cache
//           await FirebaseFirestore.instance.collection('feedbackCache').add({
//             'response': userResponse,
//             'feedback': feedback,
//             'timestamp': FieldValue.serverTimestamp(),
//           });

//           return feedback;
//         } else if (res.statusCode == 503) {
//           // Model is loading or busy
//           await Future.delayed(Duration(seconds: delaySeconds));
//           delaySeconds *= 2;
//           retryCount++;
//         } else {
//           return "Error ${res.statusCode}: ${res.body}";
//         }
//       } catch (e) {
//         retryCount++;
//         await Future.delayed(Duration(seconds: delaySeconds));
//         delaySeconds *= 2;
//         if (retryCount >= 3) {
//           return "Failed to get feedback from AI: $e";
//         }
//       }
//     }

//     return "Too many requests. Please try again shortly.";
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
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text("No lessons available for this SDG yet."),
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
//                           // Split title and description at first colon
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

    // setState(() {
    //   responsesCount = answersSnapshot.docs.length;
    //   canRespond = responsesCount < 2; // max 2 responses allowed
    // });
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
          "content":
              "Question: $question\nAnswer: $userResponse\nPlease provide friendly feedback in JSON format."
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
