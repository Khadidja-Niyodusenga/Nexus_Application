import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart'; // For WidgetsFlutterBinding

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase
      .initializeApp(); // Manual initialization if no firebase_options.dart
  await cleanAllDuplicates();
}

Future<void> cleanAllDuplicates() async {
  final firestore = FirebaseFirestore.instance;
  final progressCollection = firestore.collection('progress');

  final querySnapshot = await progressCollection.get();

  for (var userDoc in querySnapshot.docs) {
    final userId = userDoc.id;
    final data = userDoc.data();
    final sdgs = Map<String, dynamic>.from(data['sdgs'] ?? {});

    bool needsUpdate = false;
    final updatedSdgs = Map<String, dynamic>.from(sdgs);

    for (int sdgNum = 1; sdgNum <= 17; sdgNum++) {
      final sdgId = sdgNum.toString();

      if (sdgs.containsKey(sdgId)) {
        final sdgData = Map<String, dynamic>.from(sdgs[sdgId]);

        int readMinutes = sdgData['readMinutes'] ?? 0;
        String quality = sdgData['responseQuality'] ?? 'none';
        int percentage = sdgData['percentage'] ?? 0;
        bool responded = sdgData['responded'] ?? false;
        bool readCounted = sdgData['readCounted'] ?? false;

        final possibleQualities = ['good', 'partial', 'poor', 'none'];
        if (possibleQualities.indexOf(quality) >
            possibleQualities.indexOf(sdgData['responseQuality'] ?? 'none')) {
          quality = sdgData['responseQuality'];
        }

        updatedSdgs[sdgId] = {
          'opened': true,
          'accessCount': 1,
          'readMinutes': readMinutes,
          'responded': responded,
          'responseQuality': quality,
          'percentage': percentage,
          'readCounted': readCounted,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        needsUpdate = true;
      }
    }

    if (needsUpdate) {
      await firestore.runTransaction((txn) async {
        txn.set(
            userDoc.reference,
            {
              'userId': userId,
              'sdgs': updatedSdgs,
            },
            SetOptions(merge: true));
      });
      print("Cleaned duplicates for user: $userId");
    }
  }

  print("Cleanup complete for all users.");
}
