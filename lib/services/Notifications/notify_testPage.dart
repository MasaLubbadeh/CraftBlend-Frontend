import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'notification_helper.dart';

class NotificationTestPage extends StatelessWidget {
  const NotificationTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Notifications")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            FirebaseMessaging messaging = FirebaseMessaging.instance;
            String? token = await messaging.getToken();

            if (token == null) {
              print("Error: No device token available.");
              return;
            }

            try {
              await NotificationService.sendNotification(
                token,
                "Test Notification",
                "This is a test notification body.",
              );
              print("Notification sent successfully");
            } catch (error) {
              print("Error sending notification: $error");
            }
          },
          child: const Text("Send Test Notification"),
        ),
      ),
    );
  }
}
