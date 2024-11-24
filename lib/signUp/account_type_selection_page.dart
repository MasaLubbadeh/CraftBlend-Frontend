import 'package:flutter/material.dart';
import 'signup.dart';
import 'store_sign_up_page.dart';

class AccountTypeSelectionPage extends StatelessWidget {
  const AccountTypeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    Color myColor = const Color(0xff456268);
    Size mediaSize = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        color: myColor,
        image: DecorationImage(
          image: const AssetImage("assets/images/craftsBackground.jpg"),
          fit: BoxFit.cover,
          colorFilter:
              ColorFilter.mode(myColor.withOpacity(0.1), BlendMode.dstATop),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Place the file.png image at the top of the Stack
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(
                  "assets/images/logoo.png", // Replace with your image path
                  height: 400, // Adjust height as needed
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Bottom section moved back with negative bottom position
            Positioned(
              bottom: -5, // Negative value to push it back
              left: -5,
              right: -5,
              child: Transform.translate(
                offset:
                    const Offset(0, 100), // Translate it downwards if needed
                child: _buildBottom(mediaSize, context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTop(Size mediaSize) {
    return SizedBox(
      width: mediaSize.width,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.card_giftcard,
              size: 60,
              color: Colors.white,
            ),
            Text(
              "CraftBlend",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 28,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottom(Size mediaSize, BuildContext context) {
    return SizedBox(
      width: mediaSize.width,
      height: mediaSize.height * 0.7,
      child: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20), // Space between the image and the title
        const Text(
          "Select Your Account Type",
          style: TextStyle(
            color: Color(0xff456268),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 40),
        _buildAccountOption(
          context,
          "User Account",
          "Personal Account",
          Icons.person,
          const Color(0xFFE3F2FD),
          const SignUpPage(),
        ),
        const SizedBox(height: 20),
        _buildAccountOption(
          context,
          "Store Account",
          "Business Account",
          Icons.store,
          const Color(0xFFF1F8E9),
          const StoreSignUpPage(),
        ),
      ],
    );
  }

  Widget _buildAccountOption(BuildContext context, String title,
      String description, IconData icon, Color color, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 60, color: const Color(0xff456268)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xff456268),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xff78909C),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
