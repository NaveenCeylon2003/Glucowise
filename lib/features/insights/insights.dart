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
  double sugarLimit = 0.0;

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
        // Fetch sugar limit from user document
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        sugarLimit = (userDoc['sugarLimit'] as num?)?.toDouble() ??
            (userDoc['recommendedSugarIntake'] as num?)?.toDouble() ??
            0.0;

        QuerySnapshot summarySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('daily_summaries')
            .orderBy('timestamp', descending: true)
            .limit(7)
            .get();

        QuerySnapshot searchedSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('searched_foods')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();

        QuerySnapshot scannedSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scanned_foods')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();

        setState(() {
          dailySummaries = summarySnapshot.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            double totalSugar = (data['totalSugar'] as num?)?.toDouble() ?? 0.0;
            double limit = (data['limit'] as num?)?.toDouble() ??
                sugarLimit; // Use stored limit or user limit
            return {
              'date': data['date'] as String,
              'totalSugar': totalSugar,
              'limit': limit,
              'excessOrDeficit': totalSugar - limit, // Calculate dynamically
            };
          }).toList();

          dailySearchedFoods = _groupByDay(searchedSnapshot.docs);
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

  Map<String, List<Map<String, dynamic>>> _groupByDay(
      List<QueryDocumentSnapshot> docs) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    DateTime now = DateTime.now();
    DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      Timestamp? timestamp = data['timestamp'] as Timestamp?;
      if (timestamp == null) continue;

      DateTime dateTime = timestamp.toDate();
      if (dateTime.isBefore(sevenDaysAgo)) continue;

      String date = dateTime.toString().split(' ')[0];
      data['sugarConsumed'] =
          (data['sugarConsumed'] as num?)?.toDouble() ?? 0.0;

      grouped[date] = grouped[date] ?? [];
      grouped[date]!.add(data);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Insights',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.purple,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Refresh Data',
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Weekly Sugar Intake',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 250,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: dailySummaries.isNotEmpty
                                          ? (dailySummaries
                                                      .map((e) =>
                                                          e['totalSugar']
                                                              as double)
                                                      .reduce((a, b) =>
                                                          a > b ? a : b) *
                                                  1.2)
                                              .clamp(10.0, double.infinity)
                                          : 100.0,
                                      barGroups: dailySummaries.reversed
                                          .map((summary) {
                                        int index = dailySummaries.length -
                                            dailySummaries.indexOf(summary) -
                                            1;
                                        double sugar =
                                            summary['totalSugar'] as double;
                                        double limit =
                                            summary['limit'] as double;
                                        return BarChartGroupData(
                                          x: index,
                                          barRods: [
                                            BarChartRodData(
                                              toY: sugar,
                                              gradient: LinearGradient(
                                                colors: sugar > limit
                                                    ? [
                                                        Colors.redAccent,
                                                        Colors.red
                                                      ]
                                                    : [
                                                        Colors.purple,
                                                        Colors.purpleAccent
                                                      ],
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                              ),
                                              width: 18,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ],
                                          showingTooltipIndicators: [0],
                                        );
                                      }).toList(),
                                      titlesData: FlTitlesData(
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              int index = value.toInt();
                                              if (index >= 0 &&
                                                  index <
                                                      dailySummaries.length) {
                                                String date = dailySummaries[
                                                        dailySummaries.length -
                                                            1 -
                                                            index]['date']
                                                    as String;
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8.0),
                                                  child: Text(
                                                    date.split('-').last,
                                                    style: const TextStyle(
                                                        fontSize: 12),
                                                  ),
                                                );
                                              }
                                              return const Text('');
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) =>
                                                Text(
                                              '${value.toInt()} g',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ),
                                        topTitles: const AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false)),
                                        rightTitles: const AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false)),
                                      ),
                                      gridData: FlGridData(
                                        drawHorizontalLine: true,
                                        horizontalInterval: 20,
                                      ),
                                      borderData: FlBorderData(show: false),
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        touchTooltipData: BarTouchTooltipData(
                                          getTooltipItem: (group, groupIndex,
                                              rod, rodIndex) {
                                            int dayIndex =
                                                dailySummaries.length -
                                                    1 -
                                                    group.x;
                                            return BarTooltipItem(
                                              '${dailySummaries[dayIndex]['date']}\n${rod.toY.toStringAsFixed(1)} g',
                                              const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Daily Summary (Last 7 Days)',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple),
                                ),
                                const SizedBox(height: 10),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.purple.withOpacity(0.1),
                                          Colors.deepPurple.withOpacity(0.1)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    columns: const [
                                      DataColumn(
                                          label: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text('Date',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.purple)))),
                                      DataColumn(
                                          label: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text('Intake (g)',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.purple)))),
                                      DataColumn(
                                          label: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text('Excess/Deficit',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.purple)))),
                                    ],
                                    rows: dailySummaries.map((summary) {
                                      return DataRow(cells: [
                                        DataCell(
                                            Text(summary['date'] as String)),
                                        DataCell(Text(
                                            (summary['totalSugar'] as double)
                                                .toStringAsFixed(1))),
                                        DataCell(Text(
                                          (summary['excessOrDeficit'] as double)
                                              .toStringAsFixed(1),
                                          style: TextStyle(
                                            color: (summary['excessOrDeficit']
                                                        as double) >
                                                    0
                                                ? Colors.redAccent
                                                : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildHistorySection('Searched Foods (Last 7 Days)',
                            dailySearchedFoods, Icons.search),
                        const SizedBox(height: 20),
                        _buildHistorySection('Scanned Barcodes (Last 7 Days)',
                            dailyScannedBarcodes, Icons.qr_code),
                      ],
                    ),
                  ),
                ),
              ));
  }

  Widget _buildHistorySection(String title,
      Map<String, List<Map<String, dynamic>>> dailyItems, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(
          title,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
        ),
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: dailyItems.isEmpty
                ? const Text("No items recorded in the last 7 days.",
                    style: TextStyle(color: Colors.grey))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dailyItems.entries.map((entry) {
                      String date = entry.key;
                      List<Map<String, dynamic>> items = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            date,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          ...items.map((item) {
                            String name =
                                item['foodName'] as String? ?? 'Unknown Item';
                            double sugar = item['sugarConsumed'] as double;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${sugar.toStringAsFixed(1)} g",
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.purple,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
