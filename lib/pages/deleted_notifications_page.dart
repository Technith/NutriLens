import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';

class DeletedNotificationsPage extends StatefulWidget {
  @override
  _DeletedNotificationsPageState createState() => _DeletedNotificationsPageState();
}

class _DeletedNotificationsPageState extends State<DeletedNotificationsPage> {
  @override
  void initState() {
    super.initState();
    _loadDeletedNotifications(); // Ensure deleted notifications load when this page opens
  }

  void _loadDeletedNotifications() async {
    var notificationService = Provider.of<NotificationService>(context, listen: false);
    await notificationService.loadDeletedNotifications(); //
    setState(() {}); // Refresh UI
  }


  @override
  Widget build(BuildContext context) {
    var notificationService = Provider.of<NotificationService>(context);
    var deletedNotifications = notificationService.getDeletedNotifications();

    return Scaffold(
      appBar: AppBar(
        title: Text("Deleted Notifications"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue),
            onPressed: _loadDeletedNotifications, // Refresh deleted notifications
          ),
        ],
      ),
      body: deletedNotifications.isEmpty
          ? Center(child: Text("No deleted notifications"))
          : ListView.builder(
        itemCount: deletedNotifications.length,
        itemBuilder: (context, index) {
          var message = deletedNotifications[index];
          return Card(
            child: ListTile(
              title: Text(message.notification?.title ?? "No Title"),
              subtitle: Text(message.notification?.body ?? "No Content"),
              trailing: IconButton(
                icon: Icon(Icons.restore, color: Colors.green),
                onPressed: () {
                  notificationService.restoreNotification(index);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
