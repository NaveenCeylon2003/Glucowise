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
      switch (_selectedMethod) {
        case "Barcode Entry":
          homepageState.setState(() => homepageState.myIndex = 5);
          break;
        case "Photo Scanner":
          homepageState.setState(() => homepageState.myIndex = 4);
          break;
        case "Search by Name":
          homepageState.setState(() => homepageState.myIndex = 9);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Scan Method"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Select your preferred scanning method",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              onChanged: (String? newValue) {
                setState(() => _selectedMethod = newValue!);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _scanMethods.map((String method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Text(method, style: const TextStyle(fontSize: 16)),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: _navigateBasedOnSelection,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Proceed"),
            ),
            const SizedBox(height: 15),
            FilledButton.tonal(
              onPressed: () {
                HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
                homepageState?.setState(() => homepageState.myIndex = 0);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Back"),
            ),
          ],
        ),
      ),
    );
  }
}

