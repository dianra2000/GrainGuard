// ContainerInside.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Realtime Database
import 'package:fl_chart/fl_chart.dart'; // Import FL Chart

// Data model for the chart
class WeightData {
  final DateTime time;
  final double weight;

  WeightData(this.time, this.weight);
}

class ContainerInside extends StatefulWidget {
  final String containerId;

  const ContainerInside({super.key, required this.containerId});

  @override
  State<ContainerInside> createState() => _ContainerInsideState();
}

class _ContainerInsideState extends State<ContainerInside> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  double _currentWeight = 0.0;
  List<WeightData> _weightHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenToWeightData();
  }

  void _listenToWeightData() {
    // Listen for currentWeight changes
    _databaseRef.child('currentWeight').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        setState(() {
          _currentWeight = (data as num).toDouble();
        });
      }
    });

    // Listen for weightHistory changes
    _databaseRef.child('weightHistory').onValue.listen((event) {
      final data = event.snapshot.value;
      List<WeightData> loadedHistory = [];
      if (data != null && data is Map) {
        data.forEach((key, value) {
          // 'key' is the timestamp string (e.g., "2025-07-06_14-39-16")
          // 'value' is the weight (e.g., 0.04)

          // Parse the timestamp string into a DateTime object
          // Example format: YYYY-MM-DD_HH-MM-SS
          try {
            List<String> dateParts = key.split('_')[0].split('-');
            List<String> timeParts = key.split('_')[1].split('-');

            DateTime timestamp = DateTime(
              int.parse(dateParts[0]), // Year
              int.parse(dateParts[1]), // Month
              int.parse(dateParts[2]), // Day
              int.parse(timeParts[0]), // Hour
              int.parse(timeParts[1]), // Minute
              int.parse(timeParts[2]), // Second
            );
            loadedHistory.add(WeightData(timestamp, (value as num).toDouble()));
          } catch (e) {
            print('Error parsing timestamp $key: $e');
          }
        });

        // Sort the history by time
        loadedHistory.sort((a, b) => a.time.compareTo(b.time));
      }

      setState(() {
        _weightHistory = loadedHistory;
        _isLoading = false;
      });
    }, onError: (error) {
      print("Failed to load weight history: $error");
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GrainGuard'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Current Scale of',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Container ${widget.containerId}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${_currentWeight.toStringAsFixed(2)} kg', // Display current weight
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Product Trends by Time', // Changed from 'Month' to 'Time'
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _weightHistory.isEmpty
                      ? const Center(child: Text('No weight history available.'))
                      : Padding(
                          padding: const EdgeInsets.all(8.0), // Add padding for the chart
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: true),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      // Convert the double value back to DateTime
                                      // FL_Chart uses double for x-axis, so we convert DateTime to millisecondsSinceEpoch
                                      final dateTime = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        space: 8.0,
                                        child: Text(
                                          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toStringAsFixed(1), // Display weight with 1 decimal place
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    }
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: const Color(0xff37434d)),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _weightHistory.map((data) {
                                    // Convert DateTime to millisecondsSinceEpoch for FL Chart's x-axis
                                    return FlSpot(data.time.millisecondsSinceEpoch.toDouble(), data.weight);
                                  }).toList(),
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                              // Optional: Add touch input for tooltips
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                    return touchedSpots.map((LineBarSpot touchedSpot) {
                                      final dateTime = DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt());
                                      return LineTooltipItem(
                                        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}\n${touchedSpot.y.toStringAsFixed(2)} kg',
                                        const TextStyle(color: Colors.white),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
              color: Colors.grey,
            ),
            IconButton(
              icon: const Icon(Icons.person, size: 30),
              onPressed: () {},
              color: Colors.grey,
            ),
            IconButton(
              icon: const Icon(Icons.history, size: 30),
              onPressed: () {},
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
