import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  // Check if the user is logged in and navigate accordingly
  void _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate loading delay
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      // If user is logged in and email is verified, go to home
      Navigator.pushReplacementNamed(context, "home");
    } else {
      // If not logged in or email not verified, go to start screen
      Navigator.pushReplacementNamed(context, "start");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Icon(
              Icons.health_and_safety, // Replace with your app's icon
              size: 100,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 20),
            const Text(
              "GlucoWise",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(), // Loading indicator
          ],
        ),
      ),
    );
  }
}