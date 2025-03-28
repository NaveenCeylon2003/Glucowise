import 'dart:convert';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  String _sugarContent = "Press the button to scan a barcode or upload an image";
  String _foodName = "Unknown Product";
  bool _isLoading = false;

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future<Map<String, dynamic>?> _getCachedFoodData(String key) async {
    final prefs = await _getPrefs();
    final cachedData = prefs.getString(key.toLowerCase());
    if (cachedData != null) {
      return jsonDecode(cachedData) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> _saveToSharedPreferences(String key, String foodName, double? sugarContent) async {
    final prefs = await _getPrefs();
    final data = {
      'foodName': foodName,
      'sugarContent': sugarContent,
    };
    await prefs.setString(key.toLowerCase(), jsonEncode(data));
  }

  Future<void> _saveToFirestore(String key, String foodName, double? sugarContent) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("Please log in to save food data.");
      return;
    }

    try {
      String docId = "${key.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}";
      String today = DateTime.now().toString().split(' ')[0];

      // Save to scanned_foods collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scanned_foods')
          .doc(docId)
          .set({
        'barcode': key,
        'foodName': foodName,
        'sugarContent': sugarContent,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Increment total sugar in daily_summaries (assuming sugarContent is per 100g, adjust if needed)
      if (sugarContent != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('daily_summaries')
            .doc(today)
            .set({
          'totalSugar': FieldValue.increment(sugarContent),
          'date': today,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      _showSnackBar("Food data saved successfully!", Colors.green);
    } catch (e) {
      _showSnackBar("Error saving to Firestore: $e", Colors.red);
    }
  }

  Future<void> _scanBarcode() async {
    setState(() {
      _isLoading = true;
      _sugarContent = "Scanning...";
    });

    try {
      if (!kIsWeb) {
        String barcode = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666",
          "Cancel",
          true,
          ScanMode.BARCODE,
        );

        if (barcode == "-1") {
          setState(() {
            _sugarContent = "Scan cancelled.";
            _isLoading = false;
          });
          return;
        }
        await _processBarcode(barcode);
      } else {
        await _uploadImageForWeb();
      }
    } catch (e) {
      setState(() {
        _sugarContent = "Error: $e";
      });
      debugPrint("Error details: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadImageForWeb() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _sugarContent = "Image uploaded. Barcode detection not implemented.";
          _foodName = "Image-based Product";
        });
        // TODO: Implement barcode detection from image (e.g., google_ml_kit)
      } else {
        setState(() {
          _sugarContent = "No image selected.";
        });
      }
    } catch (e) {
      setState(() {
        _sugarContent = "Error uploading image: $e";
      });
    }
  }

  Future<void> _processBarcode(String barcode) async {
    final cachedData = await _getCachedFoodData(barcode);
    if (cachedData != null) {
      setState(() {
        _foodName = cachedData['foodName'] as String;
        final sugar = cachedData['sugarContent'] as double?;
        _sugarContent = sugar != null
            ? "Sugar content: $sugar g per 100g (cached)"
            : "Sugar data not available for $_foodName (cached)";
      });
      await _saveToFirestore(barcode, _foodName, cachedData['sugarContent'] as double?);
      return;
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _sugarContent = "No network connection. Please try again.";
      });
      return;
    }

    String apiUrl = "https://world.openfoodfacts.org/api/v0/product/$barcode.json";
    var response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['status'] == 1) {
        _foodName = data['product']['product_name'] ?? "Unknown Product";
        double? sugar = data['product']['nutriments']?['sugars_100g']?.toDouble();

        setState(() {
          _sugarContent = sugar != null
              ? "Sugar content: $sugar g per 100g"
              : "Sugar data not available for $_foodName";
        });

        await _saveToSharedPreferences(barcode, _foodName, sugar);
        await _saveToFirestore(barcode, _foodName, sugar);
      } else {
        setState(() {
          _sugarContent = "Product not found with this barcode.";
        });
      }
    } else {
      setState(() {
        _sugarContent = "Error: Failed to fetch data (Status: ${response.statusCode})";
      });
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
        title: const Text(
          "Scan Barcode",
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
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Scan Your Food",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        kIsWeb ? "Upload an image to scan" : "Scan a barcode to get started",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      if (_foodName != "Unknown Product")
                        _buildResultCard("Product", _foodName, Colors.purple),
                      const SizedBox(height: 10),
                      _buildResultCard("Sugar Info", _sugarContent, Colors.deepPurple),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _scanBarcode,
                          icon: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : Icon(kIsWeb ? Icons.upload : Icons.qr_code_scanner, color: Colors.white),
                          label: Text(
                            _isLoading ? "Processing..." : (kIsWeb ? "Upload Image" : "Scan Barcode"),
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
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          label: const Text(
                            "Back",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
          ],
        ),
      ),
    );
  }
}