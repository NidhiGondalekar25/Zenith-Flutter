import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zenith/features/auth/login_screen.dart';
import 'package:zenith/features/home/home_screen.dart';

/// Listens to Firebase auth state and routes accordingly.
/// If logged in → HomeScreen, if not → LoginScreen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Logged in
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Not logged in
        return const LoginScreen();
      },
    );
  }
}
