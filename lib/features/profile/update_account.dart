import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:g21285878naveen/features/home/home.dart';

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
            _usernameController.text =
                doc['username'] as String? ?? user.displayName ?? '';
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

  Future<void> _updateUserData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        try {
          double? height = double.tryParse(_heightController.text.trim());
          double? weight = double.tryParse(_weightController.text.trim());
          int? age = int.tryParse(_ageController.text.trim());

          if (height == null ||
              weight == null ||
              age == null ||
              height <= 0 ||
              weight <= 0 ||
              age <= 0) {
            _showSnackBar(
                "Please enter valid positive numbers for height, weight, and age.");
            setState(() => _isLoading = false);
            return;
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'username': _usernameController.text.trim(),
            'height': height,
            'weight': weight,
            'age': age,
            'gender': _gender,
            'activityLevel': _activityLevel,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          _showSnackBar("Account updated successfully.");

          HomepageState? homepageState =
              context.findAncestorStateOfType<HomepageState>();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Update Account",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.8),
              Colors.deepPurple.withOpacity(0.8)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Update Your Account",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Edit your profile details",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(_usernameController, "Username",
                          "Enter your username", Icons.person),
                      const SizedBox(height: 16),
                      _buildTextField(_heightController, "Height (cm)",
                          "e.g., 170", Icons.height),
                      const SizedBox(height: 16),
                      _buildTextField(_weightController, "Weight (kg)",
                          "e.g., 70", Icons.fitness_center),
                      const SizedBox(height: 16),
                      _buildTextField(_ageController, "Age (years)", "e.g., 30",
                          Icons.cake),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        "Gender",
                        _gender,
                        ['Male', 'Female'],
                        (value) => setState(() => _gender = value!),
                        Icons.people_alt,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        "Activity Level",
                        _activityLevel,
                        _activityMultipliers.keys.toList(),
                        (value) => setState(() => _activityLevel = value!),
                        Icons.directions_run,
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _updateUserData,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.update, color: Colors.white),
                          label: Text(
                            _isLoading ? "Updating..." : "Update Account",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HomepageState? homepageState = context
                                .findAncestorStateOfType<HomepageState>();
                            homepageState
                                ?.setState(() => homepageState.myIndex = 2);
                          },
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          label: const Text(
                            "Back to Profile",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build text fields
  Widget _buildTextField(TextEditingController controller, String label,
      String hint, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.purple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.purpleAccent, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: label.contains("Username")
          ? TextInputType.text
          : TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Please enter your ${label.toLowerCase()}.";
        }
        if (!label.contains("Username") &&
            (double.tryParse(value) == null || double.parse(value) <= 0)) {
          return "Enter a valid positive number.";
        }
        return null;
      },
    );
  }

  // Helper method to build dropdown fields
  Widget _buildDropdownField(String label, String value, List<String> items,
      Function(String?) onChanged, IconData icon) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.purple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.purpleAccent, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
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
}
