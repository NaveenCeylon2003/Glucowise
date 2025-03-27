import 'dart:convert';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart'; // Add file_picker

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to save food data.")),
      );
      return;
    }

    try {
      String docId = "${key.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}";
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

      print("Saved to Firestore (scanned_foods): $docId - Sugar: $sugarContent");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving to Firestore: $e")),
      );
    }
  }

  Future<void> _scanBarcode() async {
    setState(() {
      _isLoading = true;
      _sugarContent = "Scanning...";
    });

    try {
      if (!kIsWeb) {
        // Mobile: Use camera to scan barcode
        String barcode = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", // Overlay color
          "Cancel", // Cancel button text
          true, // Show flash icon
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
        // Web: Use file picker to upload an image
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
        // TODO: Add barcode detection from image (e.g., using google_ml_kit)
        // For now, we just acknowledge the upload
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
    // Check cached data first
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

    // Check connectivity
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _sugarContent = "No network connection. Please try again.";
      });
      return;
    }

    // Fetch data from OpenFoodFacts API
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Barcode")),
      body: Center(
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
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _scanBarcode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  kIsWeb ? "Upload Image" : "Scan Barcode",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Simple back navigation
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
      ),
    );
  }
}