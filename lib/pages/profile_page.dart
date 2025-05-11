import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nutrilensfire/pages/change_email.dart';
import 'package:nutrilensfire/pages/change_password.dart';
import 'package:nutrilensfire/pages/calorie_goal_page.dart';
import 'package:nutrilensfire/pages/allergen_info.dart';
import 'package:nutrilensfire/pages/tracker_page.dart';
import 'package:nutrilensfire/pages/login.dart'; // ✅ Added import

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<String> getEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email ?? 'Guest';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Center(
      child: FutureBuilder(
        future: getEmail(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
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
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (user != null) ...[
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeEmail()));
                      },
                      child: const Text('Change Email'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePassword()));
                      },
                      child: const Text('Change Password'),
                    ),
                    const SizedBox(height: 10),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade300,
                      child: const Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    TextButton(
                      onPressed: () {
                        // Future feature: set profile picture
                      },
                      child: const Text('Set Profile Picture'),
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        "Want to save preferences and personalize your experience?",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage())); // ✅ Fixed redirect
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("Sign in or Create an Account"),
                    ),
                  ],

                  if (user != null)
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
                                  MaterialPageRoute(builder: (_) => CalorieGoalPage()),
                                );
                              },
                            ),
                            ListTile(
                              title: const Text('Allergen Information'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AllergenInfo()),
                                );
                              },
                            ),
                            ListTile(
                              title: const Text('Calorie/Nutrition Tracker'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => TrackerPage()),
                                );
                              },
                            ),
                            ListTile(
                              title: const Text('History Log'),
                              onTap: () {
                                Navigator.pushNamed(context, '/history_log');
                              },
                            ),
                            ListTile(
                              title: const Text('Report Issue'),
                              onTap: () {
                                Navigator.pushNamed(context, '/report_issue');
                              },
                            ),
                          ],
                        ).toList(),
                      ),
                    ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}