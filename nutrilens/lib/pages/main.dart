import 'package:flutter/material.dart';
import 'package:my_project/pages/health_metrics_page.dart';
import 'pages/login.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'pages/search_page.dart';
import 'pages/notifications_page.dart';
import 'pages/language_page.dart';
import 'pages/theme_page.dart';
import 'pages/dietary_preferences_page.dart';
import 'pages/user_guide_page.dart';
import 'pages/support_page.dart';
import 'pages/change_password_page.dart';
import 'pages/profile_page.dart';
import 'pages/ingredients_profile_page.dart';
import 'pages/calorie_goal_page.dart';
import 'pages/history_log_page.dart';

void main() {
  runApp(NutriLensApp());
}

class NutriLensApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriLens',
      initialRoute: '/', // Set LoginPage as the initial route
      routes: {
        '/': (context) => LoginPage(), // Login Page route
        '/home': (context) => HomePage(), // Home Page route
        '/settings': (context) => SettingsPage(), // Settings Page route
        '/search': (context) => SearchPage(), // Search Page route
        '/notifications': (context) => NotificationsPage(), // Notifications Page route
        '/language': (context) => LanguagePage(), // Language Page route
        '/theme': (context) => ThemePage(), // Theme Page route
        '/dietary_preferences': (context) => DietaryPreferencesPage(), // Dietary Preferences Page route
        '/user_guide': (context) => UserGuidePage(), // User Guide Page route
        '/support': (context) => SupportPage(), // Support Page route
        '/change_password': (context) => ChangePasswordPage(), // Change Password Page route
        '/profile': (context) => ProfilePage(),
        '/ingredients_profile': (context) => IngredientsProfilePage(),
        '/calorie_goal': (context) => CalorieGoalPage(),
        '/health_metrics': (context) => HealthMetricsPage(),
        '/history_log': (context) => HistoryLogPage()
        


      },
    );
  }
}
