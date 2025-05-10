import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nutrilensfire/pages/change_email.dart';
import 'package:nutrilensfire/pages/change_password.dart';
import 'package:nutrilensfire/pages/calorie_goal_page.dart';
import 'package:nutrilensfire/pages/allergen_info.dart';
import 'package:nutrilensfire/pages/tracker_page.dart';
import 'package:firebase_database/firebase_database.dart';

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
      home: ProfilePage(), // Use const for optimization
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key}); // Updated with key

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Implement navigation logic here based on the index
    });
  }

  Future<String?> getEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.email;
    } else {
      return "Guest";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: FutureBuilder(
            future: getEmail(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text(
                  snapshot.error.toString(),
                );
              } else {
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Nutrilens'),
                    centerTitle: true,
                    elevation: 0,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  body: Column(
                    children: <Widget>[
                      Text(
                        snapshot.data.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                                ChangeEmail()),
                          );
                        },
                        child: const Text('Change Email'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                                ChangePassword()),
                          );
                        },
                        child: const Text('Change Password'),
                      ),
                      const SizedBox(height: 10),
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
                                title: const Text('Calorie/Weight Goals'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) =>
                                        CalorieGoalPage()),
                                  );
                                },
                              ),
                              /*ListTile(
                                title: const Text('Ingredients Profile'),
                                onTap: () {
                                  Navigator.pushNamed(context, '/calorie_goal');
                                },
                              ),*/
                              ListTile(
                                title: const Text('Allergen Information'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) =>
                                        AllergenInfo()),
                                  );
                                },
                              ),
                              ListTile(
                                title: const Text('Calorie/Nutrition Tracker'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) =>
                                        TrackerPage()),
                                  );
                                },
                              ),
                              /*ListTile(
                                title: const Text('History Log'),
                                onTap: () {
                                  Navigator.pushNamed(context, '/history_log');
                                },
                              ),*/
                            ],
                          ).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }
        )
    );
  }
}