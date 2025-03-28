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
          _currentLimit =
              "${(doc['sugarLimit'] as num?)?.toStringAsFixed(1) ?? (doc['recommendedSugarIntake'] as num?)?.toStringAsFixed(1) ?? 'Not set'} g";
          _sugarLimitController.text =
              (doc['sugarLimit'] as num?)?.toString() ??
                  (doc['recommendedSugarIntake'] as num?)?.toString() ??
                  '';
        });
      }
    }
  }

  Future<void> _saveSugarLimit() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please log in to save your sugar limit.")),
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
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sugar limit saved successfully!")),
      );

      HomepageState? homepageState =
          context.findAncestorStateOfType<HomepageState>();
      if (homepageState != null) {
        await homepageState.refreshSugarData();
        homepageState.setState(() {}); // Force rebuild of Homepage
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving sugar limit: $e")),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Set Sugar Limit",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.8),
              Colors.deepPurple.withOpacity(0.8)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Set Daily Sugar Limit",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Customize your daily sugar goal",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      _buildResultCard(
                          "Current Limit", _currentLimit, Colors.purple),
                      const SizedBox(height: 20),
                      _buildTextField(
                        _sugarLimitController,
                        "Set Daily Sugar Limit (g)",
                        "e.g., 50",
                        Icons.cake,
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveSugarLimit,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.save, color: Colors.white),
                          label: Text(
                            _isLoading ? "Saving..." : "Save Sugar Limit",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HomepageState? homepageState = context
                                .findAncestorStateOfType<HomepageState>();
                            homepageState?.setState(() => homepageState
                                .myIndex = 2); // Back to ProfilePage
                          },
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          label: const Text(
                            "Back to Profile",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build text fields
  Widget _buildTextField(TextEditingController controller, String label,
      String hint, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.purple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.purpleAccent, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: TextInputType.number,
    );
  }

  // Helper method to build result cards
  Widget _buildResultCard(String label, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 5),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple)),
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
