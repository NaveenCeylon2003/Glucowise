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
  final TextEditingController _amountConsumedController = TextEditingController();
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

  // Save barcode data to SharedPreferences (only sugarPer100g and foodName)
  Future<void> _saveToSharedPreferences(String barcode, String foodName, double? sugarPer100g) async {
    final prefs = await _getPrefs();
    final data = {
      'foodName': foodName,
      'sugarPer100g': sugarPer100g,
    };
    await prefs.setString(barcode, jsonEncode(data));
  }

  // Save barcode data to Firestore with real-time daily summary update
  Future<void> _saveToFirestore(String barcode, String foodName, double? sugarPer100g, double? sugarConsumed, double? amountConsumed) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to save barcode data.")),
      );
      return;
    }

    try {
      String docId = "${barcode}_${DateTime.now().millisecondsSinceEpoch}";
      String today = DateTime.now().toString().split(' ')[0];

      // Save individual barcode entry
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scanned_barcodes')
          .doc(docId)
          .set({
        'barcode': barcode,
        'foodName': foodName,
        'sugarPer100g': sugarPer100g,
        'sugarConsumed': sugarConsumed,
        'amountConsumed': amountConsumed,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Increment total sugar in daily_summaries
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('daily_summaries')
          .doc(today)
          .set({
        'date': today,
        'totalSugar': FieldValue.increment(sugarConsumed ?? 0.0),
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // No need to manually refresh Homepage, as it uses a real-time listener
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving to Firestore: $e")),
      );
    }
  }

  Future<void> _searchBarcode() async {
    String barcode = _barcodeController.text.trim();
    String amountText = _amountConsumedController.text.trim();

    if (barcode.isEmpty) {
      setState(() {
        _sugarContent = "Please enter a barcode.";
        _isLoading = false;
      });
      return;
    }

    if (amountText.isEmpty) {
      setState(() {
        _sugarContent = "Please enter the amount consumed.";
        _isLoading = false;
      });
      return;
    }

    double? amountConsumed = double.tryParse(amountText);
    if (amountConsumed == null || amountConsumed <= 0) {
      setState(() {
        _sugarContent = "Please enter a valid positive amount.";
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
        // Fetch fresh data from API if network is available
        String apiUrl = "https://world.openfoodfacts.org/api/v2/product/$barcode.json";
        var response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);

          if (data["status"] == 1) {
            _foodName = data["product"]["product_name"] ?? "Unknown Product";
            double? sugarPer100g = data["product"]["nutriments"]["sugars_100g"]?.toDouble();

            double? sugarConsumed;
            if (sugarPer100g != null) {
              sugarConsumed = (sugarPer100g / 100) * amountConsumed;
            }

            setState(() {
              _sugarContent = sugarConsumed != null
                  ? "Sugar consumed: ${sugarConsumed.toStringAsFixed(1)} g\n(Sugar per 100g: $sugarPer100g g)"
                  : "Sugar data not available for $_foodName";
            });

            await _saveToSharedPreferences(barcode, _foodName, sugarPer100g);
            await _saveToFirestore(barcode, _foodName, sugarPer100g, sugarConsumed, amountConsumed);
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
      } else {
        // Fallback to cached data only if no network is available
        final cachedData = await _getCachedBarcodeData(barcode);
        if (cachedData != null) {
          setState(() {
            _foodName = cachedData['foodName'] as String;
            final sugarPer100g = cachedData['sugarPer100g'] as double?;
            if (sugarPer100g != null) {
              final sugarConsumed = (sugarPer100g / 100) * amountConsumed;
              _sugarContent = "Sugar consumed: ${sugarConsumed.toStringAsFixed(1)} g (cached)\n(Sugar per 100g: $sugarPer100g g)";
            } else {
              _sugarContent = "Sugar data not available for $_foodName (cached)";
            }
            _isLoading = false;
          });
          final sugarPer100g = cachedData['sugarPer100g'] as double?;
          final sugarConsumed = sugarPer100g != null ? (sugarPer100g / 100) * amountConsumed : null;
          await _saveToFirestore(barcode, _foodName, sugarPer100g, sugarConsumed, amountConsumed);
        } else {
          setState(() {
            _sugarContent = "No network connection and no cached data available.";
            _isLoading = false;
          });
        }
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
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16.0),
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
              const SizedBox(height: 20),
              TextField(
                controller: _amountConsumedController,
                decoration: const InputDecoration(
                  labelText: "Amount Consumed (g)",
                  prefixIcon: Icon(Icons.fastfood),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _searchBarcode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  "Calculate Sugar Content",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
                  if (homepageState != null) {
                    homepageState.setState(() => homepageState.myIndex = 0); // Back to Homescreen
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text("Back", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _amountConsumedController.dispose();
    super.dispose();
  }
}