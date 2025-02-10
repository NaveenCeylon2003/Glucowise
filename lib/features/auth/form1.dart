import 'package:flutter/material.dart';
import 'package:g21285878naveen/features/auth/signupform.dart';

void main() {
  runApp(BMICalculatorApp());
}

class BMICalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: "bmi",
      routes: {
        "signup":(context)=> Signupscreen()
      },
      title: 'BMI Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BMICalculatorScreen(),
    );
  }
}

class BMICalculatorScreen extends StatefulWidget {
  @override
  _BMICalculatorScreenState createState() => _BMICalculatorScreenState();
}

class _BMICalculatorScreenState extends State<BMICalculatorScreen> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  double _bmiResult = 0.0;
  String _bmiCategory = '';

  void _calculateBMI() {
    String heightText = _heightController.text.trim();
    String weightText = _weightController.text.trim();

    // Validate input
    if (heightText.isEmpty || weightText.isEmpty) {
      _showSnackBar("Please enter both height and weight.");
      return;
    }

    double? height = double.tryParse(heightText);
    double? weight = double.tryParse(weightText);

    if (height == null || weight == null || height <= 0 || weight <= 0) {
      _showSnackBar("Invalid input. Height and weight must be positive numbers.");
      return;
    }

    // Convert cm to meters safely using the '!' operator, since we've validated it's not null
    double heightInMeters = height / 100;

    setState(() {
      _bmiResult = weight / (heightInMeters * heightInMeters);
      _bmiCategory = _getBMICategory(_bmiResult);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }


  String _getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi >= 18.5 && bmi < 24.9) {
      return 'Normal weight';
    } else if (bmi >= 25 && bmi < 29.9) {
      return 'Overweight';
    } else {
      return 'Obesity: Higher risk of type 2 diabetes.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BMI Calculator'),
      ),
      body: Padding(
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
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: _calculateBMI,
                    child: Text('Calculate BMI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Text(
                    'BMI: ${_bmiResult.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Category: $_bmiCategory',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_bmiResult > 0) {
                        //_showSnackBar(_getBMICategory(_bmiResult));
                        Navigator.pushNamed(context, "signup");
                      }
                    },
                    child: Text("Let's start tracking"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                  ),

                ],
              ),
            ),
          )),
    );
  }
}
