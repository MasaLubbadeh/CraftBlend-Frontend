import 'package:flutter/material.dart';
import 'signUp/account_type_selection_page.dart';

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
          const Padding(
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
          const Spacer(),

          // "Agree & Continue" Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Navigate to the next page or perform any action
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AccountTypeSelectionPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF007BFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Agree & Continue",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
