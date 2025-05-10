import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationService with ChangeNotifier {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final NotificationService _instance = NotificationService._internal();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("deleted_notifications");
  final DatabaseReference _recallRef = FirebaseDatabase.instance.ref("recalls");
  final DatabaseReference _userSettingsRef = FirebaseDatabase.instance.ref("user_settings"); // ✅ Reference for user settings

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  List<RemoteMessage> _notifications = [];
  List<RemoteMessage> get notifications => _notifications;

  List<Map<String, dynamic>> _recalls = [];
  List<Map<String, dynamic>> get recalls => _recalls;

  List<RemoteMessage> _deletedNotifications = [];

  /// Initialize Firebase and set up notifications
  Future<void> initialize() async {
    await Firebase.initializeApp();
    await _requestNotificationPermission();
    _setupFirebaseMessagingHandlers();
    await loadDeletedNotifications();
    await fetchRecalls();
  }

  /// Fetch recalls from Firebase Realtime Database
  Future<void> fetchRecalls() async {
    DatabaseEvent event = await _recallRef.once();

    if (event.snapshot.value != null && event.snapshot.value is Map) {
      Map<dynamic, dynamic> recallsMap = event.snapshot.value as Map<dynamic, dynamic>;

      _recalls = recallsMap.values.map((recall) {
        return {
          "product": recall["product"] ?? "Unknown Product",
          "reason": recall["reason"] ?? "No reason provided",
          "date": recall["date"] ?? "Unknown Date",
        };
      }).toList();

      notifyListeners();
    }
  }

  /// Request user permission for notifications
  Future<void> _requestNotificationPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print("User declined notifications");
    } else {
      print("User granted notification permission");
    }
  }

  /// Fetch user's notification frequency preference
  Future<String> getNotificationFrequency(String userId) async {
    DatabaseEvent event = await _userSettingsRef.child(userId).once();

    if (event.snapshot.value != null) {
      Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      return data["notification_frequency"] ?? "daily"; // Default to daily if not set
    }

    return "daily";
  }

  /// Save user's notification frequency preference
  Future<void> saveNotificationFrequency(String userId, String frequency) async {
    await _userSettingsRef.child(userId).set({
      "notification_frequency": frequency,
      "last_notified": DateTime.now().toIso8601String(),
    });

    print("✅ Notification preference updated to: $frequency");
  }

  /// Check if user should receive a notification based on frequency
  Future<bool> shouldSendNotification(String userId) async {
    DatabaseEvent event = await _userSettingsRef.child(userId).once();

    if (event.snapshot.value != null) {
      Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      String frequency = data["notification_frequency"] ?? "daily";
      DateTime lastNotified = data.containsKey("last_notified")
          ? DateTime.parse(data["last_notified"])
          : DateTime.fromMillisecondsSinceEpoch(0);

      DateTime now = DateTime.now();

      if (frequency == "daily" && now.difference(lastNotified).inHours < 24) {
        return false; // Skip if already sent today
      }

      if (frequency == "weekly" && now.difference(lastNotified).inDays < 7) {
        return false; // Skip if already sent this week
      }
    }

    return true;
  }

  /// Send notification only if the user is eligible
  Future<void> sendNotification(String userId, String title, String body) async {
    bool canSend = await shouldSendNotification(userId);
    if (!canSend) {
      print("⏳ Notification skipped based on user preference.");
      return;
    }

    // ✅ Send the notification
    await FirebaseDatabase.instance.ref("notifications").push().set({
      "title": title,
      "body": body,
      "userId": userId,
      "timestamp": DateTime.now().toIso8601String(),
    });

    // ✅ Update last notified timestamp
    await _userSettingsRef.child(userId).update({"last_notified": DateTime.now().toIso8601String()});

    print("✅ Notification sent: $title");
  }

  /// Show a small alert when a notification appears in the foreground
  void _showNotificationAlert(RemoteMessage message) {
    BuildContext? context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.notification?.title ?? "New Notification"),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            navigatorKey.currentState?.pushNamed('/notifications');
          },
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Set up handlers for Firebase notifications
  void _setupFirebaseMessagingHandlers() {
    _firebaseMessaging.getToken().then((token) {
      print("FCM Token: $token");
    });

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _notifications.insert(0, message);
      notifyListeners();
      _showNotificationAlert(message);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _notifications.insert(0, message);
      notifyListeners();
      navigatorKey.currentState?.pushNamed('/notifications');
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Delete a notification and store it in Firebase
  void deleteNotification(int index, BuildContext context) async {
    if (index >= 0 && index < _notifications.length) {
      RemoteMessage deleted = _notifications.removeAt(index);
      _deletedNotifications.add(deleted);
      await _saveDeletedNotifications();
      notifyListeners();
    }
  }

  /// Retrieve all deleted notifications
  List<RemoteMessage> getDeletedNotifications() {
    return _deletedNotifications;
  }

  /// Restore a deleted notification
  void restoreNotification(int index) async {
    if (index >= 0 && index < _deletedNotifications.length) {
      _notifications.insert(0, _deletedNotifications.removeAt(index));
      await _saveDeletedNotifications();
      notifyListeners();
    }
  }

  /// Save deleted notifications to Firebase
  Future<void> _saveDeletedNotifications() async {
    List<Map<String, dynamic>> deletedList = _deletedNotifications.map((message) {
      return {
        "title": message.notification?.title ?? "No Title",
        "body": message.notification?.body ?? "No Content",
      };
    }).toList();
    await _databaseRef.set(deletedList);
  }

  /// Load deleted notifications from Firebase
  Future<void> loadDeletedNotifications() async {
    DatabaseEvent event = await _databaseRef.once();

    if (event.snapshot.value != null && event.snapshot.value is Map) {
      Map<dynamic, dynamic> deletedMap = event.snapshot.value as Map<dynamic, dynamic>;

      _deletedNotifications = deletedMap.values.map((data) {
        return RemoteMessage(
          notification: RemoteNotification(
            title: data["title"] ?? "No Title",
            body: data["body"] ?? "No Content",
          ),
        );
      }).toList();

      notifyListeners();
    }
  }

  /// Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print("Handling background message: ${message.messageId}");
  }
}
