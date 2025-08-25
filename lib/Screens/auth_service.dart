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
      String email, String username, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    await _firestore.collection('normal_users').doc(uid).set({
      'uid': uid,
      'email': email,
      'username': username,
      'name': cred.user!.displayName ?? '',
      'phone': cred.user!.phoneNumber ?? '',
      'role': 'user',
      'profilePicture': cred.user!.photoURL ?? '',
      'passwordHash': _hashPassword(password),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Login with username + password
  Future<bool> loginWithUsername(String username, String password) async {
    if (username.isEmpty || password.isEmpty) return false;

    // 1. Find the user document in Firestore
    final snapshot = await _firestore
        .collection('normal_users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return false;

    final doc = snapshot.docs.first;
    final userData = doc.data();

    final storedHash = userData['passwordHash'] ?? '';
    final enteredHash = _hashPassword(password);

    // 2. Compare the entered password hash with Firestore hash
    if (enteredHash == storedHash) {
      // Password matches Firestore — login success
      return true;
    } else {
      // Password mismatch — maybe user reset password via email
      try {
        // Try signing in with Firebase Auth using email stored in Firestore
        final email = userData['email'] ?? '';
        if (email.isEmpty) return false;

        await _auth.signInWithEmailAndPassword(
            email: email, password: password);

        // If Firebase Auth login succeeds, update Firestore with new password hash
        await _firestore.collection('normal_users').doc(doc.id).update({
          'passwordHash': enteredHash,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        return true;
      } catch (e) {
        // Firebase Auth login failed — wrong password
        return false;
      }
    }
  }

  /// Google sign-in
  Future<User?> signInWithGoogle() async {
    // Force account picker popup every time
    final googleSignIn = GoogleSignIn(scopes: ['email']);
    await googleSignIn.signOut(); // ensures account picker shows
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred = await _auth.signInWithCredential(credential);

    final docRef =
        _firestore.collection('normal_users').doc(userCred.user!.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      // User exists: update missing fields only
      final data = doc.data()!;
      await docRef.update({
        'name': (data['name'] == null || data['name'] == '')
            ? userCred.user!.displayName
            : data['name'],
        'profilePicture':
            (data['profilePicture'] == null || data['profilePicture'] == '')
                ? userCred.user!.photoURL
                : data['profilePicture'],
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } else {
      // First-time Google login: create new document
      await docRef.set({
        'uid': userCred.user!.uid,
        'email': userCred.user!.email ?? '',
        'username': '', // user can fill later
        'name': userCred.user!.displayName ?? '',
        'phone': '', // user can fill later
        'role': 'user',
        'profilePicture': userCred.user!.photoURL ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    return userCred.user;
  }

  /// Send password reset email and update Firestore hash if password changed
  Future<void> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) throw Exception("Email is required");

    try {
      // Send Firebase password reset email
      await _auth.sendPasswordResetEmail(email: email);

      // Optional: You can track that a reset link was sent.
      print("Password reset email sent to $email");
    } catch (e) {
      throw Exception("Failed to send reset email: $e");
    }
  }
}

Future<void> sendPasswordReset(String email) async {
  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
}
