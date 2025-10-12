import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:g21285878naveen/features/home/home.dart';

class SugarLimitPage extends StatefulWidget {
  const SugarLimitPage({super.key});

  @override
  _SugarLimitPageState createState() => _SugarLimitPageState();
}

class _SugarLimitPageState extends State<SugarLimitPage> {
  final TextEditingController _sugarLimitController = TextEditingController();
  String _currentLimit = "Not set";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSugarLimit();
  }

  Future<void> _loadSugarLimit() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _currentLimit = "${(doc['sugarLimit'] as num?)?.toStringAsFixed(1) ?? (doc['recommendedSugarIntake'] as num?)?.toStringAsFixed(1) ?? 'Not set'} g";
          _sugarLimitController.text = (doc['sugarLimit'] as num?)?.toString() ?? (doc['recommendedSugarIntake'] as num?)?.toString() ?? '';
        });
      }
    }
  }

  Future<void> _saveSugarLimit() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to save your sugar limit.")),
      );
      return;
    }

    String sugarLimitText = _sugarLimitController.text.trim();
    if (sugarLimitText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a sugar limit.")),
      );
      return;
    }

    double? sugarLimit = double.tryParse(sugarLimitText);
    if (sugarLimit == null || sugarLimit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid positive number.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'sugarLimit': sugarLimit,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _currentLimit = "$sugarLimit g";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sugar limit saved successfully!")),
      );

      // Refresh Homepage state and data
      HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
      if (homepageState != null) {
        await homepageState.refreshSugarData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving sugar limit: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Set Daily Sugar Limit",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              "Current Daily Sugar Limit: $_currentLimit",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _sugarLimitController,
              decoration: const InputDecoration(
                labelText: "Set Daily Sugar Limit (g)",
                prefixIcon: Icon(Icons.cake),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _saveSugarLimit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text("Save Sugar Limit", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
                homepageState?.setState(() => homepageState.myIndex = 2); // Back to ProfilePage
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text("Back", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sugarLimitController.dispose();
    super.dispose();
  }
}
