import 'dart:convert';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:g21285878naveen/features/home/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class FoodSearchPage extends StatefulWidget {
  const FoodSearchPage({super.key});

  @override
  _FoodSearchPageState createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends State<FoodSearchPage> {
  String _sugarContent = "Enter a food name or scan/upload a barcode to fetch sugar content";
  String _foodName = "Unknown Product";
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  bool _isLoading = false;
  String _activeTab = 'search';
  Uint8List? _uploadedImage;

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
          .collection('searched_foods')
          .doc(docId)
          .set({
        'foodQuery': key,
        'foodName': foodName,
        'sugarContent': sugarContent,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("Saved to Firestore (searched_foods): $docId - Sugar: $sugarContent");

      HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
      if (homepageState != null) {
        await homepageState.refreshSugarData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving to Firestore: $e")),
      );
    }
  }

  Future<void> _searchProduct() async {
    String foodQuery = _searchController.text.trim();
    if (foodQuery.isEmpty) {
      setState(() {
        _sugarContent = "Please enter a food name.";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _sugarContent = "Fetching data...";
    });

    try {
      final cachedData = await _getCachedFoodData(foodQuery);
      if (cachedData != null) {
        setState(() {
          _foodName = cachedData['foodName'] as String;
          final sugar = cachedData['sugarContent'] as double?;
          _sugarContent = sugar != null
              ? "Sugar content: $sugar g per 100g (cached)"
              : "Sugar data not available for $_foodName (cached)";
          _isLoading = false;
        });
        return;
      }

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          _sugarContent = "No network connection. Please try again.";
          _isLoading = false;
        });
        return;
      }

      String apiUrl =
          "https://world.openfoodfacts.org/cgi/search.pl?search_terms=${Uri.encodeComponent(foodQuery)}&fields=code,product_name,nutriments&json=1";
      var response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print("Search API Response: $data");
        if (data["products"] != null && data["products"].isNotEmpty) {
          _foodName = data["products"][0]["product_name"] ?? "Unknown Product";
          double? sugar = data["products"][0]["nutriments"]?["sugars_100g"]?.toDouble();

          setState(() {
            _sugarContent = sugar != null
                ? "Sugar content: $sugar g per 100g"
                : "Sugar data not available for $_foodName";
          });

          await _saveToSharedPreferences(foodQuery, _foodName, sugar);
          await _saveToFirestore(foodQuery, _foodName, sugar);
        } else {
          setState(() {
            _sugarContent = "No products found for '$foodQuery'.";
          });
        }
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
  }

  Future<void> _fetchBarcode(String barcode) async {
    if (barcode.isEmpty) {
      setState(() {
        _sugarContent = "Please enter a barcode.";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _sugarContent = "Fetching barcode data...";
    });

    try {
      final cachedData = await _getCachedFoodData(barcode);
      if (cachedData != null) {
        setState(() {
          _foodName = cachedData['foodName'] as String;
          final sugar = cachedData['sugarContent'] as double?;
          _sugarContent = sugar != null
              ? "Sugar content: $sugar g per 100g (cached)"
              : "Sugar data not available for $_foodName (cached)";
          _isLoading = false;
        });
        return;
      }

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          _sugarContent = "No network connection. Please try again.";
          _isLoading = false;
        });
        return;
      }

      String apiUrl = "https://world.openfoodfacts.org/api/v0/product/$barcode.json";
      var response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print("Barcode API Response: $data");
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

  Future<void> _scanBarcode() async {
    if (kIsWeb) return;

    setState(() {
      _isLoading = true;
      _sugarContent = "Scanning barcode...";
    });

    try {
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        await _fetchBarcode(result.rawContent);
      } else {
        setState(() {
          _sugarContent = "No barcode detected. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _sugarContent = "Error scanning barcode: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadImage() async {
    setState(() {
      _isLoading = true;
      _sugarContent = "Uploading image...";
      _uploadedImage = null;
      _barcodeController.clear();
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _uploadedImage = result.files.single.bytes!;
          _sugarContent = "Image uploaded. Enter the barcode below.";
        });
      } else {
        setState(() {
          _sugarContent = "No image selected.";
        });
      }
    } catch (e) {
      setState(() {
        _sugarContent = "Error uploading image: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: "Enter Food Name",
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
          onSubmitted: (_) => _searchProduct(),
        ),
        const SizedBox(height: 30),
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
          onPressed: _searchProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
          child: const Text("Fetch Sugar Content", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildScanTab() {
    if (kIsWeb) {
      return Column(
        children: [
          const Text(
            'Upload an image of a barcode and enter the barcode number.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 30),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
            onPressed: _uploadImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text("Upload Image", style: TextStyle(color: Colors.white)),
          ),
          if (_uploadedImage != null) ...[
            const SizedBox(height: 30),
            TextField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: "Enter Barcode from Image",
                prefixIcon: Icon(Icons.qr_code),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (value) => _fetchBarcode(value),
            ),
          ],
        ],
      );
    } else {
      return Column(
        children: [
          const Text(
            'Press the button below to scan a barcode.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 30),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
            onPressed: _scanBarcode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text("Scan Barcode", style: TextStyle(color: Colors.white)),
          ),
        ],
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _activeTab = 'search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _activeTab == 'search' ? Colors.blueAccent : Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Search', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _activeTab = 'scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _activeTab == 'scan' ? Colors.blueAccent : Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Scan', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _activeTab == 'search' ? _buildSearchTab() : _buildScanTab(),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
                homepageState?.setState(() => homepageState.myIndex = 0);
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
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }
}