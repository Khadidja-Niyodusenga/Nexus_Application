import 'package:cloud_firestore/cloud_firestore.dart';

class LessonService {
  static Future<void> updateLessonCounts({
    required int sdgNumber,
    required String userId,
    required String newQuality,
    required bool responded,
    required int readMinutes,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final lessonQuery = await firestore
        .collection('lessons')
        .where('sdgId', isEqualTo: sdgNumber.toString())
        .where('status', isEqualTo: 'Published')
        .limit(1)
        .get();

    if (lessonQuery.docs.isEmpty) {
      print('No published lesson found for sdgId: $sdgNumber');
      return;
    }

    final lessonRef = lessonQuery.docs.first.reference;
    final lessonSnap = await lessonRef.get();
    final lessonData = lessonSnap.data() as Map<String, dynamic>? ?? {};

    try {
      await firestore.runTransaction((txn) async {
        final lessonSnap = await txn.get(lessonRef);
        final lessonData = lessonSnap.data() as Map<String, dynamic>;
        final updates = <String, dynamic>{};

        bool hasResponded =
            lessonData['respondedUsers']?.containsKey(userId) ?? false;
        String? previousQuality = lessonData['userQualities']?[userId];

        if (responded) {
          if (!hasResponded) {
            updates['respondedCount'] = FieldValue.increment(1);
            updates['respondedUsers.$userId'] = true;
            updates['userQualities.$userId'] = newQuality;
            if (newQuality == "good") {
              updates['goodResponseCount'] = FieldValue.increment(1);
            } else if (newQuality == "partial") {
              updates['partialResponseCount'] = FieldValue.increment(1);
            } else if (newQuality == "poor") {
              updates['poorResponseCount'] = FieldValue.increment(1);
            }
          } else if (previousQuality != newQuality) {
            if (previousQuality == "good") {
              updates['goodResponseCount'] = FieldValue.increment(-1);
            } else if (previousQuality == "partial") {
              updates['partialResponseCount'] = FieldValue.increment(-1);
            } else if (previousQuality == "poor") {
              updates['poorResponseCount'] = FieldValue.increment(-1);
            }
            if (newQuality == "good") {
              updates['goodResponseCount'] = FieldValue.increment(1);
            } else if (newQuality == "partial") {
              updates['partialResponseCount'] = FieldValue.increment(1);
            } else if (newQuality == "poor") {
              updates['poorResponseCount'] = FieldValue.increment(1);
            }
            updates['userQualities.$userId'] = newQuality;
          }
        }
        if (readMinutes >= 2 &&
            !(lessonData['read5minUsers']?.containsKey(userId) ?? false)) {
          updates['read5minCount'] = FieldValue.increment(1);
          updates['read5minUsers.$userId'] = true;
        }

        if (updates.isNotEmpty) {
          txn.update(lessonRef, updates);
        }
      });
    } catch (e) {
      print('Error updating lesson counts: $e');
    }
  }
}
