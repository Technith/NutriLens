import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';

class ButtonFab extends StatelessWidget {
  final String buttonText;
  final Function()? onTap;

  const ButtonFab({
    super.key,
    required this.buttonText,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(25),
        margin: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: ThemeColor.primary,
        ),
        child: Center(
          child: Text(
            buttonText,
            style: TextStyle(
              color: ThemeColor.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}