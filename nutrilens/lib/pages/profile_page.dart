import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key); // Updated with key

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrilens',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ProfilePage(), // Use const for optimization
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key); // Updated with key

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 2;  // Initialize profile tab as active

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Implement navigation logic here based on the index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrilens'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: <Widget>[
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade300,
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () {
              // Add functionality to set a profile picture
            },
            child: const Text('Set Profile Picture'),
          ),
          Expanded(
            child: ListView(
              children: ListTile.divideTiles(
                context: context,
                tiles: [
                  ListTile(
                    title: const Text('Ingredients Profile'),
                    onTap: () {
                      Navigator.pushNamed(context, '/ingredients_profile');
                    },
                  ),
                  ListTile(
                    title: const Text('Calorie Goal'),
                    onTap: () {
                      Navigator.pushNamed(context, '/calorie_goal');
                    },
                  ),
                  ListTile(
                    title: const Text('Health Metrics'),
                    onTap: () {
                      Navigator.pushNamed(context, '/health_metrics');
                    },
                  ),
                  ListTile(
                    title: const Text('History Log'),
                    onTap: () {
                      Navigator.pushNamed(context, '/history_log');
                    },
                  ),
                ],
              ).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}