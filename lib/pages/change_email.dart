import '../components/button_fab.dart';
import '../components/text_field_fab.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/theme_colors.dart';

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
              'Change Email',
              style: TextStyle(
                color: ThemeColor.textPrimary,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 50),

            Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: InputDecorationTheme(
                  hintStyle: TextStyle(color: ThemeColor.textSecondary),
                ),
                textTheme: Theme.of(context).textTheme.copyWith(
                  bodyMedium: TextStyle(color: ThemeColor.textPrimary),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeColor.primary,
                    foregroundColor: ThemeColor.textPrimary,
                  ),
                ),
              ),
              child: Column(
                children: [
                  TextFieldFab(
                    controller: emailController,
                    hintText: 'Email',
                    obscureText: false,
                  ),
                  const SizedBox(height: 25),
                  ButtonFab(
                    buttonText: 'Change Email',
                    onTap: () => {
                      changeEmail(),
                      Navigator.pop(context),
                      FirebaseAuth.instance.signOut(),
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
