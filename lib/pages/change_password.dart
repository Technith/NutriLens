import 'package:flutter/material.dart';
import '../components/button_fab.dart';
import '../components/text_field_fab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChangePassword extends StatelessWidget {
  final passwordController = TextEditingController();

  ChangePassword({super.key});

  void changePassword() async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.updatePassword(
      passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
      ),
      body: Center(
        child: Column(
          children: [
            const Text(
              'Change Password',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 50),

            TextFieldFab(controller: passwordController,
                hintText: 'Password',
                obscureText: true),

            const SizedBox(height: 25),


            // change button
            ButtonFab(buttonText: 'Change Password', onTap: () => {changePassword(),Navigator.pop(context), FirebaseAuth.instance.signOut()}),
          ],
        ),
      ),
    );
  }
}
