import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

class NotificationService {
  /// Get access token for Google Cloud Console
  static Future<String> getAccessToken() async {
    // Replace this with your service account credentials JSON
    String? serviceAccountJson = dotenv.env['GOOGLE_SERVICE_KEY'];

    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    var client = http.Client();
    try {
      final credentials =
          auth.ServiceAccountCredentials.fromJson(serviceAccountJson);
      final accessCredentials =
          await auth.obtainAccessCredentialsViaServiceAccount(
        credentials,
        scopes,
        client,
      );
      return accessCredentials.accessToken.data;
    } finally {
      client.close();
    }
  }

  /// Send a notification using Firebase Cloud Messaging
  static Future<void> sendNotification(
    String deviceToken,
    String title,
    String body,
  ) async {
    final String accessToken = await getAccessToken();
    String endpointFCM =
        'https://fcm.googleapis.com/v1/projects/craftblend-c388a/messages:send';
    final Map<String, dynamic> message = {
      "message": {
        "token": deviceToken,
        "notification": {"title": title, "body": body},
        "data": {"route": "serviceScreen"}
      }
    };

    final response = await http.post(
      Uri.parse(endpointFCM),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification: ${response.body}');
    }
  }
}
