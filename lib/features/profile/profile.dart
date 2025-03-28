import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:g21285878naveen/features/home/home.dart';
import 'package:g21285878naveen/features/profile/sugar_limit.dart';

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
  String _gender = "Not set"; // Updated from _sex to match other screens
  String _age = "Not set";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            _currentLimit =
                "${(doc['sugarLimit'] as num?)?.toStringAsFixed(1) ?? (doc['recommendedSugarIntake'] as num?)?.toStringAsFixed(1) ?? 'Not set'} g";
            _username =
                doc['username'] as String? ?? user.displayName ?? 'Not set';
            _height = "${doc['height'] as num? ?? 'Not set'} cm";
            _weight = "${doc['weight'] as num? ?? 'Not set'} kg";
            _gender = doc['gender'] as String? ??
                'Not set'; // Changed from 'sex' to 'gender'
            _age = "${doc['age'] as num? ?? 'Not set'} years";
            _isLoading = false;
          });
        }
      } catch (e) {
        print("Error loading user data: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to load data: $e"),
              backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Header
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor:
                                    Colors.purpleAccent.withOpacity(0.2),
                                child: const Icon(Icons.person,
                                    size: 60, color: Colors.purpleAccent),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _username,
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purpleAccent),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Manage your account details",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // User Information Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Your Details",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple),
                              ),
                              const SizedBox(height: 10),
                              _buildInfoTile(
                                  "Username", _username, Icons.person_outline),
                              _buildInfoTile("Height", _height, Icons.height),
                              _buildInfoTile(
                                  "Weight", _weight, Icons.fitness_center),
                              _buildInfoTile(
                                  "Gender", _gender, Icons.people_alt),
                              _buildInfoTile("Age", _age, Icons.cake),
                              _buildInfoTile("Daily Sugar Limit", _currentLimit,
                                  Icons.local_drink),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      _buildActionButton(
                        "Set Sugar Limit",
                        Colors.purple,
                        Icons.settings,
                        () => _navigateTo(10), // SugarLimitPage
                      ),
                      const SizedBox(height: 15),
                      _buildActionButton(
                        "Update Account",
                        Colors.purple,
                        Icons.edit,
                        () => _navigateTo(6), // UpdateAccountScreen
                      ),
                      const SizedBox(height: 15),
                      _buildActionButton(
                        "Change Email",
                        Colors.purple,
                        Icons.email,
                        () => _navigateTo(7), // ChangeEmailScreen
                      ),
                      const SizedBox(height: 15),
                      _buildActionButton(
                        "Log Out",
                        Colors.redAccent,
                        Icons.logout,
                        () => _navigateTo(8), // LogoutScreen
                      ),
                      const SizedBox(height: 15),
                      _buildActionButton(
                        "Back to Home",
                        Colors.grey,
                        Icons.arrow_back,
                        () => _navigateTo(0), // Homescreen
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Helper method to build info tiles
  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build action buttons
  Widget _buildActionButton(
      String label, Color color, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 300,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          elevation: 5,
        ),
      ),
    );
  }

  // Helper method to navigate
  void _navigateTo(int index) {
    HomepageState? homepageState =
        context.findAncestorStateOfType<HomepageState>();
    homepageState?.setState(() => homepageState.myIndex = index);
  }
}
