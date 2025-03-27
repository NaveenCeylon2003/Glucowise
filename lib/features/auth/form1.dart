import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TDEECalculatorScreen extends StatefulWidget {
  const TDEECalculatorScreen({super.key}); // Added const constructor

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

  final Map<String, double> _activityMultipliers = {
    'Sedentary': 1.2,
    'Lightly Active': 1.375,
    'Moderately Active': 1.55,
    'Very Active': 1.725,
    'Extra Active': 1.9,
  };

  Future<void> _calculateTDEEAndSugar() async {
    String heightText = _heightController.text.trim();
    String weightText = _weightController.text.trim();
    String ageText = _ageController.text.trim();

    if (heightText.isEmpty || weightText.isEmpty || ageText.isEmpty) {
      _showSnackBar("Please enter height, weight, and age.");
      return;
    }

    double? height = double.tryParse(heightText);
    double? weight = double.tryParse(weightText);
    int? age = int.tryParse(ageText);

    if (height == null || weight == null || age == null || height <= 0 || weight <= 0 || age <= 0) {
      _showSnackBar("Invalid input. All values must be positive numbers.");
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
      }
    } else {
      _showSnackBar("No user logged in. Please sign in.");
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
        title: const Text('TDEE & Sugar Calculator'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              width: 300,
              child: Column(
                children: [
                  TextField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                      hintText: 'Enter your height in centimeters',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      hintText: 'Enter your weight in kilograms',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'Age (years)',
                      hintText: 'Enter your age',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
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
                  ElevatedButton(
                    onPressed: _calculateTDEEAndSugar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: const Text(
                      'Calculate TDEE & Sugar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Text(
                    'TDEE: ${_tdeeResult.toStringAsFixed(0)} kcal',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Recommended Sugar: ${_sugarRecommendation.toStringAsFixed(1)} g',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BMICalculatorApp extends StatelessWidget {
  const BMICalculatorApp({super.key}); // Added const constructor

  @override
  Widget build(BuildContext context) {
    return const TDEECalculatorScreen();
  }
}