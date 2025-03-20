import 'package:flutter/material.dart';
import 'package:g21285878naveen/features/scan/scan.dart';
import 'package:g21285878naveen/features/scan/barcode_entry.dart'; // Import the new page

void main() {
  runApp(const Scanroutes());
}

class Scanroutes extends StatelessWidget {
  const Scanroutes({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "options",
      routes: {
        "options": (context) => const Scanoptions(),
        "scan": (context) => const ScanPage(), // Fixed: Added const
        "barcode": (context) => const BarcodeEntryPage(), // Fixed: Added const
      },
    );
  }
}

class Scanoptions extends StatefulWidget {
  const Scanoptions({super.key});

  @override
  _ScanoptionsState createState() => _ScanoptionsState();
}

class _ScanoptionsState extends State<Scanoptions> {
  String _selectedMethod = "Barcode Entry";
  final List<String> _scanMethods = ["Barcode Entry", "Photo Scanner"];

  void _navigateBasedOnSelection() {
    if (!mounted) return;

    if (_selectedMethod == "Barcode Entry") {
      Navigator.of(context).pushNamed("barcode");
    } else if (_selectedMethod == "Photo Scanner") {
      Navigator.of(context).pushNamed("scan"); // For testing barcode scanner later
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Options")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Select your preferred method of scanning",
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
          ],
        ),
      ),
    );
  }
}