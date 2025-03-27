import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:g21285878naveen/features/home/home.dart';
import 'package:g21285878naveen/features/profile/sugar_limit.dart'; // Import SugarLimitPage

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _currentLimit = "Not set";
  String _username = "Not set";
  String _height = "Not set";
  String _weight = "Not set";
  String _sex = "Not set";
  String _age = "Not set";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _currentLimit = "${(doc['sugarLimit'] as num?)?.toStringAsFixed(1) ?? (doc['recommendedSugarIntake'] as num?)?.toStringAsFixed(1) ?? 'Not set'} g";
          _username = doc['username'] as String? ?? user.displayName ?? 'Not set';
          _height = "${doc['height'] as num? ?? 'Not set'} cm";
          _weight = "${doc['weight'] as num? ?? 'Not set'} kg";
          _sex = doc['gender'] as String? ?? 'Not set';
          _age = "${doc['age'] as num? ?? 'Not set'} years";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Profile Settings",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // User Information Section
              _buildInfoRow("Username", _username),
              const SizedBox(height: 10),
              _buildInfoRow("Height", _height),
              const SizedBox(height: 10),
              _buildInfoRow("Weight", _weight),
              const SizedBox(height: 10),
              _buildInfoRow("Gender", _sex),
              const SizedBox(height: 10),
              _buildInfoRow("Age", _age),
              const SizedBox(height: 10),
              _buildInfoRow("Daily Sugar Limit", _currentLimit),
              const SizedBox(height: 30),
              // Buttons Section
              ElevatedButton(
                onPressed: () {
                  HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
                  homepageState?.setState(() => homepageState.myIndex = 10); // Navigate to SugarLimitPage
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text("Set Sugar Limit", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
                  homepageState?.setState(() => homepageState.myIndex = 6); // Update Account
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text("Update Account", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
                  homepageState?.setState(() => homepageState.myIndex = 7); // Change Email
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text("Change Email", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
                  homepageState?.setState(() => homepageState.myIndex = 8); // Logout
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text("Log Out", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
                  homepageState?.setState(() => homepageState.myIndex = 0); // Back to Homescreen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text("Back", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build info rows
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$label:",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}