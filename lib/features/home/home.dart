import 'package:flutter/material.dart';
import 'package:g21285878naveen/features/insights/insights.dart';
import 'package:g21285878naveen/features/profile/profile.dart';
import 'package:g21285878naveen/features/profile/update_account.dart';
import 'package:g21285878naveen/features/profile/change_email.dart';
import 'package:g21285878naveen/features/profile/logout.dart';
import 'package:g21285878naveen/features/profile/notification_settings.dart';
import 'package:g21285878naveen/features/scan/scan.dart';
import 'package:g21285878naveen/features/scan/options.dart';
import 'package:g21285878naveen/features/scan/barcode_entry.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    if (homepageState?.isLoading ?? true) {
      return const Center(child: CircularProgressIndicator());
    }

    double totalSugar = homepageState?.totalScannedSugar ?? 0.0;
    double dailyLimit = homepageState?.dailySugarLimit ?? 0.0;
    double remainingSugar = dailyLimit - totalSugar;
    double progress = dailyLimit > 0 ? totalSugar / dailyLimit : 0.0;
    if (progress > 1.0) progress = 1.0;
    if (progress < 0.0) progress = 0.0;

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
            "Daily Sugar Allowance: ${remainingSugar >= 0 ? remainingSugar.toStringAsFixed(1) : 0.0} g / ${dailyLimit.toStringAsFixed(1)} g",
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
  double? dailySugarLimit;
  double totalScannedSugar = 0.0;
  bool isLoading = true;

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
    const NotificationSettingsScreen(), // 9: Notification Settings
  ];

  @override
  void initState() {
    super.initState();
    _loadSugarData();
    _saveDailySummary();
  }

  Future<void> _loadSugarData() async {
    setState(() => isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          // Use sugarLimit if set, otherwise fall back to recommendedSugarIntake
          dailySugarLimit = (userDoc['sugarLimit'] as num?)?.toDouble() ??
              (userDoc['recommendedSugarIntake'] as num?)?.toDouble() ??
              0.0;
        });

        QuerySnapshot barcodeDocs = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scanned_barcodes')
            .get();

        double total = 0.0;
        for (var doc in barcodeDocs.docs) {
          final sugar = doc['sugarContent'];
          if (sugar != null && sugar is num) total += sugar.toDouble();
        }
        setState(() => totalScannedSugar = total);
      } catch (e) {
        print("Error fetching data: $e");
        setState(() {
          dailySugarLimit = 0.0;
          totalScannedSugar = 0.0;
        });
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> refreshSugarData() async {
    await _loadSugarData();
  }

  Future<void> _saveDailySummary() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && dailySugarLimit != null) {
      String date = DateTime.now().toString().split(' ')[0];
      double excessOrDeficit = totalScannedSugar - dailySugarLimit!;

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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(index: myIndex, children: widgetList),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.purple,
        currentIndex: myIndex > 2 ? 0 : myIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_chart), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          setState(() => myIndex = index);
          if (index == 0 || index == 2) {
            _loadSugarData();
            _saveDailySummary();
          }
        },
      ),
    );
  }
}