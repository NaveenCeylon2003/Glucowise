import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:g21285878naveen/features/home/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FoodSearchPage extends StatefulWidget {
  const FoodSearchPage({super.key});

  @override
  _FoodSearchPageState createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends State<FoodSearchPage> {
  String _sugarContent = "Enter a food name to fetch sugar content";
  String _foodName = "Unknown Product";
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountConsumedController = TextEditingController();
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

  Future<void> _saveToSharedPreferences(String key, String foodName, double? sugarPer100g, double? sugarConsumed, double? amountConsumed) async {
    final prefs = await _getPrefs();
    final data = {
      'foodName': foodName,
      'sugarPer100g': sugarPer100g,
      'sugarConsumed': sugarConsumed,
      'amountConsumed': amountConsumed,
    };
    await prefs.setString(key.toLowerCase(), jsonEncode(data));
  }

  Future<void> _saveToFirestore(String key, String foodName, double? sugarPer100g, double? sugarConsumed, double? amountConsumed) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("Please log in to save food data.");
      return;
    }

    try {
      String docId = "${key.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}";
      String today = DateTime.now().toString().split(' ')[0];

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('searched_foods')
          .doc(docId)
          .set({
        'foodQuery': key,
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

  Future<void> _searchProduct() async {
    String foodQuery = _searchController.text.trim();
    String amountText = _amountConsumedController.text.trim();

    if (foodQuery.isEmpty) {
      setState(() {
        _sugarContent = "Please enter a food name.";
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
        String apiUrl =
            "https://world.openfoodfacts.org/cgi/search.pl?search_terms=${Uri.encodeComponent(foodQuery)}&fields=code,product_name,nutriments&json=1";
        var response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          if (data["products"] != null && data["products"].isNotEmpty) {
            _foodName = data["products"][0]["product_name"] ?? "Unknown Product";
            double? sugarPer100g = data["products"][0]["nutriments"]?["sugars_100g"]?.toDouble();

            double? sugarConsumed;
            if (sugarPer100g != null) {
              sugarConsumed = (sugarPer100g / 100) * amountConsumed;
            }

            setState(() {
              _sugarContent = sugarConsumed != null
                  ? "Sugar consumed: ${sugarConsumed.toStringAsFixed(1)} g\n(Sugar per 100g: $sugarPer100g g)"
                  : "Sugar data not available for $_foodName";
            });

            await _saveToSharedPreferences(foodQuery, _foodName, sugarPer100g, sugarConsumed, amountConsumed);
            await _saveToFirestore(foodQuery, _foodName, sugarPer100g, sugarConsumed, amountConsumed);
            _showSnackBar("Food data saved successfully!", Colors.green);
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
      } else {
        final cachedData = await _getCachedFoodData(foodQuery);
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
          });
          final sugarPer100g = cachedData['sugarPer100g'] as double?;
          final sugarConsumed = sugarPer100g != null ? (sugarPer100g / 100) * amountConsumed : null;
          await _saveToFirestore(foodQuery, _foodName, sugarPer100g, sugarConsumed, amountConsumed);
          _showSnackBar("Loaded cached data.", Colors.green);
        } else {
          setState(() {
            _sugarContent = "No network connection and no cached data available.";
          });
        }
      }
    } catch (e) {
      setState(() {
        _sugarContent = "Error: $e";
      });
      _showSnackBar("Error fetching data: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
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
          "Food Sugar Search",
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
                        "Search Food",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Find sugar content in your food",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      if (_foodName != "Unknown Product")
                        _buildResultCard("Product", _foodName, Colors.purple),
                      const SizedBox(height: 10),
                      _buildResultCard("Sugar Info", _sugarContent, Colors.deepPurple),
                      const SizedBox(height: 20),
                      _buildTextField(_searchController, "Enter Food Name", "e.g., Apple", Icons.search),
                      const SizedBox(height: 16),
                      _buildTextField(_amountConsumedController, "Amount Consumed (g)", "e.g., 100", Icons.fastfood),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _searchProduct,
                          icon: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : const Icon(Icons.search, color: Colors.white),
                          label: Text(
                            _isLoading ? "Searching..." : "Calculate Sugar Content",
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
                          onPressed: () async {
                            HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
                            if (homepageState != null) {
                              await homepageState.refreshSugarData();
                              homepageState.setState(() => homepageState.myIndex = 0);
                            }
                          },
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          label: const Text(
                            "Back to Home",
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

  // Helper method to build text fields
  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon) {
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
      keyboardType: label.contains("Amount") ? TextInputType.number : TextInputType.text,
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

  @override
  void dispose() {
    _searchController.dispose();
    _amountConsumedController.dispose();
    super.dispose();
  }
}