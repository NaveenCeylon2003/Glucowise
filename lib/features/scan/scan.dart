import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  String _sugarContent = "Press the button to scan a barcode";
  String _foodName = "Unknown Product";
  bool _isLoading = false;

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
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                          _sugarContent = "Scanning...";
                        });

                        try {
                          // Scan barcode
                          String barcode =
                              await FlutterBarcodeScanner.scanBarcode(
                            "#ff6666", // Overlay color
                            "Cancel", // Cancel button text
                            true, // Show flash icon
                            ScanMode.BARCODE,
                          );

                          if (barcode == "-1") {
                            // Scan cancelled
                            setState(() {
                              _sugarContent = "Scan cancelled.";
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
                          debugPrint("Error details: $e"); // Log for debugging
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
                        "Scan Barcode",
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
