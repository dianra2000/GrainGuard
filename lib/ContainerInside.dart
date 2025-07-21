import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart'; // Import for LoginScreen

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
  final User? _user = FirebaseAuth.instance.currentUser;
  double _currentWeight = 0.0;
  List<WeightData> _weightHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _listenToWeightData();
    } else {
      setState(() {
        _isLoading = false;
      });
      // If user is null, navigate back to login screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
    }
  }

  void _listenToWeightData() {
    // Listen for currentWeight changes
    _databaseRef
        .child('users')
        .child(_user!.uid)
        .child('containers')
        .child(widget.containerId)
        .child('currentWeight')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        setState(() {
          _currentWeight = (data as num).toDouble();
        });
      }
    });

    // Listen for weightHistory changes
    _databaseRef
        .child('users')
        .child(_user!.uid)
        .child('containers')
        .child(widget.containerId)
        .child('weightHistory')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      List<WeightData> loadedHistory = [];
      
      if (data != null && data is Map) {
        data.forEach((key, value) {
          try {
            List<String> dateParts = key.split('_')[0].split('-');
            List<String> timeParts = key.split('_')[1].split('-');

            DateTime timestamp = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]), 
              int.parse(dateParts[2]),
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
              int.parse(timeParts[2]),
            );
            loadedHistory.add(WeightData(timestamp, (value as num).toDouble()));
          } catch (e) {
            print('Error parsing timestamp $key: $e');
          }
        });

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

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GRAINGUARD',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color.fromARGB(255, 106, 50, 155), // Match home screen AppBar color
        automaticallyImplyLeading: false, // Remove default back button
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container( // Apply gradient to the body
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 179, 138, 216), // Lighter purple at the top
              Colors.white, // White at the bottom
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Padding(
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
                widget.containerId,
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
                    '${_currentWeight.toStringAsFixed(2)} kg',
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
                'Product Trends by Time',
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
                            padding: const EdgeInsets.all(8.0),
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
                                          value.toStringAsFixed(1),
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
      ),
      bottomNavigationBar: BottomNavigation(
        onHomePressed: () {
          // Navigate back to HomeScreen
          Navigator.pop(context);
        },
        onAddPressed: () {
          // Navigate back to HomeScreen to add a new container
          Navigator.pop(context);
          // You might want to add a mechanism to automatically open the add dialog on HomeScreen
          // For now, it just goes back to the home screen.
        },
        onHistoryPressed: () {
          // Already on a container's history screen, so do nothing or refresh
          // For now, it does nothing.
        },
      ),
    );
  }
}

// Re-defining BottomNavigation here for self-containment as requested
// In a real app, this would typically be in a shared widget file.
class BottomNavigation extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onAddPressed;
  final VoidCallback onHistoryPressed;

  const BottomNavigation({
    super.key,
    required this.onHomePressed,
    required this.onAddPressed,
    required this.onHistoryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            onPressed: onHomePressed,
            color: Colors.grey, // Not active on this screen
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 30), // Plus icon
            onPressed: onAddPressed,
            color: Colors.grey,
          ),
          IconButton(
            icon: const Icon(Icons.history, size: 30), // History icon
            onPressed: onHistoryPressed,
            color: Colors.blue, // Active color for history as this screen shows history
          ),
        ],
      ),
    );
  }
}
