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

        // Helper function to extract increment value from FieldValue
        int getIncrementValue(dynamic fieldValue) {
          if (fieldValue is FieldValue) {
            // FieldValue.increment stores the delta value internally
            // We can inspect the string representation or use a default
            final stringValue = fieldValue.toString();
            if (stringValue.contains('FieldValue.increment')) {
              final match = RegExp(r'FieldValue\.increment\((-?\d+)\)')
                  .firstMatch(stringValue);
              return match != null ? int.parse(match.group(1)!) : 0;
            }
          }
          return 0;
        }

        // Calculate avgProgress if responded or hasResponded
        if (responded || hasResponded) {
          // Get current counts from lessonData, default to 0 if not num
          final accessCount = lessonData['accessCount'] is num
              ? lessonData['accessCount'] as num
              : 0;
          final read5minCount = lessonData['read5minCount'] is num
              ? lessonData['read5minCount'] as num
              : 0;
          final goodResponseCount = lessonData['goodResponseCount'] is num
              ? lessonData['goodResponseCount'] as num
              : 0;
          final partialResponseCount = lessonData['partialResponseCount'] is num
              ? lessonData['partialResponseCount'] as num
              : 0;
          final poorResponseCount = lessonData['poorResponseCount'] is num
              ? lessonData['poorResponseCount'] as num
              : 0;
          final respondedCount = lessonData['respondedCount'] is num
              ? lessonData['respondedCount'] as num
              : 0;

          // Apply pending increments from updates
          final updatedRead5minCount = read5minCount +
              (updates.containsKey('read5minCount')
                  ? getIncrementValue(updates['read5minCount'])
                  : 0);
          final updatedGoodResponseCount = goodResponseCount +
              (updates.containsKey('goodResponseCount')
                  ? getIncrementValue(updates['goodResponseCount'])
                  : 0);
          final updatedPartialResponseCount = partialResponseCount +
              (updates.containsKey('partialResponseCount')
                  ? getIncrementValue(updates['partialResponseCount'])
                  : 0);
          final updatedPoorResponseCount = poorResponseCount +
              (updates.containsKey('poorResponseCount')
                  ? getIncrementValue(updates['poorResponseCount'])
                  : 0);
          final updatedRespondedCount = respondedCount +
              (updates.containsKey('respondedCount')
                  ? getIncrementValue(updates['respondedCount'])
                  : 0);

          if (updatedRespondedCount > 0) {
            final score = (accessCount * 10 +
                    updatedRead5minCount * 10 +
                    updatedGoodResponseCount * 65 +
                    updatedPartialResponseCount * 30 +
                    updatedPoorResponseCount * 5) /
                updatedRespondedCount;
            updates['avgProgress'] = score.round().clamp(0, 100);
            print('Calculated avgProgress: ${updates['avgProgress']}');
            print(
                'Fields for avgProgress: accessCount=$accessCount, read5minCount=$updatedRead5minCount, '
                'goodResponseCount=$updatedGoodResponseCount, partialResponseCount=$updatedPartialResponseCount, '
                'poorResponseCount=$updatedPoorResponseCount, respondedCount=$updatedRespondedCount');
          } else {
            print('Skipped avgProgress calculation: respondedCount is 0');
          }
        }
        if (updates.isNotEmpty) {
          txn.update(lessonRef, updates);
        }
      });
    } catch (e) {
      print('Error updating lesson counts: $e');
    }
  } // not avg updated
}
