import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dashboard_screen.dart';
import 'auth_service.dart';
import 'SignUpScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;

  /// Login with username (email will be fetched internally)
  Future<void> _loginWithUsername() async {
    setState(() => _loading = true);
    try {
      bool success = await _authService.loginWithUsername(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wrong username or password")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
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
              color: const Color(0xFFFCF9F9),
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
                  'Sign in with your username and password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Times New Roman',
                      color: Colors.black),
                ),
                const SizedBox(height: 20),

                // Username only
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[300],
                    hintText: 'Username',
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
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[300],
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: implement forget password
                    },
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
                          onPressed: _loginWithUsername,
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
                          onPressed: _loginWithGoogle,
                          icon: Image.asset(
                            'assets/image.png',
                            height: 24,
                            width: 24,
                          ),
                          label: const Text(
                            'Sign in with Google',
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
                      const TextSpan(text: 'New to Nexus '),
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
