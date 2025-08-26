// import 'package:flutter/material.dart';
// import 'package:flutter/gestures.dart';
// import 'auth_service.dart';
// import 'LoginScreen.dart';
// import 'dashboard_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class SignUpScreen extends StatefulWidget {
//   const SignUpScreen({super.key});

//   @override
//   State<SignUpScreen> createState() => _SignUpScreenState();
// }

// class _SignUpScreenState extends State<SignUpScreen> {
//   bool agreed = false;
//   bool _loading = false;
//   bool _isObscure = true;
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();

//   final AuthService _authService = AuthService();

//   // Future<void> _signUpWithUsername() async {
//   //   if (!agreed) return;

//   //   String email = _emailController.text.trim();
//   //   String username = _usernameController.text.trim();
//   //   String password = _passwordController.text.trim();

//   //   if (email.isEmpty || username.isEmpty || password.isEmpty) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text("Please fill all fields")),
//   //     );
//   //     return;
//   //   }

//   //   setState(() => _loading = true);

//   //   try {
//   //     // Call your AuthService
//   //     await AuthService().signUpWithUsernameAndPassword(
//   //       email,
//   //       username,
//   //       password,
//   //     );

//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text("Sign up successful!")),
//   //     );

//   //     // After signup, navigate to Dashboard or Login
//   //     Navigator.pushReplacement(
//   //       context,
//   //       MaterialPageRoute(builder: (_) => const LoginScreen()),
//   //     );
//   //   } catch (e) {
//   //     ScaffoldMessenger.of(context)
//   //         .showSnackBar(SnackBar(content: Text(e.toString())));
//   //   } finally {
//   //     setState(() => _loading = false);
//   //   }
//   // }

//   Future<void> _signUpWithUsername() async {
//     if (!agreed) return;

//     String email = _emailController.text.trim();
//     String username = _usernameController.text.trim();
//     String password = _passwordController.text.trim();

//     if (email.isEmpty || username.isEmpty || password.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please fill all fields")),
//       );
//       return;
//     }

//     setState(() => _loading = true);

//     try {
//       // ✅ Create user in Firebase Auth
//       UserCredential userCredential =
//           await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       // ✅ Get the created user
//       User? user = userCredential.user;

//       if (user != null) {
//         // ✅ Create Firestore document using UID
//         await FirebaseFirestore.instance
//             .collection('normal_users')
//             .doc(user.uid)
//             .set({
//           'name': '',
//           'username': username,
//           'email': email,
//           'profilePicture': '',
//           'createdAt': FieldValue.serverTimestamp(),
//         });

//         // ✅ Success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Sign up successful!")),
//         );

//         // ✅ Navigate to Dashboard
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const DashboardScreen()),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("User creation failed.")),
//         );
//       }
//     } on FirebaseAuthException catch (e) {
//       String errorMessage;
//       if (e.code == 'email-already-in-use') {
//         errorMessage = "This email is already registered.";
//       } else if (e.code == 'weak-password') {
//         errorMessage = "Password is too weak.";
//       } else {
//         errorMessage = e.message ?? "Authentication failed.";
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(errorMessage)),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: ${e.toString()}")),
//       );
//     } finally {
//       setState(() => _loading = false);
//     }
//     await FirebaseAuth.instance.signInWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//   }

