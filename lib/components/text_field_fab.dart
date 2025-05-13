import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';

class TextFieldFab extends StatelessWidget {
  final dynamic controller;
  final String hintText;
  final bool obscureText;

  const TextFieldFab({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: ThemeColor.textPrimary),
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: ThemeColor.primary),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: ThemeColor.primary),
          ),
          fillColor: ThemeColor.secondary,
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(color: ThemeColor.textSecondary),
        ),
      ),
    );
  }
}