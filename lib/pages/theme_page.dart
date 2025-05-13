import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/color_theme_service.dart';
import '../theme/theme_colors.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ColorThemeProvider>(context);

    return Scaffold(
      backgroundColor: ThemeColor.background,
      appBar: AppBar(
        backgroundColor: ThemeColor.background,
        iconTheme: IconThemeData(color: ThemeColor.textPrimary),
        title: Text(
          'Theme Settings',
          style: TextStyle(color: ThemeColor.textPrimary),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a theme:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ThemeColor.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            
            // Light Mode Button
            _themeButton(
              context,
              label: 'Light Mode',
              selected: themeProvider.currentTheme == AppTheme.light,
              onPressed: () => themeProvider.setTheme(AppTheme.light),
            ),
            const SizedBox(height: 12),

            // Dark Mode Button
            _themeButton(
              context,
              label: 'Dark Mode',
              selected: themeProvider.currentTheme == AppTheme.dark,
              onPressed: () => themeProvider.setTheme(AppTheme.dark),
            ),
            const SizedBox(height: 12),

            // Warm Mode Button
            _themeButton(
              context,
              label: 'Warm Mode',
              selected: themeProvider.currentTheme == AppTheme.warm,
              onPressed: () => themeProvider.setTheme(AppTheme.warm),
            ),
            const SizedBox(height: 12),

            // Nature Mode Button
            _themeButton(
              context,
              label: 'Nature Mode',
              selected: themeProvider.currentTheme == AppTheme.nature,
              onPressed: () => themeProvider.setTheme(AppTheme.nature),
            ),
          ],
        ),
      ),
    );
  }

  // Button builder
  Widget _themeButton(BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? ThemeColor.primary : ThemeColor.secondary,
          foregroundColor: ThemeColor.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(label),
      ),
    );
  }
}