import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ContainerInside.dart';
import '../auth/login_screen.dart'; // Make sure you have this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> containers = ['01'];
  final String _storageKey = 'saved_containers';

  @override
  void initState() {
    super.initState();
    _loadContainers();
  }

  Future<void> _loadContainers() async {
    final prefs = await SharedPreferences.getInstance();
    final savedContainers = prefs.getStringList(_storageKey);
    if (savedContainers != null && savedContainers.isNotEmpty) {
      setState(() {
        containers = savedContainers;
      });
    }
  }

  Future<void> _saveContainers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, containers);
  }

  void _addNewContainer() async {
    final newContainerId = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String containerId = '';
        return AlertDialog(
          title: const Text('Add New Container'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Enter Container ID',
              hintText: 'e.g., 02, 03, etc.',
            ),
            onChanged: (value) {
              containerId = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, containerId),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (newContainerId != null && newContainerId.isNotEmpty) {
      setState(() {
        containers.add(newContainerId);
      });
      await _saveContainers();
    }
  }

  void _removeContainer(String containerId) async {
    setState(() {
      containers.remove(containerId);
    });
    await _saveContainers();
  }

  void _navigateToContainerDetails(String containerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContainerInside(containerId: containerId),
      ),
    );
  }

  void _logout() async {
  // Clear any session data if needed
  // Then navigate to login screen
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const LoginScreen()),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GrainGuard'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          ...containers.map((containerId) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: GestureDetector(
                  onTap: () => _navigateToContainerDetails(containerId),
                  child: ContainerCard(
                    containerNumber: containerId,
                    onRemove: containerId != '01' 
                        ? () => _removeContainer(containerId) 
                        : null,
                  ),
                ),
              )),
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
          const BottomNavigation(),
        ],
      ),
    );
  }
}

class ContainerCard extends StatelessWidget {
  final String containerNumber;
  final VoidCallback? onRemove;

  const ContainerCard({
    super.key,
    required this.containerNumber,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Container $containerNumber',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onRemove,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key});

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
            onPressed: () {},
            color: Colors.blue,
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
    );
  }
}