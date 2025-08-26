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

  /// Sign up with email + username + password
  Future<void> signUpWithUsernameAndPassword(
      String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    await _firestore.collection('normal_users').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': cred.user!.displayName ?? '',
      'phone': cred.user!.phoneNumber ?? '',
      'role': 'user',
      'profilePicture': cred.user!.photoURL ?? '',
      'passwordHash': _hashPassword(password),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'year': DateTime.now().year.toString(), // ✅ added year
    });
  }

  /// Login with username + password
  /// Login with email + password (was called loginWithUsername)
  Future<bool> loginWithUsername(String email, String password) async {
    if (email.isEmpty || password.isEmpty) return false;

    final snapshot = await _firestore
        .collection('normal_users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return false;

    final doc = snapshot.docs.first;
    final userData = doc.data();

    final storedHash = userData['passwordHash'] ?? '';
    final enteredHash = _hashPassword(password);

    if (enteredHash != storedHash) {
      // Password does not match
      return false;
    }

    try {
      // Password matches, sign in with Firebase using plain password
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Optionally update Firestore hash or timestamp
      await _firestore.collection('normal_users').doc(doc.id).update({
        'passwordHash': enteredHash,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<User?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(scopes: ['email']);
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final googleCredential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    try {
      // Try signing in with Google
      final userCred = await _auth.signInWithCredential(googleCredential);
      final user = userCred.user!;

      // Update Firestore user data
      final docRef = _firestore.collection('normal_users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'name': user.displayName ?? '',
          'profilePicture': user.photoURL ?? '',
          'role': 'user',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'year': DateTime.now().year.toString(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        // Email exists with Email/Password
        final email = e.email!;
        // Fetch the existing methods for this email
        final methods = await _auth.fetchSignInMethodsForEmail(email);

        if (methods.contains('password')) {
          // Sign in with Email/Password using your stored password hash
          final snapshot = await _firestore
              .collection('normal_users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (snapshot.docs.isNotEmpty) {
            final doc = snapshot.docs.first;
            final userData = doc.data();

            // You **cannot reverse the hash**, so you must ask user for the password **once**
            // Then link the Google credential
            // For silent linking, you need plain password at this point
            throw FirebaseAuthException(
              code: 'manual-link-required',
              message: 'User exists with Email/Password. Link Google manually.',
            );
          }
        }
      } else {
        rethrow;
      }
    }
  }

  /// Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) throw Exception("Email is required");

    try {
      await _auth.sendPasswordResetEmail(email: email);
      print("Password reset email sent to $email");
    } catch (e) {
      throw Exception("Failed to send reset email: $e");
    }
  }
}

Future<void> sendPasswordReset(String email) async {
  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
}
