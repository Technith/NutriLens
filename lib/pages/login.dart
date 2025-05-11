import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/button_fab.dart';
import '../components/text_field_fab.dart';
import 'registration.dart';
import 'home_page.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void signIn(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.message}')),
        );
      }
    }
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
              const Text(
                'NutriLens',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 48,
                ),
              ),
              const SizedBox(height: 100),
              TextFieldFab(
                controller: emailController,
                hintText: 'Email',
                obscureText: false,
              ),
              const SizedBox(height: 25),
              TextFieldFab(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 50),
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
                child: const Text("Register"),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut(); // ✅ Force logout for guest
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  }
                },
                child: const Text("Continue as Guest"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}