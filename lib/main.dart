import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/notification_service.dart';
import 'pages/health_metrics_page.dart';
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
import 'pages/glossary_page.dart';
import 'pages/deleted_notifications_page.dart';
import 'services/api_service.dart';
import 'pages/deals_page.dart';
import 'pages/barcode_scanner_page.dart';
import 'pages/report_issue_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Fetch recalls when the app starts
  ApiService().fetchFDARecalls();

  NotificationService notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => notificationService,
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
        '/': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/barcode': (context) => BarcodeScannerPage(),
        '/settings': (context) => SettingsPage(),
        '/search': (context) => SearchPage(),
        '/notifications': (context) => NotificationsPage(),
        '/language': (context) => LanguagePage(),
        '/theme': (context) => ThemePage(),
        '/dietary_preferences': (context) => DietaryPreferencesPage(),
        '/user_guide': (context) => UserGuidePage(),
        '/support': (context) => SupportPage(),
        '/change_password': (context) => ChangePasswordPage(),
        '/profile': (context) => ProfilePage(),
        '/ingredients_profile': (context) => IngredientsProfilePage(),
        '/calorie_goal': (context) => CalorieGoalPage(),
        '/health_metrics': (context) => HealthMetricsPage(),
        '/history_log': (context) => HistoryLogPage(),
        '/glossary': (context) => GlossaryPage(),
        './deleted_notifications': (context) => DeletedNotificationsPage(),
        '/deals': (context) => DealsPage(),
        '/report_issue': (context) => ReportIssuePage()
      },
    );
  }
}
