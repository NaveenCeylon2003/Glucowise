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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to save food data.")),
      );
      return;
    }

    try {
      String docId = "${key.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}";
      String today = DateTime.now().toString().split(' ')[0];

      // Save individual search entry
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

      // Increment total sugar in daily_summaries
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

      // Listener in Homepage will handle excessOrDeficit
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving to Firestore: $e")),
      );
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
        // Fetch fresh data from API if network is available
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
        // Fallback to cached data only if no network is available
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
            _isLoading = false;
          });
          final sugarPer100g = cachedData['sugarPer100g'] as double?;
          final sugarConsumed = sugarPer100g != null ? (sugarPer100g / 100) * amountConsumed : null;
          await _saveToFirestore(foodQuery, _foodName, sugarPer100g, sugarConsumed, amountConsumed);
          return;
        } else {
          setState(() {
            _sugarContent = "No network connection and no cached data available.";
            _isLoading = false;
          });
          return;
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
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _searchProduct,
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
                onPressed: () async {
                  HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
                  if (homepageState != null) {
                    await homepageState.refreshSugarData(); // Refresh data before navigating
                    homepageState.setState(() => homepageState.myIndex = 0);
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