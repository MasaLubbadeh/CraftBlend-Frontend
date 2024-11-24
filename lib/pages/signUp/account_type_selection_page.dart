import 'package:flutter/material.dart';
import 'signup.dart';
import 'store_sign_up_page.dart';
import '../../models/sign_up_data.dart';
import '../../configuration//config.dart';

class AccountTypeSelectionPage extends StatelessWidget {
  const AccountTypeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    //  Color myColor = const Color(0xff456268);
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
            // Top logo
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(
                  "assets/images/logoo.png",
                  height: 400,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Bottom card for account selection
            Positioned(
              bottom: -5,
              left: -5,
              right: -5,
              child: Transform.translate(
                offset: const Offset(0, 100),
                child: _buildBottom(mediaSize, context),
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
        const SizedBox(height: 20),
        const Text(
          "Select Your Account Type",
          style: TextStyle(
            color: myColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 40),
        // User Account Option
        _buildAccountOption(
          context,
          "User Account",
          "Personal Account",
          Icons.person,
          const Color.fromARGB(255, 148, 132, 160),
          "U", // Pass "U" for user account type
        ),
        const SizedBox(height: 20),
        // Store Account Option
        _buildAccountOption(
          context,
          "Store Account",
          "Business Account",
          Icons.store,
          myColor,
          "S", // Pass "S" for store account type
        ),
      ],
    );
  }

  Widget _buildAccountOption(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    String accountType, // New parameter for account type
  ) {
    return GestureDetector(
      onTap: () {
        final signUpData =
            SignUpData(accountType: accountType); // Set account type
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              if (accountType == "U") {
                print(signUpData);
                return SignUpPage(signUpData: signUpData);
              } else {
                // print("account type:");
                print(signUpData.toString());
                return StoreSignUpPage(signUpData: signUpData);
              }
            },
          ),
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
            Icon(icon, size: 60, color: Colors.white),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white,
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
