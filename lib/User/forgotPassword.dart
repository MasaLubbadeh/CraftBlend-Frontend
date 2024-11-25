import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile.dart';
import '../config.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late Size mediaSize;
  late SharedPreferences prefs;
  TextEditingController emailController = TextEditingController();
  String errorMessage = ""; // For displaying errors

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    mediaSize = MediaQuery.of(context).size; // Get the media size
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [myColor.withOpacity(0.9), Colors.blueGrey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: DecorationImage(
          image: const AssetImage("images/craftsBackground.jpg"),
          fit: BoxFit.cover,
          colorFilter:
              ColorFilter.mode(myColor.withOpacity(0.05), BlendMode.dstATop),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned(top: 80, child: _buildTop()),
            Positioned(
              top: mediaSize.height * 0.45,
              left: mediaSize.width * 0.1,
              right: mediaSize.width * 0.1,
              child: _buildEmailContainer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTop() {
    return SizedBox(
      width: mediaSize.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock,
            size: mediaSize.width * 0.20,
            color: Colors.white,
          ),
          Text(
            "Password Reset",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: mediaSize.width * 0.09,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          Container(
            width: mediaSize.width * 0.8,
            margin: const EdgeInsets.only(top: 10),
            child: Text(
              "Please enter your email to recieve a reset email to create a new password",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w400,
                fontSize: mediaSize.width * 0.04,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailContainer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.8),
            Colors.white.withOpacity(0.4)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              hintText: "Enter your email",
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.transparent, // Make the background transparent
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade500, width: 1.5),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade500, width: 1.5),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                    color: myColor, width: 2.0), // Accent color on focus
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
                backgroundColor: myColor,
                shadowColor: Colors.black.withOpacity(0.2),
              ),
              onPressed: _sendResetEmail,
              child: const Text(
                "Send",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

/////////////////////////////////////////////////
  void _sendResetEmail() async {
    final email = emailController.text;
    print("Send reset email to: $email");

    try {
      final response = await http.post(
        Uri.parse(forgotPassword), // Replace with your actual backend URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        // Success: Navigate to ResetPasswordPage or show success message
        print("Temporary password sent to email.");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      } else {
        // Error handling based on response status code
        print("Failed to send reset email: ${response.body}");
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content:
                const Text("Failed to send reset email. Please try again."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      print("Error: $error");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: const Text("An error occurred. Please try again."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }
}
