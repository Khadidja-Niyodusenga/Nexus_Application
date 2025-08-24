// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class GoogleSignInService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Use singleton instance of GoogleSignIn
//   final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: ['email'],
//     serverClientId: '<YOUR_WEB_CLIENT_ID>', // Replace with actual Web client ID
//   );

//   bool _isInitialized = false;

//   Future<void> initialize() async {
//     if (!_isInitialized) {
//       await _googleSignIn.initialize(serverClientId: '<YOUR_WEB_CLIENT_ID>');
//       _isInitialized = true;
//     }
//   }

//   Future<User?> signInWithGoogle() async {
//     await initialize();

//     try {
//       // Use authenticate instead of signIn in v7.x
//       final GoogleSignInAccount? googleUser =
//           await _googleSignIn.authenticate();
//       if (googleUser == null) {
//         // Sign-in aborted
//         return null;
//       }

//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;

//       final credential = GoogleAuthProvider.credential(
//         idToken: googleAuth.idToken,
//         // accessToken is deprecated in this version, so omit it
//       );

//       UserCredential userCredential =
//           await _auth.signInWithCredential(credential);

//       await _saveUserToFirestore(userCredential.user!);

//       return userCredential.user;
//     } catch (e) {
//       print('Google sign-in error: $e');
//       return null;
//     }
//   }

//   Future<void> _saveUserToFirestore(User user) async {
//     final userDoc =
//         FirebaseFirestore.instance.collection('normal_users').doc(user.uid);

//     final docSnapshot = await userDoc.get();

//     if (!docSnapshot.exists) {
//       await userDoc.set({
//         'uid': user.uid,
//         'name': user.displayName ?? '',
//         'email': user.email ?? '',
//         'phone': user.phoneNumber ?? '',
//         'role': 'user',
//         'profilePicture': user.photoURL ?? '',
//         'createdAt': DateTime.now().toIso8601String(),
//         'updatedAt': DateTime.now().toIso8601String(),
//       });
//     } else {
//       await userDoc.update({'updatedAt': DateTime.now().toIso8601String()});
//     }
//   }

//   Future<void> signOut() async {
//     await _googleSignIn.signOut();
//     await _auth.signOut();
//   }
// }
