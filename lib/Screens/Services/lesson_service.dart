import 'package:cloud_firestore/cloud_firestore.dart';

class LessonService {
  static Future<void> updateLessonCounts({
    required int sdgNumber,
    required Map<String, dynamic> updates,
  }) async {
    final firestore = FirebaseFirestore.instance;

    // Find lesson by sdgNumber field
    final query = await firestore
        .collection('lessons')
        .where('sdgNumber', isEqualTo: sdgNumber)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      print("⚠️ No lesson found for SDG $sdgNumber");
      return;
    }

    final lessonRef = query.docs.first.reference;

    // Apply incremental updates
    await lessonRef.update(updates);

    // Re-fetch lesson after update
    final snapshot = await lessonRef.get();
    final data = snapshot.data() as Map<String, dynamic>? ?? {};

    final int accessCount = (data['accessCount'] ?? 0) as int;
    final int read5minCount = (data['read5minCount'] ?? 0) as int;
    final int respondedCount = (data['respondedCount'] ?? 0) as int;
    final int goodResponseCount = (data['goodResponseCount'] ?? 0) as int;
    final int partialResponseCount = (data['partialResponseCount'] ?? 0) as int;
    final int poorResponseCount = (data['poorResponseCount'] ?? 0) as int;

    // ----- Progress Calculation -----
    int totalUsers = accessCount; // every access is at least 1 user
    if (totalUsers == 0) {
      await lessonRef.update({'avgProgress': 0});
      return;
    }

    int totalPoints = 0;

    // Base points
    totalPoints += accessCount * 10;
    totalPoints += read5minCount * 25;
    totalPoints += respondedCount * 25;

    // Quality
    totalPoints += goodResponseCount * 40;
    totalPoints += partialResponseCount * 30;
    totalPoints += poorResponseCount * 20;

    // Average progress (0–100)
    int avgProgress = (totalPoints ~/ totalUsers).clamp(0, 100);

    await lessonRef.update({'avgProgress': avgProgress});
  }
}
