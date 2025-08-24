// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'dart:convert'; // for utf8.encode
// import 'package:crypto/crypto.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   /// Username + password sign up (no email)
//   Future<User?> signUpWithUsernameAndPassword(
//       String username, String password) async {
//     if (username.isEmpty || password.isEmpty) {
//       throw Exception('Username and password are required.');
//     }

//     // enforce unique username
//     final existing = await _firestore
//         .collection('normal_users')
//         .where('username', isEqualTo: username)
//         .limit(1)
//         .get();
//     if (existing.docs.isNotEmpty) {
//       throw Exception('Username already taken.');
//     }

//     // create Firebase user with a synthetic email
//     final syntheticEmail = '$username@nexus.local';
//     final cred = await _auth.createUserWithEmailAndPassword(
//       email: syntheticEmail,
//       password: password, // needed by Firebase
//     );

//     // hash the password before storing
//     final hashedPassword = sha256.convert(utf8.encode(password)).toString();

//     await _firestore.collection('normal_users').doc(cred.user!.uid).set({
//       'uid': cred.user!.uid,
//       'username': username,
//       'password': hashedPassword, // ⚡ store hashed password
//       'email': '', // optional
//       'name': '',
//       'phone': '',
//       'role': 'user',
//       'profilePicture': '',
//       'createdAt': DateTime.now().toIso8601String(),
//       'updatedAt': DateTime.now().toIso8601String(),
//     });

//     return cred.user;
//   }

//   /// Username + password login (uses the same synthetic email)
//   // Future<User?> loginWithUsernameAndPassword(
//   //     String username, String password) async {
//   //   final syntheticEmail = '$username@nexus.local';
//   //   final cred = await _auth.signInWithEmailAndPassword(
//   //     email: syntheticEmail,
//   //     password: password,
//   //   );
//   //   return cred.user;
//   // }
//   Future<bool> loginWithUsername(String username, String password) async {
//     var snap = await _firestore
//         .collection("normal_users")
//         .where("username", isEqualTo: username)
//         .where("password", isEqualTo: password)
//         .get();

//     return snap.docs.isNotEmpty;
//   }

//   /// Google sign-in (forces account chooser) and store basic profile
//   Future<User?> signInWithGoogle() async {
//     final g = GoogleSignIn(scopes: ['email']);
//     await g.signOut(); // forces the account picker popup
//     final GoogleSignInAccount? googleUser = await g.signIn();
//     if (googleUser == null) return null;

//     final googleAuth = await googleUser.authentication;
//     final credential = GoogleAuthProvider.credential(
//       accessToken: googleAuth.accessToken,
//       idToken: googleAuth.idToken,
//     );

//     final cred = await _auth.signInWithCredential(credential);
//     final uid = cred.user!.uid;

//     final docRef = _firestore.collection('normal_users').doc(uid);
//     final snap = await docRef.get();
//     if (!snap.exists) {
//       await docRef.set({
//         'uid': uid,
//         'email': cred.user!.email ?? '',
//         'username': '', // user can set later
//         'name': cred.user!.displayName ?? '',
//         'phone': cred.user!.phoneNumber ?? '',
//         'role': 'user',
//         'profilePicture': cred.user!.photoURL ?? '',
//         'createdAt': DateTime.now().toIso8601String(),
//         'updatedAt': DateTime.now().toIso8601String(),
//       });
//     }

//     return cred.user;
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert'; // for utf8.encode
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Hash password with SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sign up with username + password
  Future<void> signUpWithUsernameAndPassword(
      String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      throw Exception('Username and password are required.');
    }

    // Check if username exists
    final existing = await _firestore
        .collection('normal_users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Username already taken.');
    }

    final hashedPassword = _hashPassword(password);

    // Store directly in Firestore
    await _firestore.collection('normal_users').add({
      'uid': '', // optional, can generate or leave blank
      'username': username,
      'email': '', // no email needed
      'name': '',
      'phone': '',
      'role': 'user',
      'profilePicture': '',
      'passwordHash': hashedPassword,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Login with username + password
  Future<bool> loginWithUsername(String username, String password) async {
    if (username.isEmpty || password.isEmpty) return false;

    final snapshot = await _firestore
        .collection('normal_users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return false;

    final userData = snapshot.docs.first.data();
    final storedHash = userData['passwordHash'] ?? '';

    // Compare hashed password
    return _hashPassword(password) == storedHash;
  }

  /// Google sign-in
  Future<User?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred = await _auth.signInWithCredential(credential);

    // Create Firestore entry if first time
    final doc = await _firestore
        .collection('normal_users')
        .doc(userCred.user!.uid)
        .get();

    if (!doc.exists) {
      await _firestore.collection('normal_users').doc(userCred.user!.uid).set({
        'uid': userCred.user!.uid,
        'email': userCred.user!.email ?? '',
        'username': '', // user can set later
        'name': userCred.user!.displayName ?? '',
        'phone': userCred.user!.phoneNumber ?? '',
        'role': 'user',
        'profilePicture': userCred.user!.photoURL ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    return userCred.user;
  }
}
