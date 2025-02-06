import 'package:flutter/material.dart';

class Insights extends StatelessWidget {
  const Insights({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            children: [
              Text(
                "Insights for scanning",
                style: TextStyle(color: Colors.blue),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
