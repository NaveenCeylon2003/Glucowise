import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TDEECalculatorScreen extends StatefulWidget {
  const TDEECalculatorScreen({super.key});

  @override
  _TDEECalculatorScreenState createState() => _TDEECalculatorScreenState();
}

class _TDEECalculatorScreenState extends State<TDEECalculatorScreen> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _gender = 'Male';
  String _activityLevel = 'Sedentary';
  double _tdeeResult = 0.0;
  double _sugarRecommendation = 0.0;
  bool _isLoading = false;

  final Map<String, double> _activityMultipliers = {
    'Sedentary': 1.2,
    'Lightly Active': 1.375,
    'Moderately Active': 1.55,
    'Very Active': 1.725,
    'Extra Active': 1.9,
  };

  Future<void> _calculateTDEEAndSugar() async {
    setState(() => _isLoading = true);
    String heightText = _heightController.text.trim();
    String weightText = _weightController.text.trim();
    String ageText = _ageController.text.trim();

    if (heightText.isEmpty || weightText.isEmpty || ageText.isEmpty) {
      _showSnackBar("Please enter height, weight, and age.");
      setState(() => _isLoading = false);
      return;
    }

    double? height = double.tryParse(heightText);
    double? weight = double.tryParse(weightText);
    int? age = int.tryParse(ageText);

    if (height == null || weight == null || age == null || height <= 0 || weight <= 0 || age <= 0) {
      _showSnackBar("Invalid input. All values must be positive numbers.");
      setState(() => _isLoading = false);
      return;
    }

    double bmr = _gender == 'Male'
        ? 10 * weight + 6.25 * height - 5 * age + 5
        : 10 * weight + 6.25 * height - 5 * age - 161;

    double activityMultiplier = _activityMultipliers[_activityLevel]!;
    double tdee = bmr * activityMultiplier;
    double sugarCalories = tdee * 0.10;
    double sugarGrams = sugarCalories / 4;

    setState(() {
      _tdeeResult = tdee;
      _sugarRecommendation = sugarGrams;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'height': height,
          'weight': weight,
          'age': age,
          'gender': _gender,
          'activityLevel': _activityLevel,
          'tdee': tdee,
          'recommendedSugarIntake': sugarGrams,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        _showSnackBar("Data saved successfully.");

        try {
          await user.sendEmailVerification();
          _showSnackBar("Verification email sent. Please check your email.");
        } catch (emailError) {
          _showSnackBar("Failed to send verification email: $emailError");
        }

        Navigator.pushReplacementNamed(context, "home");
      } catch (e) {
        _showSnackBar("Error saving data: $e");
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      _showSnackBar("No user logged in. Please sign in.");
      setState(() => _isLoading = false);
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
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TDEE & Sugar Calculator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.withOpacity(0.8), Colors.deepPurple.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Calculate Your TDEE",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Enter your details to get started",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(_heightController, "Height (cm)", "e.g., 170", Icons.height),
                      const SizedBox(height: 16),
                      _buildTextField(_weightController, "Weight (kg)", "e.g., 70", Icons.fitness_center),
                      const SizedBox(height: 16),
                      _buildTextField(_ageController, "Age (years)", "e.g., 30", Icons.cake),
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
                          onPressed: _isLoading ? null : _calculateTDEEAndSugar,
                          icon: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : const Icon(Icons.calculate, color: Colors.white),
                          label: Text(
                            _isLoading ? "Calculating..." : "Calculate TDEE & Sugar",
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_tdeeResult > 0) ...[
                        _buildResultCard("TDEE", "${_tdeeResult.toStringAsFixed(0)} kcal", Colors.purple),
                        const SizedBox(height: 10),
                        _buildResultCard("Recommended Sugar", "${_sugarRecommendation.toStringAsFixed(1)} g", Colors.deepPurple),
                      ],
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
  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon) {
    return TextField(
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
      keyboardType: TextInputType.number,
    );
  }

  // Helper method to build dropdown fields
  Widget _buildDropdownField(String label, String value, List<String> items, Function(String?) onChanged, IconData icon) {
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
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  // Helper method to build result cards
  Widget _buildResultCard(String label, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
          ],
        ),
      ),
    );
  }
}

class BMICalculatorApp extends StatelessWidget {
  const BMICalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const TDEECalculatorScreen();
  }
}