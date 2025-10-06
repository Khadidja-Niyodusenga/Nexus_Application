import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  Future<int> getActiveUsers({required int days}) async {
    final threshold =
        Timestamp.fromDate(DateTime.now().subtract(Duration(days: days)));
    final query = await FirebaseFirestore.instance
        .collection('normal_users')
        .where('lastActive', isGreaterThanOrEqualTo: threshold)
        .get();
    return query.docs.length;
  }

  static Future<void> updateLastActive(String userId) async {
    if (userId.isEmpty) return;

    final userRef =
        FirebaseFirestore.instance.collection('normal_users').doc(userId);

    try {
      await userRef.set(
        {
          'lastActive': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print('Updated lastActive for user: $userId');
    } catch (e) {
      print('Error updating lastActive: $e');
    }
  }
}
