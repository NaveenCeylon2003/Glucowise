import 'package:flutter/material.dart';
import 'package:g21285878naveen/features/home/home.dart';
import 'package:g21285878naveen/features/insights/insights.dart';
import 'package:g21285878naveen/features/profile/profile.dart';
import 'package:http/http.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            children: [
              Text("Lets get to scanning"),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  ScanPage();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),
                child: Text(
                  "Lets Scan",
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
