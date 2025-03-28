import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:g21285878naveen/features/home/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class BarcodeEntryPage extends StatefulWidget {
  const BarcodeEntryPage({super.key});

  @override
  _BarcodeEntryPageState createState() => _BarcodeEntryPageState();
}

class _BarcodeEntryPageState extends State<BarcodeEntryPage> {
  String _sugarContent = "Enter a barcode to fetch sugar content";
  String _foodName = "Unknown Product";
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _amountConsumedController =
      TextEditingController();
  bool _isLoading = false;

  Future<void> _searchBarcode() async {
    String barcode = _barcodeController.text.trim();
    String amountText = _amountConsumedController.text.trim();

    if (barcode.isEmpty || amountText.isEmpty) {
      setState(() {
        _sugarContent = "Please enter valid details.";
        _isLoading = false;
      });
      return;
    }

    double? amountConsumed = double.tryParse(amountText);
    if (amountConsumed == null || amountConsumed <= 0) {
      setState(() {
        _sugarContent = "Please enter a valid amount.";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _sugarContent = "Fetching data...";
    });

    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        String apiUrl =
            "https://world.openfoodfacts.org/api/v2/product/$barcode.json";
        var response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          if (data["status"] == 1) {
            _foodName = data["product"]["product_name"] ?? "Unknown Product";
            double? sugarPer100g =
                data["product"]["nutriments"]["sugars_100g"]?.toDouble();

            double? sugarConsumed = sugarPer100g != null
                ? (sugarPer100g / 100) * amountConsumed
                : null;
            setState(() {
              _sugarContent = sugarConsumed != null
                  ? "Sugar consumed: ${sugarConsumed.toStringAsFixed(1)} g\n(Sugar per 100g: $sugarPer100g g)"
                  : "Sugar data not available for $_foodName";
            });

            // Save to Firestore
            await _saveToFirestore(barcode, _foodName, sugarPer100g,
                sugarConsumed, amountConsumed);
            _showSnackBar("Barcode data saved successfully!", Colors.green);
          } else {
            setState(() {
              _sugarContent = "Product not found.";
            });
          }
        } else {
          setState(() {
            _sugarContent =
                "Error: Failed to fetch data (Status: ${response.statusCode})";
          });
        }
      } else {
        setState(() {
          _sugarContent = "No internet connection.";
        });
      }
    } catch (e) {
      setState(() {
        _sugarContent = "Error: $e";
      });
      _showSnackBar("Error fetching data: $e", Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToFirestore(
      String barcode,
      String foodName,
      double? sugarPer100g,
      double? sugarConsumed,
      double? amountConsumed) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("Please log in to save barcode data.");
      return;
    }

    try {
      String docId = "${barcode}_${DateTime.now().millisecondsSinceEpoch}";
      String today = DateTime.now().toString().split(' ')[0];

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scanned_foods')
          .doc(docId)
          .set({
        'barcode': barcode,
        'foodName': foodName,
        'sugarPer100g': sugarPer100g,
        'sugarConsumed': sugarConsumed,
        'amountConsumed': amountConsumed,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('daily_summaries')
          .doc(today)
          .set({
        'totalSugar': FieldValue.increment(sugarConsumed ?? 0.0),
        'date': today,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      _showSnackBar("Error saving to Firestore: $e", Colors.red);
    }
  }

  void _showSnackBar(String message, [Color? backgroundColor]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.grey,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Barcode Sugar Checker",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
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
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Scan Barcode",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple),
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(_barcodeController, "Enter Barcode",
                          "e.g., 123456789", Icons.barcode_reader),
                      const SizedBox(height: 10),
                      _buildTextField(_amountConsumedController,
                          "Amount Consumed (g)", "e.g., 100", Icons.fastfood),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _searchBarcode,
                                icon: const Icon(Icons.search,
                                    color: Colors.white),
                                label: const Text("Calculate Sugar Content",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purpleAccent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  elevation: 5,
                                ),
                              ),
                            ),
                      const SizedBox(height: 20),
                      Text(
                        _sugarContent,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HomepageState? homepageState = context
                                .findAncestorStateOfType<HomepageState>();
                            if (homepageState != null) {
                              homepageState
                                  .setState(() => homepageState.myIndex = 0);
                            }
                          },
                          icon: const Icon(Icons.home, color: Colors.white),
                          label: const Text("Back to Home",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18)),
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

  Widget _buildTextField(TextEditingController controller, String label,
      String hint, IconData icon) {
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
      keyboardType:
          label.contains("Amount") ? TextInputType.number : TextInputType.text,
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _amountConsumedController.dispose();
    super.dispose();
  }
}
