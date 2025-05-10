import '../components/button_fab.dart';
import '../components/text_field_fab.dart';
import 'package:flutter/material.dart';

class RegistrationPage extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  RegistrationPage({super.key});

  void register() {}


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
              'Create Account',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 50),

            TextFieldFab(controller: emailController, hintText: 'Email', obscureText: false),

            const SizedBox(height: 25),

            TextFieldFab(controller: passwordController, hintText: 'Password', obscureText: true),

            const SizedBox(height: 50),

              // sign in button
            ButtonFab(buttonText: 'Register', onTap: register),
          ],
        ),
      ),
    );
  }
}
