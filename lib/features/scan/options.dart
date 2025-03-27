import 'package:flutter/material.dart';
import 'package:g21285878naveen/features/home/home.dart'; // Import to access HomepageState

class Scanoptions extends StatefulWidget {
  const Scanoptions({super.key});

  @override
  _ScanoptionsState createState() => _ScanoptionsState();
}

class _ScanoptionsState extends State<Scanoptions> {
  String _selectedMethod = "Barcode Entry";
  final List<String> _scanMethods = ["Barcode Entry", "Photo Scanner", "Search by Name"];

  void _navigateBasedOnSelection() {
    HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
    if (!mounted || homepageState == null) return;

    setState(() {
      if (_selectedMethod == "Barcode Entry") {
        homepageState.setState(() {
          homepageState.myIndex = 5; // Navigate to BarcodeEntryPage
        });
      } else if (_selectedMethod == "Photo Scanner") {
        homepageState.setState(() {
          homepageState.myIndex = 4; // Navigate to ScanPage
        });
      } else if (_selectedMethod == "Search by Name") {
        homepageState.setState(() {
          homepageState.myIndex = 9; // Navigate to FoodSearchPage
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Select your preferred method",
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          DropdownButton<String>(
            value: _selectedMethod,
            onChanged: (String? newValue) {
              setState(() {
                _selectedMethod = newValue!;
              });
            },
            items: _scanMethods.map((String method) {
              return DropdownMenuItem<String>(
                value: method,
                child: Text(method),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            "Selected: $_selectedMethod",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _navigateBasedOnSelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text(
              "Proceed",
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
              homepageState?.setState(() {
                homepageState.myIndex = 0; // Back to Homescreen
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text(
              "Back",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}