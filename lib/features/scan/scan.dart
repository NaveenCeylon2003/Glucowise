import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  String sugarContent = "Press the button to fetch sugar content";

  fetchSugarContent() async {
    String barcode = "3017624010701";
    String apiUrl = "https://world.openfoodfacts.org/api/v2/product/$barcode.json";

    try {
      var response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        // Extracting sugar content
        double? sugar = data["product"]["nutriments"]["sugars_100g"];
        setState(() {
          if (sugar != null) {
            sugarContent = "Sugar content: $sugar g per 100g";
          } else {
            sugarContent = "Sugar data not available";
          }
        });
      } else {
        setState(() {
          sugarContent = "Error: Failed to fetch data.";
        });
      }
    } catch (e) {
      setState(() {
        sugarContent = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Page")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(sugarContent, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: fetchSugarContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text("Fetch Sugar Content", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
