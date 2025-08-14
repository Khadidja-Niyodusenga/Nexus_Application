// import 'package:flutter/material.dart';
// import 'package:flutter/gestures.dart';
// import 'SignUpScreen.dart';
// import 'dashboard_screen.dart';

// class LoginScreen extends StatelessWidget {
//   const LoginScreen({super.key});

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
//               color: const Color(0xFFFCF9F9),
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
//                     fontWeight: FontWeight.bold,
//                     fontSize: 28,
//                     fontFamily: 'Times New Roman',
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 RichText(
//                   textAlign: TextAlign.center,
//                   text: TextSpan(
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontFamily: 'Times New Roman',
//                       color: Colors.black,
//                     ),
//                     children: [
//                       const TextSpan(text: 'Welcome Back '),
//                       TextSpan(
//                         text: 'to Nexus App\n',
//                         style: TextStyle(
//                           color: Colors.blue.shade400,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const TextSpan(text: 'Sign in now '),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 TextField(
//                   decoration: InputDecoration(
//                     filled: true,
//                     fillColor: Colors.grey[300],
//                     hintText: 'Email or username',
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
//                 TextField(
//                   obscureText: true,
//                   decoration: InputDecoration(
//                     filled: true,
//                     fillColor: Colors.grey[300],
//                     hintText: 'password',
//                     hintStyle: const TextStyle(color: Colors.grey),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide.none,
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(
//                         vertical: 14, horizontal: 16),
//                   ),
//                 ),
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: TextButton(
//                     onPressed: () {
//                       // TODO: forget password logic here
//                     },
//                     child: Text(
//                       'forget password',
//                       style: TextStyle(
//                         color: Colors.blue.shade400,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 SizedBox(
//   width: double.infinity,
//   child: ElevatedButton(
//     onPressed: () {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => const DashboardScreen(),
//         ),
//       );
//     },
//     style: ElevatedButton.styleFrom(
//       backgroundColor: Colors.blue.shade400,
//       padding: const EdgeInsets.symmetric(vertical: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(50),
//       ),
//     ),
//     child: const Text(
//       'Sign in',
//       style: TextStyle(
//         fontWeight: FontWeight.bold,
//         fontSize: 18,
//         color: Colors.white,
//         fontFamily: 'Times New Roman',
//       ),
//     ),
//   ),
// ),
// ],
//     ),
//                 const SizedBox(height: 16),

//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       // TODO: Google sign in logic here
//                     },
//                     icon: Image.asset(
//                       'assets/image.png',
//                       height: 24,
//                       width: 24,
//                     ),
//                     label: const Text(
//                       'sign in with Google',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                         fontFamily: 'Times New Roman',
//                         color: Color.fromARGB(255, 255, 255, 255),
//                       ),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green.shade400,
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       foregroundColor: const Color.fromARGB(255, 255, 255, 255),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 RichText(
//                   text: TextSpan(
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontFamily: 'Times New Roman',
//                       color: Colors.black,
//                     ),
//                     children: [
//                       const TextSpan(text: 'New to Nexus '),
//                       TextSpan(
//                         text: 'Sign up',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue.shade400,
//                         ),
//                         recognizer: TapGestureRecognizer()
//                           ..onTap = () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (context) => const SignUpScreen()),
//                             );
//                           },
//                       ),
//                     ],
//                   ),
//                 ),
//           ),
//         ),
//       ),

//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'SignUpScreen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                    fontFamily: 'Times New Roman',
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Times New Roman',
                      color: Colors.black,
                    ),
                    children: [
                      const TextSpan(text: 'Welcome Back '),
                      TextSpan(
                        text: 'to Nexus App\n',
                        style: TextStyle(
                          color: Colors.blue.shade400,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: 'Sign in now '),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[300],
                    hintText: 'Email or username',
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
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[300],
                    hintText: 'password',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'forget password',
                      style: TextStyle(
                        color: Colors.blue.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DashboardScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16), // ✅ Now inside Column
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: Image.asset(
                      'assets/image.png',
                      height: 24,
                      width: 24,
                    ),
                    label: const Text(
                      'sign in with Google',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Times New Roman',
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Times New Roman',
                      color: Colors.black,
                    ),
                    children: [
                      const TextSpan(text: 'New to Nexus '),
                      TextSpan(
                        text: 'Sign up',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade400,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUpScreen()),
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
