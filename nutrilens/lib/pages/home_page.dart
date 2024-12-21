import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nutrilens'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // Text color
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
          children: [
            Icon(
              Icons.camera_alt_outlined, // Camera icon
              size: 150,
              color: Colors.black,
            ),
            SizedBox(height: 20),
            Text(
              'Scan now!',
              style: TextStyle(
                fontSize: 20,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Index of the HomePage
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.green), // Highlighted home icon
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/settings'); 
          } else if (index == 1) {
            Navigator.pushNamed(context, '/notifications');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/home');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/search');
          } else if (index == 4) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }
}
