import 'package:cloud_firestore/cloud_firestore.dart';

class LessonService {
  static Future<void> updateLessonCounts({
    required int sdgNumber,
    required String userId,
    required String newQuality,
    required bool responded,
    required int readMinutes,
    String? lessonDocId,
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
        // Initialize missing fields to avoid null or FieldValue issues
        lessonData['accessCount'] ??= 1; // Set by LearnScreen
        lessonData['read5minCount'] ??= 0;
        lessonData['goodResponseCount'] ??= 0;
        lessonData['partialResponseCount'] ??= 0;
        lessonData['poorResponseCount'] ??= 0;
        lessonData['respondedCount'] ??= 0;

        // Calculate avgProgress if responded or hasResponded
        if (responded || hasResponded) {
          // Get current counts from lessonData, default to 0 if not num
          final accessCount = lessonData['accessCount'] is num
              ? lessonData['accessCount'] as num
              : 1;
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
          int incrementValue(dynamic fieldValue) {
            if (fieldValue is FieldValue &&
                fieldValue.toString().contains('FieldValue.increment')) {
              final match = RegExp(r'FieldValue\.increment\((-?\d+)\)')
                  .firstMatch(fieldValue.toString());
              return match != null ? int.parse(match.group(1)!) : 0;
            }
            return 0;
          }

          final updatedRead5minCount = read5minCount +
              (updates.containsKey('read5minCount')
                  ? incrementValue(updates['read5minCount'])
                  : 0);
          final updatedGoodResponseCount = goodResponseCount +
              (updates.containsKey('goodResponseCount')
                  ? incrementValue(updates['goodResponseCount'])
                  : 0);
          final updatedPartialResponseCount = partialResponseCount +
              (updates.containsKey('partialResponseCount')
                  ? incrementValue(updates['partialResponseCount'])
                  : 0);
          final updatedPoorResponseCount = poorResponseCount +
              (updates.containsKey('poorResponseCount')
                  ? incrementValue(updates['poorResponseCount'])
                  : 0);
          final updatedRespondedCount = respondedCount +
              (updates.containsKey('respondedCount')
                  ? incrementValue(updates['respondedCount'])
                  : 0);

          // Ensure respondedCount is at least sum of response counts
          final totalResponses = updatedGoodResponseCount +
              updatedPartialResponseCount +
              updatedPoorResponseCount;
          final finalRespondedCount = updatedRespondedCount >= totalResponses
              ? updatedRespondedCount
              : (totalResponses > 0 ? totalResponses : 1);

          final score = (accessCount * 10 +
                  updatedRead5minCount * 10 +
                  updatedGoodResponseCount * 65 +
                  updatedPartialResponseCount * 30 +
                  updatedPoorResponseCount * 5) /
              finalRespondedCount;

          // Apply threshold logic
          int avgProgress;
          if (score < 15) {
            avgProgress = score.round();
          } else if (score < 70 || finalRespondedCount < 80) {
            avgProgress = 50;
          } else if (score < 90 || finalRespondedCount < 101) {
            avgProgress = 70;
          } else if (score < 100 || finalRespondedCount < 501) {
            avgProgress = 85;
          } else {
            avgProgress = 100;
          }
          updates['avgProgress'] = avgProgress.clamp(0, 100);
          print('Calculated avgProgress: ${updates['avgProgress']}');
          print('Raw score: $score');
          print(
              'Fields for avgProgress: accessCount=$accessCount, read5minCount=$updatedRead5minCount, '
              'goodResponseCount=$updatedGoodResponseCount, partialResponseCount=$updatedPartialResponseCount, '
              'poorResponseCount=$updatedPoorResponseCount, respondedCount=$finalRespondedCount');
          print(
              'lessonData types: accessCount=${lessonData['accessCount'].runtimeType}, '
              'read5minCount=${lessonData['read5minCount'].runtimeType}, '
              'goodResponseCount=${lessonData['goodResponseCount'].runtimeType}, '
              'partialResponseCount=${lessonData['partialResponseCount'].runtimeType}, '
              'poorResponseCount=${lessonData['poorResponseCount'].runtimeType}, '
              'respondedCount=${lessonData['respondedCount'].runtimeType}');
          print('updates contents: $updates');
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
