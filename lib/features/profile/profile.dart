import 'package:flutter/material.dart';
import 'package:g21285878naveen/features/scan/options.dart';

class Profileroutes extends StatelessWidget {
  const Profileroutes({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:Profilepage(),
      routes: {
        "profile": (context) => Profilepage(), // Use Homepage instead of Homescreen
        "options": (context) => Scanoptions(),

      },
    );
  }
}
class Profilepage extends StatelessWidget {
  const Profilepage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            children: [
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, "options");
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
                  "Update account",
                  style: TextStyle(color: Colors.white,)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
