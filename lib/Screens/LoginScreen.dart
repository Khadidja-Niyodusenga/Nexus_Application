import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dashboard_screen.dart';
import 'auth_service.dart';
import 'SignUpScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _loading = false;

  Future<void> _showForgetPasswordDialog() async {
    final TextEditingController emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Enter your email',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;

              try {
                await _authService.sendPasswordResetEmail(email);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Reset link sent to your email')),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _loginWithEmail() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Please enter email and password");
      return;
    }

    setState(() => _loading = true);

    try {
      // Attempt sign-in with email & password
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;

      if (user != null) {
        final userDocRef =
            FirebaseFirestore.instance.collection('normal_users').doc(user.uid);

        final userDoc = await userDocRef.get();

        if (!userDoc.exists) {
          // First-time user → create document with createdAt
          await userDocRef.set({
            'uid': user.uid,
            'name': '', // or user.displayName if you collected it
            'address': '',
            'phone': '',
            'email': email,
            'profilePicture': '',
            'role': 'user',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'lastActive': FieldValue.serverTimestamp(), // NEW
          });
        } else {
          // Returning user → update lastLogin only
          await userDocRef.update({
            'lastLogin': FieldValue.serverTimestamp(),
            'lastActive': FieldValue.serverTimestamp(), // NEW
            'updatedAt': FieldValue.serverTimestamp(),
          });
          await UserService.updateLastActive(user.uid);
        }

        // Navigate to Dashboard after login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showMessage("No account found with this email. Please sign up first.");
      } else if (e.code == 'wrong-password') {
        _showMessage("Wrong password. Try again.");
      } else if (e.code == 'account-exists-with-different-credential') {
        _showMessage(
            "This email is registered with another method. Please use that to sign in.");
      } else {
        _showMessage(e.message ?? "Login failed");
      }
    } finally {
      setState(() => _loading = false);
    }
  }

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
      //final user = userCredential.user;
      if (user != null) {
        final userDocRef =
            FirebaseFirestore.instance.collection('normal_users').doc(user.uid);

        final userDoc = await userDocRef.get();

        if (!userDoc.exists) {
          // First-time user → create document with createdAt, lastLogin, updatedAt
          await userDocRef.set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'address': '',
            'phone': '',
            'email': user.email ?? '',
            'profilePicture': user.photoURL ?? '',
            'role': 'user',
            'createdAt': FieldValue.serverTimestamp(), // stored once
            'lastLogin': FieldValue.serverTimestamp(),
            'lastActive': FieldValue.serverTimestamp(), // NEW
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Returning user → update lastLogin & updatedAt only
          await userDocRef.update({
            'lastLogin': FieldValue.serverTimestamp(), // updated each login
            'lastActive': FieldValue.serverTimestamp(), // NEW
            'updatedAt': FieldValue.serverTimestamp(),
          });
          await UserService.updateLastActive(user.uid);
        }
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
                  'Welcome Back to Nexus App\n Sign in now!',
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
                        borderSide: BorderSide.none),
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
                          _isObscure = !_isObscure;
                        });
                      },
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgetPasswordDialog,
                    child: Text(
                      'Forget password',
                      style:
                          TextStyle(color: Colors.blue.shade400, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _loading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loginWithEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)),
                          ),
                          child: const Text(
                            'Sign in',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                                fontFamily: 'Times New Roman'),
                          ),
                        ),
                      ),
                const SizedBox(height: 16),
                _loading
                    ? const SizedBox()
                    : SizedBox(
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
                                color: Colors.white,
                                fontFamily: 'Times New Roman'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Times New Roman',
                        color: Colors.black),
                    children: [
                      const TextSpan(text: 'New to Nexus? '),
                      TextSpan(
                        text: 'Sign up',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade400),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SignUpScreen()));
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
