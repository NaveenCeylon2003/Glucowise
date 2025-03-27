import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:g21285878naveen/features/home/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BarcodeEntryPage extends StatefulWidget {
  const BarcodeEntryPage({super.key});

  @override
  _BarcodeEntryPageState createState() => _BarcodeEntryPageState();
}

class _BarcodeEntryPageState extends State<BarcodeEntryPage> {
  String _sugarContent = "Enter a barcode to fetch sugar content";
  String _foodName = "Unknown Product";
  final TextEditingController _barcodeController = TextEditingController();
  bool _isLoading = false;

  // Load SharedPreferences instance
  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // Check and load cached data from SharedPreferences
  Future<Map<String, dynamic>?> _getCachedBarcodeData(String barcode) async {
    final prefs = await _getPrefs();
    final cachedData = prefs.getString(barcode);
    if (cachedData != null) {
      return jsonDecode(cachedData) as Map<String, dynamic>;
    }
    return null;
  }

  // Save barcode data to SharedPreferences
  Future<void> _saveToSharedPreferences(String barcode, String foodName, double? sugarContent) async {
    final prefs = await _getPrefs();
    final data = {
      'foodName': foodName,
      'sugarContent': sugarContent,
    };
    await prefs.setString(barcode, jsonEncode(data));
  }

  // Save barcode data to Firestore
  Future<void> _saveToFirestore(String barcode, String foodName, double? sugarContent) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to save barcode data.")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scanned_barcodes')
          .doc(barcode)
          .set({
        'barcode': barcode,
        'foodName': foodName,
        'sugarContent': sugarContent,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving to Firestore: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _sugarContent,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            if (_foodName != "Unknown Product")
              Text(
                "Product: $_foodName",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 30),
            TextField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: "Enter Barcode",
                prefixIcon: Icon(Icons.bar_chart_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                  _sugarContent = "Fetching data...";
                });

                try {
                  String barcode = _barcodeController.text.trim();
                  if (barcode.isEmpty) {
                    setState(() {
                      _sugarContent = "Please enter a barcode.";
                      _isLoading = false;
                    });
                    return;
                  }

                  // Check local cache first
                  final cachedData = await _getCachedBarcodeData(barcode);
                  if (cachedData != null) {
                    setState(() {
                      _foodName = cachedData['foodName'] as String;
                      final sugar = cachedData['sugarContent'] as double?;
                      _sugarContent = sugar != null
                          ? "Sugar content: $sugar g per 100g (cached)"
                          : "Sugar data not available for $_foodName (cached)";
                      _isLoading = false;
                    });
                    return; // Exit if cached data is found
                  }

                  // Check connectivity for internet fetch
                  var connectivityResult = await Connectivity().checkConnectivity();
                  if (connectivityResult == ConnectivityResult.none) {
                    setState(() {
                      _sugarContent = "No network connection. Please try again.";
                      _isLoading = false;
                    });
                    return;
                  }

                  // Fetch from OpenFoodFacts API
                  String apiUrl = "https://world.openfoodfacts.org/api/v2/product/$barcode.json";
                  var response = await http.get(Uri.parse(apiUrl));

                  if (response.statusCode == 200) {
                    var data = jsonDecode(response.body);

                    if (data["status"] == 1) {
                      _foodName = data["product"]["product_name"] ?? "Unknown Product";
                      double? sugar = data["product"]["nutriments"]["sugars_100g"];

                      setState(() {
                        if (sugar != null) {
                          _sugarContent = "Sugar content: $sugar g per 100g";
                        } else {
                          _sugarContent = "Sugar data not available for $_foodName";
                        }
                      });

                      // Save to both SharedPreferences and Firestore
                      await _saveToSharedPreferences(barcode, _foodName, sugar);
                      await _saveToFirestore(barcode, _foodName, sugar);
                    } else {
                      setState(() {
                        _sugarContent = "Product not found in database.";
                      });
                    }
                  } else if (response.statusCode == 429) {
                    setState(() {
                      _sugarContent = "Rate limit exceeded. Please wait and try again.";
                    });
                  } else {
                    setState(() {
                      _sugarContent = "Error: Failed to fetch data (Status: ${response.statusCode})";
                    });
                  }
                } catch (e) {
                  setState(() {
                    _sugarContent = "Error: $e";
                  });
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text(
                "Fetch Sugar Content",
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
      ),
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }
}