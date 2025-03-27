import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TDEECalculatorScreen extends StatefulWidget {
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
  bool _showLoginButton = false; // Flag to show the login button after email verification

  final Map<String, double> _activityMultipliers = {
    'Sedentary': 1.2,
    'Lightly Active': 1.375,
    'Moderately Active': 1.55,
    'Very Active': 1.725,
    'Extra Active': 1.9,
  };

  void _calculateTDEEAndSugar() async {
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

    double bmr;
    if (_gender == 'Male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    double activityMultiplier = _activityMultipliers[_activityLevel]!;
    double tdee = bmr * activityMultiplier;
    double sugarCalories = tdee * 0.10;
    double sugarGrams = sugarCalories / 4;

    setState(() {
      _tdeeResult = tdee;
      _sugarRecommendation = sugarGrams;
    });

    // Save to Firestore and send email verification
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

        // Send email verification after TDEE calculation
        await user.sendEmailVerification();
        _showSnackBar("Verification email sent. Please check your email.");

        // Show the login button instead of navigating directly
        setState(() {
          _showLoginButton = true;
        });
      } catch (e) {
        _showSnackBar("Error saving data or sending email: $e");
      }
    } else {
      _showSnackBar("No user logged in. Please sign up again.");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains("Error") ? Colors.red : Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TDEE & Sugar Calculator'),
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
                    decoration: InputDecoration(
                      labelText: 'Height (cm)',
                      hintText: 'Enter your height in centimeters',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16.0),
                  TextField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      labelText: 'Weight (kg)',
                      hintText: 'Enter your weight in kilograms',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16.0),
                  TextField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: 'Age (years)',
                      hintText: 'Enter your age',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: InputDecoration(labelText: 'Gender'),
                    items: ['Male', 'Female']
                        .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    value: _activityLevel,
                    decoration: InputDecoration(labelText: 'Activity Level'),
                    items: _activityMultipliers.keys
                        .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _activityLevel = value!;
                      });
                    },
                  ),
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: _calculateTDEEAndSugar,
                    child: Text('Calculate TDEE & Sugar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Text(
                    'TDEE: ${_tdeeResult.toStringAsFixed(0)} kcal',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Recommended Sugar: ${_sugarRecommendation.toStringAsFixed(1)} g',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 20.0),
                  if (_showLoginButton) // Show button only after email verification
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, "login");
                      },
                      child: Text('Go to Login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
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

// Wrapper for routing purposes
class BMICalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TDEECalculatorScreen();
  }
}