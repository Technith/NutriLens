import 'package:flutter/material.dart';
import '../components/button_fab.dart';
import '../components/text_field_fab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../theme/theme_colors.dart';

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
      backgroundColor: ThemeColor.background,
      appBar: AppBar(
        backgroundColor: ThemeColor.background,
        foregroundColor: ThemeColor.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          children: [
            Text(
              'Change Password',
              style: TextStyle(
                color: ThemeColor.textPrimary,
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
