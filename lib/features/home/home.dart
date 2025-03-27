import 'package:flutter/material.dart';
import 'dart:async';
import 'package:g21285878naveen/features/insights/insights.dart';
import 'package:g21285878naveen/features/profile/profile.dart';
import 'package:g21285878naveen/features/profile/update_account.dart';
import 'package:g21285878naveen/features/profile/change_email.dart';
import 'package:g21285878naveen/features/profile/logout.dart';
import 'package:g21285878naveen/features/profile/sugar_limit.dart';
import 'package:g21285878naveen/features/scan/scan.dart';
import 'package:g21285878naveen/features/scan/options.dart';
import 'package:g21285878naveen/features/scan/barcode_entry.dart';
import 'package:g21285878naveen/features/scan/food_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Homeroutes extends StatelessWidget {
  const Homeroutes({super.key});

  @override
  Widget build(BuildContext context) {
    return const Homescreen();
  }
}

class Homescreen extends StatelessWidget {
  const Homescreen({super.key});

  @override
  Widget build(BuildContext context) {
    HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
    double totalSugar = homepageState?.totalScannedSugar ?? 0.0;
    double dailyLimit = homepageState?.dailySugarLimit ?? 0.0;
    double remainingSugar = dailyLimit - totalSugar;
    double progress = dailyLimit > 0 ? totalSugar / dailyLimit : 0.0;
    if (progress > 1.0) progress = 1.0;
    if (progress < 0.0) progress = 0.0;

    print("Homescreen build - Daily Limit: $dailyLimit, Total Sugar: $totalSugar, Remaining: $remainingSugar, Progress: $progress");

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              homepageState?.setState(() {
                homepageState.myIndex = 3; // Navigate to Scanoptions
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text("Lets Scan", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 20),
          Text(
            dailyLimit == 0.0 && totalSugar == 0.0
                ? "Set a sugar limit to track your intake"
                : "Daily Sugar Allowance: ${remainingSugar >= 0 ? remainingSugar.toStringAsFixed(1) : 0.0} g / ${dailyLimit.toStringAsFixed(1)} g",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 250,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => HomepageState();
}

class HomepageState extends State<Homepage> {
  int myIndex = 0;
  double dailySugarLimit = 0.0; // Non-null default
  double totalScannedSugar = 0.0; // Non-null default
  StreamSubscription<DocumentSnapshot>? _summarySubscription;

  List<Widget> widgetList = [
    const Homeroutes(),              // 0: Home
    const Insights(),               // 1: Insights
    const ProfilePage(),            // 2: Profile
    const Scanoptions(),            // 3: Scan Options
    const ScanPage(),              // 4: Scan Page
    const BarcodeEntryPage(),      // 5: Barcode Entry
    const UpdateAccountScreen(),   // 6: Update Account
    const ChangeEmailScreen(),     // 7: Change Email
    const LogoutScreen(),          // 8: Logout
    const FoodSearchPage(),         // 9: Food Search Page
    const SugarLimitPage(),         // 10: Sugar Limit Page
  ];

  @override
  void initState() {
    super.initState();
    _loadCachedData(); // Load cached data immediately
    _listenToSugarData(); // Start real-time listener
  }

  @override
  void dispose() {
    _summarySubscription?.cancel(); // Clean up listener
    super.dispose();
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      dailySugarLimit = prefs.getDouble('dailySugarLimit') ?? 0.0;
      totalScannedSugar = prefs.getDouble('totalScannedSugar') ?? 0.0;
      print("Loaded from cache - Daily Limit: $dailySugarLimit, Total Sugar: $totalScannedSugar");
    });
  }

  Future<void> _saveCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('dailySugarLimit', dailySugarLimit);
    await prefs.setDouble('totalScannedSugar', totalScannedSugar);
    print("Saved to cache - Daily Limit: $dailySugarLimit, Total Sugar: $totalScannedSugar");
  }

  void _listenToSugarData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in, using defaults");
      setState(() {
        dailySugarLimit = 0.0;
        totalScannedSugar = 0.0;
      });
      _saveCachedData();
      return;
    }

    // Fetch sugar limit once (assuming it doesn't change often)
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get()
        .then((userDoc) {
      double limit = (userDoc['sugarLimit'] as num?)?.toDouble() ??
          (userDoc['recommendedSugarIntake'] as num?)?.toDouble() ??
          0.0;
      setState(() {
        dailySugarLimit = limit;
        print("Loaded sugar limit from Firestore: $dailySugarLimit");
      });
      _saveCachedData();
    }).catchError((e) {
      print("Error fetching sugar limit: $e");
    });

    // Real-time listener for daily_summaries
    String today = DateTime.now().toString().split(' ')[0];
    _summarySubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('daily_summaries')
        .doc(today)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        double total = (snapshot['totalSugar'] as num?)?.toDouble() ?? 0.0;
        setState(() {
          totalScannedSugar = total;
          print("Real-time update - Total Sugar: $totalScannedSugar");
        });
        _saveCachedData();
      } else {
        setState(() {
          totalScannedSugar = 0.0;
          print("No summary for $today, reset Total Sugar to 0");
        });
        _saveCachedData();
      }
    }, onError: (e) {
      print("Error in real-time listener: $e");
      // Keep cached value if listener fails
    });
  }

  Future<void> refreshSugarData() async {
    // No need for manual refresh with real-time listener, but keep for compatibility
    _listenToSugarData();
  }

  Future<void> _saveDailySummary() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && dailySugarLimit != null) {
      String date = DateTime.now().toString().split(' ')[0];
      double excessOrDeficit = totalScannedSugar - dailySugarLimit;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('daily_summaries')
          .doc(date)
          .set({
        'date': date,
        'totalSugar': totalScannedSugar,
        'limit': dailySugarLimit,
        'excessOrDeficit': excessOrDeficit,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: myIndex, children: widgetList),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.purple,
        currentIndex: myIndex > 2 ? 0 : myIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_chart), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          setState(() {
            myIndex = index;
            if (index == 0 || index == 2) {
              _listenToSugarData(); // Re-establish listener if needed
            }
          });
        },
      ),
    );
  }
}