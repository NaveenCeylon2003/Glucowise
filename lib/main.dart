import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:g21285878naveen/features/auth/getstarted.dart';
import 'package:g21285878naveen/features/auth/signupform.dart';
import 'package:g21285878naveen/features/auth/login.dart';
import 'package:g21285878naveen/features/auth/splash.dart';
import 'package:g21285878naveen/features/home/home.dart';
//import 'package:g21285878naveen/features/scan/scan.dart';
import 'package:g21285878naveen/features/scan/options.dart';
import 'package:g21285878naveen/features/auth/form1.dart';
import 'package:g21285878naveen/features/scan/scan.dart';

import 'package:http/http.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure Flutter binding is initialized
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDlz1L168Mdsw9qV8EMxetet9rkqLeGQ5c",
      authDomain: "glucowise-8079e.firebaseapp.com",
      projectId: "glucowise-8079e",
      storageBucket: "glucowise-8079e.appspot.com", // Corrected storageBucket
      messagingSenderId: "1072771865182",
      appId: "1:1072771865182:web:0e37dcb54597122523f2cf",
    ),
  );
  runApp(const Sugartracking());
}

class Sugartracking extends StatelessWidget {
  const Sugartracking({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(initialRoute: "splash", routes: {
      "splash": (Context) => SplashScreen(),
      "start": (context) => Start(),
      "signup": (context) => Signupscreen(),
      "login": (context) => Login(),
      "home": (context) => const Homepage(),
      "form": (context) => BMICalculatorApp(),
      "options": (context) => Scanoptions(),
      "scan": (context) => ScanPage()
    });
  }
}
