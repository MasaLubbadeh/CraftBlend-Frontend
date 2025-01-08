import 'dart:convert';
import 'package:http/http.dart' as http;

import '../configuration/config.dart';

class UserService {
  /// Fetches the user ID from the API using the provided token.
  static Future<String> fetchUserId(String token) async {
    final url = Uri.parse(getID);

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['userId'];
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch user ID');
      }
    } catch (error) {
      throw Exception('Error fetching user ID: $error');
    }
  }
}
