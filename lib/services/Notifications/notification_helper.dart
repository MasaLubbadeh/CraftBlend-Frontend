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

    /*  const serviceAccountJson = {
      "type": "service_account",
      "project_id": "craftblend-c388a",
      "private_key_id": "35f23f77d5ed2d6abc672773aceff288a43fe738",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCvf3HgIrPFLimr\n5L5LRZox5WkCp/c9qIVHVAipDXkzj3A209Acl0g8ltlCMxEjS8hZ4aC3Z5DJ1mgX\n7+SoAzGBGjsZjxPvgZV2e8gUfDjtm5TrY+dL6KeeuuuSIGejrHkfaZikrlsUQkPq\ns2qkpexOANcpTBR2IfzS0UdfXYOdQb7n8mkSalUFTZoM3YVacUs6K0cy8e0Pl4+n\nS13EPsKdUdq5sHGwG8PozPyYgFicc05UvmMlhC9Orvu7eiFnfnM7JMKm91fTkKzS\nl3iEgv8lnHNHFwJPg5u+4S5Ym/15sDjiDmTsYP0UnVWXxWonRLrLgy8hVoWtW6ip\nkCq0U2lhAgMBAAECggEADgrolcKxF8oF05dOEr/TAsMUj/3YrrpZT8fNmZlWZWXI\n2NpCAMeqJA79+2oSqPxbX7XKImLLFxts4N11Mmxu/aGXsQfd1IBN8VkePWVjOMAG\nPn+T9mL7ZpwWVW76XAJk/rp4WFULPKfAv3rzwZD1Q5iVntxTltBJZqUQTPUyntaO\nADrYWjrJQpJ+Hbh0AS+N/ZWmTCF2s84mO7Ni+cHw5S6Op/xuoA9WdbYQRKUDKZ7a\nvBcYY7pmDkO4FKdtTyhqI42xA9D18MLlbRWbTD07K5+fMn6ylLyG2u3k1hrOf/yI\nxQaSr2UsdKbJL0LoTCIC+nx/EyD5NdubHRlPyz5fsQKBgQDUh6P2PvWH1Um4nQkw\nh7+s9k4N4oodgcU14/Bbc9y7QKXCm/mvQPOjxLqsv0d6nale6b85tAT1FROw/sNj\niYhOJXZDWZOrmE1murdGRVxDc5dRUc1IYHOv4ZC/mI4xAGrAM/d/ydDYIR3QAApv\n4z6QZ0a3YDWDSQVvOFmI9f2OowKBgQDTZMGhP3upMQDq/qRn4SpV9ZQAyz4UbDGL\nE4hgYO+qdLefgoSkiKQx2/22O8V4t2qgMIV8Ga8tTgX9lkT/jA8TgwqjKJT9k0oA\nYe48s4HCGPyZKk8kMFOBRfFY4URx7U8ysmrgKDuZcFAtOvjmZRt+VWvXppHb+wvH\nXqRUlZz8KwKBgQCwWvW1ajz3wAbyiGyNtrdY4PGYF/mfzoVE2KYkXRo2z8g8mo0v\n3efOZ3q3yemYV6epuLETQswySpESd/TObduLbQ6biIM/Cpx/uERIrVmIJyzTL9v2\nSQL2WWhxdDfZdY0ffH/NrDv+fExuwvnmKl1KGkjV9aGyFS/LQKkbO3RxnQKBgGSv\nleZmpVDFzWkgVlBAF/kPWioyo+P4UHSsngVBxoWKyDcKZIE1r/crkCFvQLQpsHiS\nA9JDLYPHqOTK4RxSqo+hl7x0xNougE3EV0PEQCah3hZZ544WEn/9P2IVEZOt803z\nWyJfJ1wC+b1BXHHocHrw1sfFR63eWhLgyiabiEU3AoGBAM5ACk0rmg1c9ZdPlAmw\niO5U5Dnn3HHKoW9IwQmSmWdpP1Sti2CrbpoubLOvHQnAaApW+Gw2beQQEigkKhtD\nIiMsIisktAk54NbTfV1FnZ/IvJGgaIpMFipVSsZRbOF7G1PO0oL0fpO4X1qXJWUa\ns9Y7Z83zi7vVPXuBLIXWbi/j\n-----END PRIVATE KEY-----\n",
      "client_email":
          "craftblendserviceaccount@craftblend-c388a.iam.gserviceaccount.com",
      "client_id": "102317355414637391256",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/craftblendserviceaccount%40craftblend-c388a.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };*/

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
