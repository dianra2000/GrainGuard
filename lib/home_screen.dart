import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'ContainerInside.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> containers = [];
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late String _userId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      _loadContainers();
    } else {
      // If user is null, navigate back to login screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
    }
  }

  Future<void> _loadContainers() async {
    if (_userId.isEmpty) return;

    _database.child('users').child(_userId).child('containers').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final List<String> loadedContainers = [];
        data.forEach((key, value) {
          if (key is String) {
            loadedContainers.add(key);
          }
        });
        setState(() {
          containers = loadedContainers;
        });
      } else {
        setState(() {
          containers = [];
        });
      }
    });
  }

  Future<void> _addContainerToFirebase(String containerName) async {
    if (_userId.isEmpty) return;

    await _database.child('users').child(_userId).child('containers').child(containerName).set({
      'currentWeight': 0.0,
      'weightHistory': {},
    });
  }

  void _addNewContainer() async {
    final newContainerName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String containerName = '';
        return AlertDialog(
          title: const Text('Add New Container'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Enter Container Name',
              hintText: 'e.g., rice, sugar, flour',
            ),
            onChanged: (value) {
              containerName = value.trim();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, containerName),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (newContainerName != null && newContainerName.isNotEmpty) {
      if (!containers.contains(newContainerName)) {
        await _addContainerToFirebase(newContainerName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Container with this name already exists: $newContainerName')),
        );
      }
    }
  }

  Future<void> _removeContainer(String containerName) async {
    await _database.child('users').child(_userId).child('containers').child(containerName).remove();
  }

  void _navigateToContainerDetails(String containerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContainerInside(containerId: containerName),
      ),
    );
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
        backgroundColor: Color.fromARGB(255, 106, 50, 155),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 179, 138, 216),
              Colors.white,
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (containers.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: containers.length,
                  itemBuilder: (context, index) {
                    final containerName = containers[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: GestureDetector(
                        onTap: () => _navigateToContainerDetails(containerName),
                        child: ContainerCard(
                          containerName: containerName,
                          onRemove: () => _removeContainer(containerName),
                          onView: () => _navigateToContainerDetails(containerName), // Pass the view function
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (containers.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No containers added yet. Click "Add More" to get started!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: _addNewContainer,
                icon: const Icon(Icons.add),
                label: const Text('Add More'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
            const Spacer(),
            BottomNavigation(
              onHomePressed: () {
                // Already on HomeScreen, can do nothing or refresh if needed
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              onAddPressed: _addNewContainer,
              onHistoryPressed: () {
                if (containers.isNotEmpty) {
                  _navigateToContainerDetails(containers.first);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No containers to view history for. Add a container first!')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ContainerCard extends StatelessWidget {
  final String containerName;
  final VoidCallback onRemove;
  final VoidCallback onView;

  const ContainerCard({
    super.key,
    required this.containerName,
    required this.onRemove,
    required this.onView,
  });

  void _showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Container Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close options dialog
                  onView(); // Execute the view operation
                },
                child: const Text(
                  'View',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close options dialog
                  _showDeleteConfirmationDialog(context);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete "$containerName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close confirmation dialog
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close confirmation dialog
                onRemove(); // Execute the actual delete operation
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  containerName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert), // 3-dot icon
                  onPressed: () => _showOptionsDialog(context), // Show options dialog
                ),
              ],
            ),
            StreamBuilder(
              stream: FirebaseDatabase.instance
                  .ref('users/${FirebaseAuth.instance.currentUser?.uid}/containers/$containerName/currentWeight')
                  .onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                  final dynamic value = snapshot.data?.snapshot.value;
                  final double weight = value is int ? value.toDouble() : value as double;
                  return Text(
                    'Current Weight: ${weight.toStringAsFixed(2)}g',
                    style: const TextStyle(fontSize: 16),
                  );
                }
                return const Text(
                  'Current Weight: Loading...',
                  style: TextStyle(fontSize: 16),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

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
            color: Colors.blue, // Active color for home
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 30), // Plus icon
            onPressed: onAddPressed,
            color: Colors.grey,
          ),
          IconButton(
            icon: const Icon(Icons.history, size: 30), // History icon
            onPressed: onHistoryPressed,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}
