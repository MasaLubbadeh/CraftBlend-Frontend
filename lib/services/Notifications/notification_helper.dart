import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../configuration/config.dart';

class NotificationService {
  /// Get access token for Google Cloud Console
  static Future<String> getAccessToken() async {
    final privateKey = dotenv.env['FIREBASE_PRIVATE_KEY']!;
    final privateKeyId = dotenv.env['FIREBASE_PRIVATE_KEY_ID']!;
    final clientEmail = dotenv.env['FIREBASE_CLIENT_EMAIL']!;
    final projectId = dotenv.env['FIREBASE_PROJECT_ID']!;
    // Replace this with your service account credentials JSON
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": projectId,
      "private_key_id": privateKeyId,
      "private_key": privateKey.replaceAll(r'\n', '\n'),
      "client_email": clientEmail,
      "client_id": "102317355414637391256",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/craftblendserviceaccount%40craftblend-c388a.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

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

  /// Send notification to all users of a specific store
  static Future<void> sendNotificationToAllUsers(
      List<String> deviceTokens, String title, String body) async {
    final String accessToken = await getAccessToken();
    String endpointFCM =
        'https://fcm.googleapis.com/v1/projects/craftblend-c388a/messages:send';

    for (String token in deviceTokens) {
      final Map<String, dynamic> message = {
        "message": {
          "token": token,
          "notification": {"title": title, "body": body},
          "data": {"route": "storeScreen"}
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

      if (response.statusCode != 200) {
        print('Failed to send notification to $token: ${response.body}');
      }
    }

    print('Notifications sent to all users.');
  }

  static Future<void> sendNotificationToSingleRecipient(
      String deviceToken, String title, String body) async {
    await sendNotification(deviceToken, title, body);
  }

  /// Fetch device tokens for all users
  static Future<List<String>> fetchDeviceTokens() async {
    // Replace with your API endpoint to get device tokens
    const String apiUrl = getAllFMCTokens;
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token'); // Retrieve the stored token

    final response = await http.get(Uri.parse(apiUrl), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Replace with actual token
    });

    if (response.statusCode == 200) {
      print(response.body);
      List<dynamic> tokens = jsonDecode(response.body);
      return tokens.cast<String>();
    } else {
      throw Exception('Failed to fetch device tokens: ${response.body}');
    }
  }
}
