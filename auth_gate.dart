import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'components/landing.dart';
import 'components/home.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // Still checking Firebase session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User already logged in
        if (snapshot.hasData) {
          return const Home();   // 👈 Your main screen after login
        }

        // Not logged in
        return const LandingPage();
      },
    );
  }
}
