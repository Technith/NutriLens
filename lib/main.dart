import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nutrilensfire/theme/theme_colors.dart';
import 'package:provider/provider.dart';
import 'services/notification_service.dart';
import 'pages/health_metrics_page.dart';
import 'pages/login.dart';
import 'pages/home_page.dart' as main_home;
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
import 'pages/glossary_page.dart';
import 'pages/deleted_notifications_page.dart';
import 'services/api_service.dart';
import 'pages/deals_page.dart';
import 'pages/barcode_scanner_page.dart'; // <-- Your scanner page
import 'pages/report_issue_page.dart';
import 'pages/add_ingredients_page.dart';
import 'services/color_theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await Hive.initFlutter();
  await Hive.openBox('productCache');
  await Hive.openBox('translationCache');
  await Hive.openBox('settingsBox');
  // Fetch recalls when the app starts
  ApiService().fetchFDARecalls();

  NotificationService notificationService = NotificationService();
  await notificationService.initialize();

  ThemeColor.setLightTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => notificationService),
        ChangeNotifierProvider(create: (_) => ColorThemeProvider()),
      ],
      child: NutriLensApp(notificationService: notificationService),
    ),
  );
}

class NutriLensApp extends StatelessWidget {
  final NotificationService notificationService;
  const NutriLensApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriLens',
      navigatorKey: notificationService.navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) =>  LoginPage(),
        '/home': (context) => const CustomHomePage(), // ← Modified version
        '/barcode': (context) => const BarcodeScannerPage(),
        '/settings': (context) =>  SettingsPage(),
        '/search': (context) => const SearchPage(),
        '/notifications': (context) =>  NotificationsPage(),
        '/language': (context) => const LanguagePage(),
        '/theme': (context) => const ThemePage(),
        '/dietary_preferences': (context) => const DietaryPreferencesPage(),
        '/user_guide': (context) => const UserGuidePage(),
        '/support': (context) => const SupportPage(),
        '/change_password': (context) => const ChangePasswordPage(),
        '/profile': (context) => const ProfilePage(),
        '/ingredients_profile': (context) => const IngredientsProfilePage(),
        '/calorie_goal': (context) => CalorieGoalPage(),
        '/health_metrics': (context) => const HealthMetricsPage(),
        '/history_log': (context) => const HistoryLogPage(),
        '/glossary': (context) => const GlossaryPage(),
        './deleted_notifications': (context) => DeletedNotificationsPage(),
        '/deals': (context) => const DealsPage(),
        '/report_issue': (context) => const ReportIssuePage(),
        '/add_ingredients': (context) => const AddIngredientsPage(),
      },
    );
  }
}

class CustomHomePage extends StatelessWidget {
  const CustomHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NutriLens Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.pushNamed(context, '/barcode');
            },
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.qr_code),
          label: const Text('Scan Barcode'),
          onPressed: () {
            Navigator.pushNamed(context, '/barcode');
          },
        ),
      ),
    );
  }
}
