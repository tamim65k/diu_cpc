import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/authentication/enhanced_login_screen.dart';
import 'home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData) {
          // User is signed in
          return const HomeScreen();
        } else {
          // User is not signed in
          return const EnhancedLoginScreen();
        }
      },
    );
  }
}
