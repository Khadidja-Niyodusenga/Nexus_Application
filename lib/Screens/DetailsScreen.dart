import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'Services/lesson_service.dart';
import 'dart:async';
import 'Services/user_service.dart';
import 'package:flutter/services.dart';

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
  Timer? _readTimer;
  static final Map<int, Map<String, dynamic>> _lessonCache = {};
  static final Map<int, String> _docIdCache = {};
  final _formKey = GlobalKey<FormState>();
  int responsesCount = 0;
  bool canRespond = true;
  bool _hasCheckedResponses = false;
  DateTime? _startTime;
  int _readMinutes = 0;
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;

  String? _docId;
  Future<void> _initializeLesson() async {
    if (_lessonCache.containsKey(widget.sdgNumber)) {
      _cachedLessonData = _lessonCache[widget.sdgNumber];
      _cachedDocId = _docIdCache[widget.sdgNumber];
      if (_cachedDocId != null && _cachedDocId!.isNotEmpty) {
        _controllers.putIfAbsent(_cachedDocId!, () => TextEditingController());
        await _checkResponses(_cachedDocId!);
      }
      return;
    }
    try {
      final startTime = DateTime.now();
      final snapshot = await FirebaseFirestore.instance
          .collection('lessons')
          .where('sdgId', isEqualTo: widget.sdgNumber.toString())
          .where('status', isEqualTo: "Published")
          .limit(1)
          .get();
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      print('Lesson query took: $duration ms for SDG ${widget.sdgNumber}');
      if (snapshot.docs.isNotEmpty) {
        _cachedDocId = snapshot.docs.first.id;
        _cachedLessonData = snapshot.docs.first.data() as Map<String, dynamic>;
        _lessonCache[widget.sdgNumber] = _cachedLessonData!;
        _docIdCache[widget.sdgNumber] = _cachedDocId!;
        _controllers.putIfAbsent(_cachedDocId!, () => TextEditingController());
        await _checkResponses(_cachedDocId!);
      } else {
        _cachedLessonData = {};
        _cachedDocId = '';
        _lessonCache[widget.sdgNumber] = {};
        _docIdCache[widget.sdgNumber] = '';
      }
    } catch (e) {
      print('Error in _initializeLesson: $e');
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

    setState(() {
      responsesCount = answersSnapshot.docs.length;
      canRespond = answersSnapshot.docs.length < 2;
      _hasCheckedResponses = true;
    });
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

  void _startReadTimer() {
    _readTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        _readMinutes += 1;
        print('readMinutes incremented to: $_readMinutes'); // Debug print
      });
    });
  }

  void _stopReadTimer() {
    _readTimer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    _initializeLesson(); // already in your code
    _startReadTimer();
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      UserService.updateLastActive(user.uid);
    } // NEW: start counting read minutes
  }

  Map<String, dynamic>? _cachedLessonData;
  String? _cachedDocId;
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _lessonCache.containsKey(widget.sdgNumber)
            ? Future.value(_lessonCache[widget.sdgNumber]!)
            : FirebaseFirestore.instance
                .collection('lessons')
                .where('sdgId', isEqualTo: sdgId)
                .where('status', isEqualTo: "Published")
                .limit(1)
                .get()
                .then((snapshot) async {
                if (snapshot.docs.isEmpty) {
                  _lessonCache[widget.sdgNumber] = {};
                  _docIdCache[widget.sdgNumber] = '';
                  return {};
                }
                final data = snapshot.docs.first.data() as Map<String, dynamic>;
                _lessonCache[widget.sdgNumber] = data;
                _docIdCache[widget.sdgNumber] = snapshot.docs.first.id;
                return data;
              }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No published lessons available for this SDG yet."),
            );
          }
          var data = snapshot.data!;
          String docId = _docIdCache[widget.sdgNumber] ?? '';
          _cachedLessonData ??= data;
          _cachedDocId ??= docId;
          if (docId.isNotEmpty) {
            _controllers.putIfAbsent(docId, () => TextEditingController());
          }
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
                SelectableText.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      height: 1.5,
                    ),
                    children: [
                      // Title
                      TextSpan(
                        text: (data['title'] ?? '') + '\n\n',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Description
                      TextSpan(
                        text: (data['description'] ?? '') + '\n\n',
                        style: const TextStyle(fontSize: 16),
                      ),
                      // Activities Header
                      if (data['activities'] != null &&
                          data['activities'] is List)
                        const TextSpan(
                          text: 'Activities:\n',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      // Activities List
                      if (data['activities'] != null &&
                          data['activities'] is List)
                        ...List<TextSpan>.generate(
                          (data['activities'] as List).length,
                          (index) {
                            String activity =
                                (data['activities'] as List)[index];
                            List<String> parts = activity.split(
                                RegExp(r'\s*:\s*', caseSensitive: false));
                            String title = parts.isNotEmpty ? parts[0] : '';
                            String description = parts.length > 1
                                ? parts.sublist(1).join(': ')
                                : '';
                            return TextSpan(
                              children: [
                                TextSpan(
                                  text: '${index + 1}. $title: ',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: '$description\n',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal),
                                ),
                              ],
                            );
                          },
                        ),
                      // Interactive Question
                      if (data['interactiveQuestion'] != null)
                        TextSpan(
                          text: '\n' + (data['interactiveQuestion'] ?? ''),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 8),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _controllers[docId],
                    decoration: const InputDecoration(
                      hintText: "Write your answer here (min 20 characters)...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    inputFormatters: [
                      // Allow only letters (a–z, A–Z), digits (0–9), and spaces
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9\s]')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().length < 20) {
                        return "Answer must be at least 20 characters.";
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // ✅ Always green
                    foregroundColor: Colors.white, // ✅ White text for contrast
                  ),
                  onPressed: (!_isSubmitting && canRespond)
                      ? () async {
                          if (!_formKey.currentState!.validate()) {
                            return; // Stop if less than 20 chars
                          }
                          String answer = _controllers[docId]!.text.trim();
                          firebase_auth.User? user =
                              firebase_auth.FirebaseAuth.instance.currentUser;

                          if (answer.isEmpty || user == null) return;
                          await UserService.updateLastActive(user.uid);
                          setState(() {
                            _isSubmitting = true;
                          });

                          final answersRef =
                              FirebaseFirestore.instance.collection('answers');
                          final progressQuery = await FirebaseFirestore.instance
                              .collection('progress')
                              .where('userId', isEqualTo: user.uid)
                              .limit(1)
                              .get();
                          DocumentReference progressRef;
                          if (progressQuery.docs.isEmpty) {
                            progressRef = FirebaseFirestore.instance
                                .collection('progress')
                                .doc();
                          } else {
                            progressRef = progressQuery.docs.first.reference;
                          }

                          try {
                            String feedback = '';
                            String quality = 'none';
                            bool submitted = false;

                            await FirebaseFirestore.instance
                                .runTransaction((txn) async {
                              // Fetch existing answers
                              final existingSnapshot = await answersRef
                                  .where('userId', isEqualTo: user.uid)
                                  .where('sdgId', isEqualTo: docId)
                                  .get();

                              if (existingSnapshot.docs.length < 2) {
                                submitted = true;
                                if (existingSnapshot.docs.isNotEmpty) {
                                  // Update the first existing answer
                                  final docIdToUpdate =
                                      existingSnapshot.docs.first.id;
                                  txn.update(answersRef.doc(docIdToUpdate), {
                                    'response': answer,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });
                                } else {
                                  // Add new answer
                                  txn.set(answersRef.doc(), {
                                    'userId': user.uid,
                                    'sdgId': docId,
                                    'response': answer,
                                    'timestamp': FieldValue.serverTimestamp(),
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });
                                }

                                // Fetch progress data
                                final progressSnap = await progressRef.get();
                                final progressData = progressSnap.exists
                                    ? progressSnap.data()
                                        as Map<String, dynamic>
                                    : {};
                                final sdgsMap = Map<String, dynamic>.from(
                                    progressData['sdgs'] ?? {});
                                final sdgData = Map<String, dynamic>.from(
                                    sdgsMap[widget.sdgNumber.toString()] ??
                                        {
                                          'opened': false,
                                          'readCounted': false,
                                          'readMinutes': 0,
                                          'responded': false,
                                          'responseQuality': 'none',
                                          'percentage': 0,
                                          'updatedAt':
                                              FieldValue.serverTimestamp(),
                                        });

                                // Call AI to analyze response
                                feedback = await analyzeWithAI(
                                  question: data['interactiveQuestion'],
                                  userResponse: answer,
                                );

                                // Classify quality
                                quality = feedback
                                        .toLowerCase()
                                        .contains("good")
                                    ? "good"
                                    : feedback.toLowerCase().contains("partial")
                                        ? "partial"
                                        : "poor";

                                sdgData['opened'] = true;
                                sdgData['readCounted'] = true;
                                sdgData['readMinutes'] = _readMinutes;
                                sdgData['responded'] = true;
                                sdgData['responseQuality'] = quality;
                                sdgData['percentage'] = calculatePercentage(
                                  opened: true,
                                  readMinutes: _readMinutes,
                                  responded: true,
                                  quality: quality,
                                );
                                sdgData['updatedAt'] =
                                    FieldValue.serverTimestamp();
                                sdgsMap[widget.sdgNumber.toString()] = sdgData;

                                txn.set(
                                  progressRef,
                                  {
                                    'userId': user.uid,
                                    'sdgs': sdgsMap,
                                  },
                                  SetOptions(merge: true),
                                );
                              }
                            });

                            if (submitted) {
                              // Update lesson counts using LessonService
                              await LessonService.updateLessonCounts(
                                sdgNumber: widget.sdgNumber,
                                userId: user.uid,
                                newQuality: quality,
                                responded: true,
                                readMinutes: _readMinutes,
                              );

                              if (!mounted) return;
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Feedback"),
                                  content: Text(feedback),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _showThankYouDialog();
                                      },
                                      child: const Text("OK"),
                                    ),
                                  ],
                                ),
                              );

                              _controllers[docId]!.clear();
                              await _checkResponses(docId);
                              _stopReadTimer();
                            } else {
                              if (!mounted) return;
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Response Limit Reached"),
                                  content: const Text(
                                      "You have already submitted the maximum number of responses (2)."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("OK"),
                                    ),
                                  ],
                                ),
                              );
                            }

                            setState(() {
                              _isSubmitting = false;
                            });
                          } catch (e) {
                            print('Error in DetailsScreen onPressed: $e');
                            if (!mounted) return;
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Error"),
                                content: const Text(
                                    "Failed to submit answer. Please try again."),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("OK"),
                                  ),
                                ],
                              ),
                            );
                            setState(() {
                              _isSubmitting = false;
                            });
                          }
                        }
                      : null,
                  child: Text(_isSubmitting ? "Submitting..." : "Submit"),
                ),
              ],
              //],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _readTimer?.cancel(); // stop timer
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
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
