import '../components/button_fab.dart';
import '../components/text_field_fab.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangeEmail extends StatelessWidget {
  final emailController = TextEditingController();

  ChangeEmail({super.key});


  void changeEmail() async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.verifyBeforeUpdateEmail(
      emailController.text,
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
              'Change Email',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 50),

            TextFieldFab(controller: emailController,
                hintText: 'Email',
                obscureText: false),

            const SizedBox(height: 25),


            // change button
            ButtonFab(buttonText: 'Change Email', onTap: () => {changeEmail(), Navigator.pop(context), FirebaseAuth.instance.signOut()}),
          ],
        ),
      ),
    );
  }
}
