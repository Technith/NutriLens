import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/smart_final_deals_scraper.dart';
import '../services/sprouts_deals_scraper.dart';
import '../services/albertsons_deals_scraper.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nutrilensfire/pages/login.dart'; // ✅ Import login.dart page

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedFrequency = "daily";
  final String userId = "test_user";

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    var notificationService = Provider.of<NotificationService>(context, listen: false);
    String frequency = await notificationService.getNotificationFrequency(userId);
    setState(() {
      _selectedFrequency = frequency;
    });
  }

  Future<void> testFirebaseWrite() async {
    final DatabaseReference testRef = FirebaseDatabase.instance.ref('test_connection');

    try {
      await testRef.set({
        'message': 'Hello from NutriLens!',
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Successfully wrote to Firebase!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to write to Firebase: $e')),
      );
    }
  }

  void _updateNotificationPreference(String newFrequency) async {
    var notificationService = Provider.of<NotificationService>(context, listen: false);
    await notificationService.saveNotificationFrequency(userId, newFrequency);

    setState(() {
      _selectedFrequency = newFrequency;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Notification frequency updated to: $newFrequency")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrilens'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        children: [
          ListTile(
            title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Notification Frequency', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Choose how often you receive alerts"),
            trailing: DropdownButton<String>(
              value: _selectedFrequency,
              items: ["daily", "weekly"]
                  .map((freq) => DropdownMenuItem(value: freq, child: Text(freq.toUpperCase())))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _updateNotificationPreference(value);
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Check FDA Recalls', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            trailing: const Icon(Icons.warning, color: Colors.red),
            onTap: () async {
              ApiService apiService = ApiService();
              await apiService.fetchFDARecalls();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("🔍 Checking for FDA Recalls..."),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Fetch Albertsons Deals', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            trailing: const Icon(Icons.local_offer, color: Colors.red),
            onTap: () async {
              final scraper = AlbertsonsDealsScraper();
              await scraper.scrapeAndSaveDeals();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Albertsons Deals fetched and saved!')),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Language', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/language');
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Theme', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/theme');
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Dietary Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/dietary_preferences');
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('User Guide', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/user_guide');
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Support', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/support');
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/change_password');
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Test Firebase Connection', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.cloud_upload),
            onTap: () async {
              await testFirebaseWrite();
            },
          ),
          const Divider(),

          if (user != null)
            ListTile(
              title: const Text(
                'Log out',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                        (route) => false,
                  );
                }
              },
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.settings, color: Colors.green), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
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