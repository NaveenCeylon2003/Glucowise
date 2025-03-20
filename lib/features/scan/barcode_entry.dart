import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manual Barcode Entry")),
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
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
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

                          // Check connectivity
                          var connectivityResult =
                              await Connectivity().checkConnectivity();
                          if (connectivityResult == ConnectivityResult.none) {
                            setState(() {
                              _sugarContent =
                                  "No network connection. Please try again.";
                              _isLoading = false;
                            });
                            return;
                          }

                          // Fetch data from OpenFoodFacts API
                          String apiUrl =
                              "https://world.openfoodfacts.org/api/v2/product/$barcode.json";
                          var response = await http.get(Uri.parse(apiUrl));

                          if (response.statusCode == 200) {
                            var data = jsonDecode(response.body);

                            if (data["status"] == 1) {
                              _foodName = data["product"]["product_name"] ??
                                  "Unknown Product";
                              double? sugar =
                                  data["product"]["nutriments"]["sugars_100g"];

                              setState(() {
                                if (sugar != null) {
                                  _sugarContent =
                                      "Sugar content: $sugar g per 100g";
                                } else {
                                  _sugarContent =
                                      "Sugar data not available for $_foodName";
                                }
                              });

                              if (sugar != null) {
                                Navigator.pop(context, {
                                  'name': _foodName,
                                  'sugar': sugar,
                                });
                              }
                            } else {
                              setState(() {
                                _sugarContent =
                                    "Product not found in database.";
                              });
                            }
                          } else if (response.statusCode == 429) {
                            setState(() {
                              _sugarContent =
                                  "Rate limit exceeded. Please wait and try again.";
                            });
                          } else {
                            setState(() {
                              _sugarContent =
                                  "Error: Failed to fetch data (Status: ${response.statusCode})";
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                      ),
                      child: const Text(
                        "Fetch Sugar Content",
                        style: TextStyle(color: Colors.white),
                      ),
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
    super.dispose();
  }
}
