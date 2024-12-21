import 'package:flutter/material.dart';
import '../components/button_fab.dart';
import '../components/text_field_fab.dart';
import 'registration.dart';


class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void signIn(BuildContext context) {
  Navigator.pushReplacementNamed(context, '/home'); // Navigate to HomePage
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 200),
              // Title
              const Text(
                'NutriLens',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 48,
                ),

              ),

              const SizedBox(height: 100),

              // Email text field
              TextFieldFab(controller: emailController, hintText: 'Email', obscureText: false),

              const SizedBox(height: 25),

              // password text field
              TextFieldFab(controller: passwordController, hintText: 'Password', obscureText: true),

              const SizedBox(height: 50),

              // sign in button
              ButtonFab(
                buttonText: 'Sign-In',
                onTap: () => signIn(context),
              ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegistrationPage()),
                  );
                },
                child: Text("Register"),
              ),
              // Oauth buttons

      ],)
    )));
  }
}