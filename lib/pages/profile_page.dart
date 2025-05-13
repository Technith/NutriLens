import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nutrilensfire/pages/change_email.dart';
import 'package:nutrilensfire/pages/change_password.dart';
import 'package:nutrilensfire/pages/calorie_goal_page.dart';
import 'package:nutrilensfire/pages/allergen_info.dart';
import 'package:nutrilensfire/pages/tracker_page.dart';
import 'package:nutrilensfire/pages/login.dart';
import '../theme/theme_colors.dart';

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
              backgroundColor: ThemeColor.background,
              appBar: AppBar(
                title: const Text('Nutrilens'),
                centerTitle: true,
                elevation: 0,
                backgroundColor: ThemeColor.primary,
                foregroundColor: ThemeColor.textPrimary,
              ),
              body: Column(
                children: <Widget>[
                  Text(
                    snapshot.data.toString(),
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ThemeColor.textPrimary
                    ),
                  ),

                  if (user != null) ...[
                    Center(
                      child: ElevatedButton.icon(
                          label: const Text("Change Email"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChangeEmail(),
                              ),
                            );
                          }
                      ),
                    ),
                    Center(
                      child: ElevatedButton.icon(
                          label: const Text("Change Password"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChangePassword(),
                              ),
                            );
                          }
                      ),
                    ),
                    const SizedBox(height: 10),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: ThemeColor.secondary,
                      child: Icon(Icons.person, size: 50, color: ThemeColor.primary),
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        "Want to save preferences and personalize your experience?",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: ThemeColor.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage())); // ✅ Fixed redirect
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeColor.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        "Sign in or Create an Account",
                        style: TextStyle(color: ThemeColor.textPrimary),
                      ),
                    ),
                  ],

                  if (user != null)
                    Expanded(
                      child: ListView(
                        children: ListTile.divideTiles(
                          context: context,
                          tiles: [
                            ListTile(
                              title: Text('Calorie Goal',style: TextStyle(color: ThemeColor.textPrimary),),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CalorieGoalPage()),
                                );
                              },
                            ),
                            ListTile(
                              title: Text('Allergen Information',style: TextStyle(color: ThemeColor.textPrimary),),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AllergenInfo()),
                                );
                              },
                            ),
                            ListTile(
                              title: Text('Calorie/Nutrition Tracker',style: TextStyle(color: ThemeColor.textPrimary),),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => TrackerPage()),
                                );
                              },
                            ),
                            ListTile(
                              title: Text('History Log',style: TextStyle(color: ThemeColor.textPrimary),),
                              onTap: () {
                                Navigator.pushNamed(context, '/history_log');
                              },
                            ),
                            ListTile(
                              title: Text('Report Issue',style: TextStyle(color: ThemeColor.textPrimary),),
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