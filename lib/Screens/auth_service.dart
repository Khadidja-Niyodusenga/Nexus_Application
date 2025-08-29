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
