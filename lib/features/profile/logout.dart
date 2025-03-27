import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:g21285878naveen/features/auth/login.dart'; // Import Login screen for navigation

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  // Function to handle logout with confirmation
  Future<void> _confirmLogout(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut(); // Sign out from Firebase
        // Navigate to Login screen and clear the navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()),
              (Route<dynamic> route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout failed: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Logout"),
        backgroundColor: Colors.redAccent,
      ),
      body: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Logout",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                "Are you ready to sign out of your account?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _confirmLogout(context), // Trigger confirmation
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  "Log Out",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Back to previous screen (ProfilePage)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  "Back",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}