import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON encoding/decoding
import '../../configuration/config.dart';
import 'profile.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late Size mediaSize;
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController repeatPasswordController = TextEditingController();
  bool isOldPasswordVisible = false;
  bool isPasswordVisible = false;
  bool isRepeatPasswordVisible = false;
  String errorMessage = ""; // For displaying errors

  @override
  void initState() {
    super.initState();
  }

  void _resetPassword() async {
    setState(() {
      errorMessage = ""; // Reset the error message
    });

    if (oldPasswordController.text.isEmpty ||
        passwordController.text.isEmpty ||
        repeatPasswordController.text.isEmpty) {
      setState(() {
        errorMessage = "All password fields are required.";
      });
      return;
    } else if (passwordController.text != repeatPasswordController.text) {
      setState(() {
        errorMessage = "Passwords do not match.";
      });
      return;
    }

    // Proceed with password reset logic here
    final String oldPassword = oldPasswordController.text;
    final String newPassword = passwordController.text;
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token'); // Retrieve the stored token

    try {
      final response = await http.post(
        Uri.parse(resetPassword),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your password was changed successfully.'),
          ),
        );

        print("Password reset successful: ${response.body}");
      } else {
        setState(() {
          errorMessage = "Failed to reset password. Please try again.";
        });
        print("Failed to reset password: ${response.body}");
      }
    } catch (error) {
      setState(() {
        errorMessage = "An error occurred: $error";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;
    mediaSize = MediaQuery.of(context).size; // Get the media size
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [myColor.withOpacity(0.9), Colors.blueGrey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: DecorationImage(
          image: const AssetImage("assets/images/craftsBackground.jpg"),
          fit: BoxFit.cover,
          colorFilter:
              ColorFilter.mode(myColor.withOpacity(0.05), BlendMode.dstATop),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: myColor,
          elevation: 0,
          toolbarHeight: appBarHeight,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Colors.white70,
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: mediaSize.width * 0.07,
            vertical: mediaSize.height * 0.05,
          ),
          child: Column(
            children: [
              _buildTop(),
              const SizedBox(height: 20),
              Text(
                "To reset your password, please enter your old password followed by your new password.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: mediaSize.width * 0.04,
                  fontWeight: FontWeight.w400,
                  letterSpacing: .35,
                ),
              ),
              const SizedBox(height: 20),
              _buildPasswordContainer(),
            ],
          ),
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
            "",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: mediaSize.width * 0.05,
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
        ],
      ),
    );
  }

  Widget _buildPasswordContainer() {
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
          _buildPasswordField(
            "Old Password",
            oldPasswordController,
            isOldPasswordVisible,
            () {
              setState(() {
                isOldPasswordVisible = !isOldPasswordVisible;
              });
            },
          ),
          const SizedBox(height: 20),
          _buildPasswordField(
            "New Password",
            passwordController,
            isPasswordVisible,
            () {
              setState(() {
                isPasswordVisible = !isPasswordVisible;
              });
            },
          ),
          const SizedBox(height: 20),
          _buildPasswordField(
            "Repeat New Password",
            repeatPasswordController,
            isRepeatPasswordVisible,
            () {
              setState(() {
                isRepeatPasswordVisible = !isRepeatPasswordVisible;
              });
            },
          ),
          const SizedBox(height: 10),
          if (errorMessage.isNotEmpty)
            Text(
              errorMessage,
              style: TextStyle(color: Colors.red.shade700),
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
              onPressed: _resetPassword,
              child: const Text(
                "Update Password",
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

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool isVisible,
    VoidCallback toggleVisibility,
  ) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade700),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade500, width: 1.5),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade500, width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: myColor, width: 2.0),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey.shade700,
          ),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }
}