//   Future<void> _signUpWithGoogle() async {
//     setState(() => _loading = true);
//     try {
//       final user = await _authService.signInWithGoogle();
//       if (user != null) {
//         // After Google sign-in, you can also register the username/password
//         // if you want the user to also have normal login
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Google sign in successful!")),
//         );
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const DashboardScreen()),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(e.toString())),
//       );
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: SingleChildScrollView(
//           child: Container(
//             width: 340,
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: const Color.fromARGB(255, 243, 241, 241),
//               borderRadius: BorderRadius.circular(24),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 15,
//                   offset: const Offset(0, 8),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   'NEXUS APP',
//                   style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 28,
//                       fontFamily: 'Times New Roman'),
//                 ),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Sign Up Here!',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                       fontSize: 16,
//                       fontFamily: 'Times New Roman',
//                       color: Colors.black),
//                 ),
//                 const SizedBox(height: 20),

//                 // Username only
//                 TextField(
//                   controller: _usernameController,
//                   decoration: InputDecoration(
//                     filled: true,
//                     fillColor: Colors.grey[300],
//                     hintText: 'Username',
//                     hintStyle: const TextStyle(color: Colors.grey),
//                     border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: BorderSide.none),
//                     contentPadding: const EdgeInsets.symmetric(
//                         vertical: 14, horizontal: 16),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
// // Email
//                 TextField(
//                   controller: _emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: InputDecoration(
//                     filled: true,
//                     fillColor: Colors.grey[300],
//                     hintText: 'Email',
//                     hintStyle: const TextStyle(color: Colors.grey),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide.none,
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(
//                         vertical: 14, horizontal: 16),
//                   ),
//                 ),
//                 const SizedBox(height: 12),

//                 // Password
//                 TextField(
//                   controller: _passwordController,
//                   obscureText: _isObscure,
//                   decoration: InputDecoration(
//                     filled: true,
//                     fillColor: Colors.grey[300],
//                     hintText: 'Password',
//                     hintStyle: const TextStyle(color: Colors.grey),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide.none,
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(
//                         vertical: 14, horizontal: 16),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _isObscure ? Icons.visibility_off : Icons.visibility,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _isObscure = !_isObscure; // toggle visibility
//                         });
//                       },
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 12),

//                 // Agree terms checkbox
//                 Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Checkbox(
//                       value: agreed,
//                       onChanged: (value) {
//                         setState(() {
//                           agreed = value ?? false;
//                         });
//                       },
//                     ),
//                     Text(
//                       'Agree terms and conditions',
//                       style: TextStyle(
//                         color: Colors.blue.shade400,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),

//                 // Sign Up button
//                 _loading
//                     ? const CircularProgressIndicator()
//                     : SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           onPressed: agreed ? _signUpWithUsername : null,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.blue.shade400,
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(50),
//                             ),
//                           ),
//                           child: const Text(
//                             'Sign up',
//                             style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 18,
//                                 color: Colors.white,
//                                 fontFamily: 'Times New Roman'),
//                           ),
//                         ),
//                       ),
//                 const SizedBox(height: 16),

//                 // Google sign in button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: _signUpWithGoogle,
//                     icon: Image.asset(
//                       'assets/image.png',
//                       height: 24,
//                       width: 24,
//                     ),
//                     label: const Text(
//                       'Continue with Google',
//                       style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                           fontFamily: 'Times New Roman',
//                           color: Colors.white),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green.shade400,
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // Already joined? Sign in
//                 RichText(
//                   text: TextSpan(
//                     style: const TextStyle(
//                         fontSize: 16,
//                         fontFamily: 'Times New Roman',
//                         color: Colors.black),
//                     children: [
//                       const TextSpan(text: 'Already have an account? '),
//                       TextSpan(
//                         text: 'Sign in',
//                         style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.blue.shade400),
//                         recognizer: TapGestureRecognizer()
//                           ..onTap = () {
//                             Navigator.pushReplacement(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (_) => const LoginScreen()),
//                             );
//                           },
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'auth_service.dart';
import 'LoginScreen.dart';
import 'dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool agreed = false;
  bool _loading = false;
  bool _isObscure = true;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final AuthService _authService = AuthService();

  Future<void> _signUpWithEmail() async {
    if (!agreed) return; // make sure terms are agreed

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Please fill all fields");
      return;
    }

    setState(() => _loading = true);

    try {
      // Check if email already exists in Firebase Auth
      final methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

      if (methods.isNotEmpty) {
        if (methods.contains('google.com')) {
          // Email exists for Google sign-in
          _showMessage(
              "This email is registered with Google. Please use Google to sign in.");
          return;
        } else if (methods.contains('password')) {
          // Email already exists for manual sign-up
          _showMessage(
              "This email is already registered. Please sign in with email/password.");
          return;
        } else {
          _showMessage("This email is already in use.");
          return;
        }
      }

      // Create new email/password account
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save full user info to Firestore
      await FirebaseFirestore.instance
          .collection('normal_users')
          .doc(userCred.user!.uid)
          .set({
        'name': '',
        'address': '',
        'telephone': '',
        'email': email,
        'profilePicture': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showMessage("Account created successfully!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Sign-up failed");
    } finally {
      setState(() => _loading = false);
    }
  }

  // Future<void> _signUpWithGoogle() async {
  //   setState(() => _loading = true);
  //   try {
  //     final user = await _authService.signInWithGoogle();

  //     if (user != null) {
  //       // Fetch sign-in methods for this email
  //       final methods =
  //           await FirebaseAuth.instance.fetchSignInMethodsForEmail(user.email!);

  //       if (methods.contains('password')) {
  //         // Email already exists for manual sign-up
  //         _showMessage(
  //             "This email is registered manually. Please use email/password to sign in.");
  //         await FirebaseAuth.instance.signOut(); // log out from Google
  //         return;
  //       }

  //       // Otherwise, allow Google login
  //       _showMessage("Google sign-in successful!");
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (context) => const DashboardScreen()),
  //       );
  //     }
  //   } catch (e) {
  //     _showMessage(e.toString());
  //   } finally {
  //     setState(() => _loading = false);
  //   }
  // }

  Future<void> _continueWithGoogle() async {
    setState(() => _loading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _showMessage("Google sign-in cancelled.");
        return;
      }

      final email = googleUser.email;

      // Fetch existing sign-in methods for this email
      final methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      print('Sign-in methods for $email: $methods');

      if (methods.contains('password')) {
        // This email is registered manually — do not allow Google
        _showMessage(
            "This email is registered manually. Please use email/password to sign in.");
        await googleSignIn.signOut(); // ensure user is logged out of Google
        return; // stop the function here
      }

      // Now safe to create Google credential and sign in
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        _showMessage("Google sign-in failed. Try again.");
        return;
      }

      // If new user, create Firestore document
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await FirebaseFirestore.instance
            .collection('normal_users')
            .doc(user.uid)
            .set({
          'name': '',
          'address': '',
          'telephone': '',
          'email': email,
          'profilePicture': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _showMessage("Google sign-in successful!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

// Utility to show messages
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 243, 241, 241),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'NEXUS APP',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      fontFamily: 'Times New Roman'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sign Up Here!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Times New Roman',
                      color: Colors.black),
                ),
                const SizedBox(height: 20),

                // Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[300],
                    hintText: 'Email',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 12),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[300],
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure; // toggle visibility
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Agree terms checkbox
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: agreed,
                      onChanged: (value) {
                        setState(() {
                          agreed = value ?? false;
                        });
                      },
                    ),
                    Text(
                      'Agree terms and conditions',
                      style: TextStyle(
                        color: Colors.blue.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sign Up button
                _loading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: agreed ? _signUpWithEmail : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                                fontFamily: 'Times New Roman'),
                          ),
                        ),
                      ),
                const SizedBox(height: 16),

                // Google sign in button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _continueWithGoogle,
                    icon: Image.asset(
                      'assets/image.png',
                      height: 24,
                      width: 24,
                    ),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Times New Roman',
                          color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Already joined? Sign in
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Times New Roman',
                        color: Colors.black),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Sign in',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade400),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
