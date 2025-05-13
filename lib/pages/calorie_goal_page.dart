import 'package:flutter/material.dart';
import '../components/text_field_fab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../theme/theme_colors.dart';

Future<String?> getCalorieGoal() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DatabaseReference ref = FirebaseDatabase.instance.ref("Users/${user.uid}");
    var snapshot = await ref.child('Calorie Goal').get();
    if (snapshot.exists) {
      return snapshot.value.toString();
    }
  }
  return "None";
}

class CalorieGoalPage extends StatelessWidget {
  final goalController = TextEditingController();

  CalorieGoalPage({super.key});

  void addCalorieGoal(String input) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference ref = FirebaseDatabase.instance.ref("Users/${user.uid}");
      await ref.update({
        "Calorie Goal" : input,
      });
    }
  }

  Future<void> inputCalorieGoal(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              backgroundColor: ThemeColor.background,
              title: Text(
                'Enter Calorie Goal',
                style: TextStyle(color: ThemeColor.textPrimary),
              ),
              content: TextFieldFab(controller: goalController, hintText: 'Daily Calories', obscureText: false),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel', style: TextStyle(color: ThemeColor.textSecondary)),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text('Submit', style: TextStyle(color: ThemeColor.primary)),
                  onPressed: () {
                    addCalorieGoal(goalController.text);
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CalorieGoalPage()));
                  },
                )
              ]
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: ThemeColor.background,
        appBar: AppBar(
          title: const Text('Calorie Goal'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: ThemeColor.background,
          foregroundColor: ThemeColor.textPrimary,
        ),
        body: Center(
            child:
            Column(
                children: [
                  FutureBuilder(
                      future: getCalorieGoal(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text(
                            snapshot.error.toString(),
                            style: TextStyle(color: ThemeColor.textPrimary),
                          );
                        }
                        else {
                          return Text(
                            'Current Calorie Goal : ${snapshot.data.toString()}',
                            style: TextStyle(
                              color: ThemeColor.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          );
                        }
                      }
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      inputCalorieGoal(context);
                    },
                    child: const Text("Change Calorie Goal"),
                  ),
                ])));
  }


}
