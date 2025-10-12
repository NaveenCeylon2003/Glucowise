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

  Future<void> _saveToSharedPreferences(String key, String foodName, double? sugarContent) async {
    final prefs = await _getPrefs();
    final data = {
      'foodName': foodName,
      'sugarContent': sugarContent,
    };
    await prefs.setString(key.toLowerCase(), jsonEncode(data));
  }

  Future<void> _saveToFirestore(String key, String foodName, double? sugarContent, double? sugarConsumed, double? amountConsumed) async {
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
        'sugarConsumed': sugarConsumed,
        'amountConsumed': amountConsumed,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("Saved to Firestore (searched_foods): $docId - Sugar: $sugarContent");

      // Update Homepage state and refresh data
      HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
      if (homepageState != null) {
        await homepageState.refreshSugarData(); // Refresh data immediately
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
        if (data["products"] != null && data["products"].isNotEmpty) {
          _foodName = data["products"][0]["product_name"] ?? "Unknown Product";
          double? sugar = data["products"][0]["nutriments"]?["sugars_100g"]?.toDouble();

          setState(() {
            _sugarContent = sugar != null
                ? "Sugar content: $sugar g per 100g"
                : "Sugar data not available for $_foodName";
          });

          await _saveToSharedPreferences(foodQuery, _foodName, sugar);
          await _saveToFirestore(foodQuery, _foodName, sugar, null, null);
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
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: "Enter Food Name",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
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
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                    _sugarContent = "Calculating sugar consumed...";
                  });

                  try {
                    String foodQuery = _searchController.text.trim();
                    String amountText = _amountConsumedController.text.trim();

                    if (foodQuery.isEmpty || amountText.isEmpty) {
                      setState(() {
                        _sugarContent = "Please enter both food name and amount consumed.";
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

                    final cachedData = await _getCachedFoodData(foodQuery);
                    if (cachedData != null) {
                      setState(() {
                        _foodName = cachedData['foodName'] as String;
                        final sugarPer100g = cachedData['sugarContent'] as double?;
                        if (sugarPer100g != null) {
                          final sugarConsumed = (sugarPer100g / 100) * amountConsumed;
                          _sugarContent = "Sugar consumed: ${sugarConsumed.toStringAsFixed(1)} g (cached)\n(Sugar per 100g: $sugarPer100g g)";
                        } else {
                          _sugarContent = "Sugar data not available for $_foodName (cached)";
                        }
                        _isLoading = false;
                      });
                      final sugarPer100g = cachedData['sugarContent'] as double?;
                      final sugarConsumed = sugarPer100g != null ? (sugarPer100g / 100) * amountConsumed : null;
                      await _saveToFirestore(foodQuery, _foodName, sugarPer100g, sugarConsumed, amountConsumed);
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
                      if (data["products"] != null && data["products"].isNotEmpty) {
                        _foodName = data["products"][0]["product_name"] ?? "Unknown Product";
                        double? sugarPer100g = data["products"][0]["nutriments"]?["sugars_100g"]?.toDouble();

                        setState(() {
                          if (sugarPer100g != null) {
                            final sugarConsumed = (sugarPer100g / 100) * amountConsumed;
                            _sugarContent = "Sugar consumed: ${sugarConsumed.toStringAsFixed(1)} g\n(Sugar per 100g: $sugarPer100g g)";
                          } else {
                            _sugarContent = "Sugar data not available for $_foodName";
                          }
                        });

                        double? sugarConsumed = sugarPer100g != null ? (sugarPer100g / 100) * amountConsumed : null;
                        await _saveToSharedPreferences(foodQuery, _foodName, sugarPer100g);
                        await _saveToFirestore(foodQuery, _foodName, sugarPer100g, sugarConsumed, amountConsumed);
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
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  "Calculate Sugar Consumed",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
                  if (homepageState != null) {
                    homepageState.setState(() {
                      homepageState.myIndex = 0; // Switch to Homescreen
                    });
                    homepageState.refreshSugarData(); // Refresh data when switching
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
    _searchController.dispose();
    _amountConsumedController.dispose();
    super.dispose();
  }
}
