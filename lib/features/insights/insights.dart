import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class Insights extends StatefulWidget {
  const Insights({super.key});

  @override
  State<Insights> createState() => _InsightsState();
}

class _InsightsState extends State<Insights> {
  List<Map<String, dynamic>> dailySummaries = [];
  Map<String, List<Map<String, dynamic>>> dailySearchedFoods = {};
  Map<String, List<Map<String, dynamic>>> dailyScannedBarcodes = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Load daily summaries (last 7 days)
        QuerySnapshot summarySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('daily_summaries')
            .orderBy('timestamp', descending: true)
            .limit(7)
            .get();

        // Load searched foods (last 7 days)
        QuerySnapshot searchedSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('searched_foods')
            .orderBy('timestamp', descending: true)
            .limit(50) // Adjust limit as needed
            .get();

        // Load scanned barcodes (last 7 days)
        QuerySnapshot scannedSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scanned_barcodes')
            .orderBy('timestamp', descending: true)
            .limit(50) // Adjust limit as needed
            .get();

        setState(() {
          // Process daily summaries
          dailySummaries = summarySnapshot.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            data['totalSugar'] = (data['totalSugar'] as num?)?.toDouble() ?? 0.0;
            data['excessOrDeficit'] = (data['excessOrDeficit'] as num?)?.toDouble() ?? 0.0;
            data['limit'] = (data['limit'] as num?)?.toDouble() ?? 0.0;
            return data;
          }).toList();

          // Process searched foods by day
          dailySearchedFoods = _groupByDay(searchedSnapshot.docs);

          // Process scanned barcodes by day
          dailyScannedBarcodes = _groupByDay(scannedSnapshot.docs);

          isLoading = false;
        });
      } catch (e) {
        print("Error loading data: $e");
        setState(() {
          dailySummaries = [];
          dailySearchedFoods = {};
          dailyScannedBarcodes = {};
          isLoading = false;
        });
      }
    } else {
      setState(() {
        dailySummaries = [];
        dailySearchedFoods = {};
        dailyScannedBarcodes = {};
        isLoading = false;
      });
    }
  }

  // Helper to group items by day
  Map<String, List<Map<String, dynamic>>> _groupByDay(List<QueryDocumentSnapshot> docs) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    DateTime now = DateTime.now();
    DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      Timestamp? timestamp = data['timestamp'] as Timestamp?;
      if (timestamp == null) continue;

      DateTime dateTime = timestamp.toDate();
      if (dateTime.isBefore(sevenDaysAgo)) continue; // Skip if older than 7 days

      String date = dateTime.toString().split(' ')[0]; // YYYY-MM-DD
      data['sugarConsumed'] = (data['sugarConsumed'] as num?)?.toDouble() ?? 0.0;

      grouped[date] = grouped[date] ?? [];
      grouped[date]!.add(data);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weekly Sugar Intake',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: dailySummaries.isNotEmpty
                        ? dailySummaries
                        .map((e) => e['totalSugar'] as double)
                        .reduce((a, b) => a > b ? a : b) *
                        1.2
                        : 100.0,
                    barGroups: dailySummaries.reversed.map((summary) {
                      int index = dailySummaries.length - dailySummaries.indexOf(summary) - 1;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: summary['totalSugar'] as double,
                            color: Colors.purple,
                            width: 15,
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < dailySummaries.length) {
                              String date = dailySummaries[dailySummaries.length - 1 - index]['date'] as String;
                              return Text(date.split('-').last); // Day only
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Daily Summary Table',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Table(
                border: TableBorder.all(),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: Colors.grey),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Intake (g)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Excess/Deficit (g)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...dailySummaries.map(
                        (summary) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(summary['date'] as String),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text((summary['totalSugar'] as double).toStringAsFixed(1)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            (summary['excessOrDeficit'] as double).toStringAsFixed(1),
                            style: TextStyle(
                              color: (summary['excessOrDeficit'] as double) > 0 ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Searched Foods (Last 7 Days)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildFoodHistoryList(dailySearchedFoods),
              const SizedBox(height: 30),
              const Text(
                'Scanned Barcodes (Last 7 Days)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildFoodHistoryList(dailyScannedBarcodes),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to build history list for searched foods or scanned barcodes
  Widget _buildFoodHistoryList(Map<String, List<Map<String, dynamic>>> dailyItems) {
    if (dailyItems.isEmpty) {
      return const Text("No items recorded in the last 7 days.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: dailyItems.entries.map((entry) {
        String date = entry.key;
        List<Map<String, dynamic>> items = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              date,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            ...items.map((item) {
              String name = item['foodName'] as String? ?? item['productName'] as String? ?? 'Unknown Item';
              double sugar = item['sugarConsumed'] as double;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(name)),
                    Text("${sugar.toStringAsFixed(1)} g"),
                  ],
                ),
              );
            }),
            const SizedBox(height: 15),
          ],
        );
      }).toList(),
    );
  }
}