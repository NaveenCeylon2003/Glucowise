import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:g21285878naveen/features/home/home.dart'; // For navigation

class UpdateAccountScreen extends StatefulWidget {
  const UpdateAccountScreen({super.key});

  @override
  _UpdateAccountScreenState createState() => _UpdateAccountScreenState();
}

class _UpdateAccountScreenState extends State<UpdateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'Male';
  String _activityLevel = 'Sedentary';
  bool _isLoading = false;

  final Map<String, double> _activityMultipliers = {
    'Sedentary': 1.2,
    'Lightly Active': 1.375,
    'Moderately Active': 1.55,
    'Very Active': 1.725,
    'Extra Active': 1.9,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load existing user data from Firestore
  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            _usernameController.text = doc['username'] as String? ?? user.displayName ?? '';
            _heightController.text = (doc['height'] as num?)?.toString() ?? '';
            _weightController.text = (doc['weight'] as num?)?.toString() ?? '';
            _ageController.text = (doc['age'] as num?)?.toString() ?? '';
            _gender = doc['gender'] as String? ?? 'Male';
            _activityLevel = doc['activityLevel'] as String? ?? 'Sedentary';
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load data: $e")),
        );
      }
    }
  }

  // Save updated user data to Firestore
  Future<void> _updateUserData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        try {
          double? height = double.tryParse(_heightController.text.trim());
          double? weight = double.tryParse(_weightController.text.trim());
          int? age = int.tryParse(_ageController.text.trim());

          if (height == null || weight == null || age == null || height <= 0 || weight <= 0 || age <= 0) {
            _showSnackBar("Please enter valid positive numbers for height, weight, and age.");
            setState(() => _isLoading = false);
            return;
          }

          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'username': _usernameController.text.trim(),
            'height': height,
            'weight': weight,
            'age': age,
            'gender': _gender,
            'activityLevel': _activityLevel,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          _showSnackBar("Account updated successfully.");

          // Navigate back to ProfilePage (index 2)
          HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
          homepageState?.setState(() => homepageState.myIndex = 2);
        } catch (e) {
          _showSnackBar("Error updating account: $e");
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        _showSnackBar("No user logged in.");
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains("Error") ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Account"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              width: 300,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      "Update Account",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter your username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter a username.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                        hintText: 'Enter your height in centimeters',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter your height.";
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return "Enter a valid positive number.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        hintText: 'Enter your weight in kilograms',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter your weight.";
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return "Enter a valid positive number.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age (years)',
                        hintText: 'Enter your age',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter your age.";
                        }
                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                          return "Enter a valid positive number.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Male', 'Female']
                          .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                          .toList(),
                      onChanged: (value) => setState(() => _gender = value!),
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      value: _activityLevel,
                      decoration: const InputDecoration(
                        labelText: 'Activity Level',
                        border: OutlineInputBorder(),
                      ),
                      items: _activityMultipliers.keys
                          .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                          .toList(),
                      onChanged: (value) => setState(() => _activityLevel = value!),
                    ),
                    const SizedBox(height: 20.0),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _updateUserData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      child: const Text(
                        "Update Account",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
                        homepageState?.setState(() => homepageState.myIndex = 2); // Back to ProfilePage
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
          ),
        ),
      ),
    );
  }
}