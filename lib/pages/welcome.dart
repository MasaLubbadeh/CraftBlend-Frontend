<<<<<<< HEAD
import 'package:craft_blend_project/pages/User/login_page.dart';
import 'package:craft_blend_project/services/Notifications/notification_helper.dart';
import 'package:craft_blend_project/services/authentication/auth_gate.dart';
import 'package:flutter/material.dart';
import '../configuration/config.dart';
=======
import 'package:flutter/material.dart';
import '../configuration/config.dart';
import 'signUp/account_type_selection_page.dart';
>>>>>>> main

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),

          // Title
          /*   const Text(
            "Welcome to",
            style: TextStyle(
              fontSize: 24,
             // fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),*/
          Image.asset(
            "assets/images/welcome1.png", // Replace with your image asset
            height: 100, // Adjust height as needed
            fit: BoxFit.contain,
          ),
          //  const SizedBox(height: 20),

          // Centered Illustration
          Image.asset(
            "assets/images/logoBlack.png", // Replace with your image asset
            height: 350, // Adjust height as needed
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 0),

          // Privacy Policy Text
<<<<<<< HEAD
          /*  const Padding(
=======
          const Padding(
>>>>>>> main
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              "Read our Privacy Policy. Tap Agree and Continue to accept the Terms of Services.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
<<<<<<< HEAD
          
          */
=======
>>>>>>> main
          const Spacer(),

          // "Agree & Continue" Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
<<<<<<< HEAD
              onPressed: () async {
                // Navigate to the next page or perform any action
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
=======
              onPressed: () {
                // Navigate to the next page or perform any action
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AccountTypeSelectionPage(),
>>>>>>> main
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: myColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
<<<<<<< HEAD
                    "Continue",
=======
                    "Agree & Continue",
>>>>>>> main
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
<<<<<<< HEAD
                      letterSpacing: 3,
=======
>>>>>>> main
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
