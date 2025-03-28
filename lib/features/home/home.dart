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

  Future<String> _getUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return doc['username'] as String? ?? user.displayName ?? 'User';
    }
    return 'User';
  }

  String _getMotivationalMessage(double progress) {
    if (progress < 0.3) {
      return "Great start! Keep it up!";
    } else if (progress < 0.7) {
      return "You're doing well—stay mindful!";
    } else if (progress < 1.0) {
      return "Almost there—watch your intake!";
    } else {
      return "Over the limit—let’s reset tomorrow!";
    }
  }

  @override
  Widget build(BuildContext context) {
    HomepageState? homepageState =
    context.findAncestorStateOfType<HomepageState>();
    double totalSugar = homepageState?.totalScannedSugar ?? 0.0;
    double dailyLimit = homepageState?.dailySugarLimit ?? 0.0;
    double remainingSugar = dailyLimit - totalSugar;
    double progress = dailyLimit > 0 ? totalSugar / dailyLimit : 0.0;
    if (progress > 1.0) progress = 1.0;
    if (progress < 0.0) progress = 0.0;

    print(
        "Homescreen build - Daily Limit: $dailyLimit, Total Sugar: $totalSugar, Remaining: $remainingSugar, Progress: $progress");

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Greeting with Username
            FutureBuilder<String>(
              future: _getUsername(),
              builder: (context, snapshot) {
                return Text(
                  "Hello, ${snapshot.data ?? 'User'}!",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              "Track your sugar intake today",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),

            // Circular Progress Indicator
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: CircularProgressIndicator(
                    value: dailyLimit == 0.0 ? 0.0 : progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      dailyLimit == 0.0
                          ? Colors.grey
                          : progress < 0.7
                          ? Colors.green
                          : progress < 1.0
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dailyLimit == 0.0
                          ? "Set Limit"
                          : "${remainingSugar >= 0 ? remainingSugar.toStringAsFixed(1) : 0.0} g",
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      dailyLimit == 0.0 ? "to Start" : "Remaining",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Motivational Message
            Text(
              dailyLimit == 0.0
                  ? "Set a sugar limit to begin!"
                  : _getMotivationalMessage(progress),
              style: const TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.purple),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Quick Stats Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                    "Today's Intake",
                    "${totalSugar.toStringAsFixed(1)} g",
                    Icons.fastfood,
                    Colors.purpleAccent),
                _buildStatCard(
                    "Daily Limit",
                    "${dailyLimit.toStringAsFixed(1)} g",
                    Icons.speed,
                    Colors.purple),
              ],
            ),
            const SizedBox(height: 30),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: () {
                homepageState?.setState(() {
                  homepageState.myIndex = 3; // Navigate to Scanoptions
                });
              },
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label:
              const Text("Scan Now", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                elevation: 5,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () {
                    homepageState
                        ?.setState(() => homepageState.myIndex = 1); // Insights
                  },
                  icon: const Icon(Icons.insights, color: Colors.purple),
                  label: const Text("View Insights",
                      style: TextStyle(color: Colors.purple)),
                ),
                const SizedBox(width: 20),
                TextButton.icon(
                  onPressed: () {
                    homepageState?.setState(
                            () => homepageState.myIndex = 10); // Sugar Limit
                  },
                  icon: const Icon(Icons.settings, color: Colors.purple),
                  label: const Text("Set Limit",
                      style: TextStyle(color: Colors.purple)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build stat cards
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            const SizedBox(height: 5),
            Text(value,
                style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
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
  double dailySugarLimit = 0.0;
  double totalScannedSugar = 0.0;
  StreamSubscription<DocumentSnapshot>? _summarySubscription;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
  bool _isLoading = true;

  List<Widget> widgetList = [
    const Homeroutes(), // 0: Home
    const Insights(), // 1: Insights
    const ProfilePage(), // 2: Profile
    const Scanoptions(), // 3: Scan Options
    const ScanPage(), // 4: Scan Page
    const BarcodeEntryPage(), // 5: Barcode Entry
    const UpdateAccountScreen(), // 6: Update Account
    const ChangeEmailScreen(), // 7: Change Email
    const LogoutScreen(), // 8: Logout
    const FoodSearchPage(), // 9: Food Search Page
    const SugarLimitPage(), // 10: Sugar Limit Page
  ];

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    await _listenToSugarData();
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _summarySubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      dailySugarLimit = prefs.getDouble('dailySugarLimit') ?? 0.0;
      totalScannedSugar = prefs.getDouble('totalScannedSugar') ?? 0.0;
      print(
          "Loaded from cache - Daily Limit: $dailySugarLimit, Total Sugar: $totalScannedSugar");
    });
  }

  Future<void> _saveCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('dailySugarLimit', dailySugarLimit);
    await prefs.setDouble('totalScannedSugar', totalScannedSugar);
    print(
        "Saved to cache - Daily Limit: $dailySugarLimit, Total Sugar: $totalScannedSugar");
  }

  Future<void> _listenToSugarData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in, redirecting to login");
      setState(() {
        dailySugarLimit = 0.0;
        totalScannedSugar = 0.0;
      });
      await _saveCachedData();
      Navigator.pushReplacementNamed(context, "login");
      return;
    }

    // Listener for user document (sugarLimit)
    _userDocSubscription?.cancel();
    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((userDoc) {
      if (userDoc.exists) {
        double limit = (userDoc['sugarLimit'] as num?)?.toDouble() ??
            (userDoc['recommendedSugarIntake'] as num?)?.toDouble() ??
            0.0;
        setState(() {
          dailySugarLimit = limit;
          print("Real-time update - Sugar Limit: $dailySugarLimit");
        });
        _saveCachedData();
      } else {
        setState(() {
          dailySugarLimit = 50.0;
          print("No user document found, setting default sugar limit: $dailySugarLimit");
        });
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'sugarLimit': dailySugarLimit,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        _saveCachedData();
      }
    }, onError: (e) {
      print("Error fetching sugar limit: $e");
      setState(() {
        dailySugarLimit = 50.0;
      });
      _saveCachedData();
    });

    // Listener for daily summaries (totalScannedSugar)
    String today = DateTime.now().toString().split(' ')[0];
    _summarySubscription?.cancel();
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
      setState(() {
        totalScannedSugar = 0.0;
      });
      _saveCachedData();
    });
  }

  Future<void> refreshSugarData() async {
    await _listenToSugarData();
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(index: myIndex, children: widgetList),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.purple,
        currentIndex: myIndex > 2 ? 0 : myIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_chart), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          setState(() {
            myIndex = index;
            if (index == 0 || index == 2) {
              _listenToSugarData();
            }
          });
        },
      ),
    );
  }
}