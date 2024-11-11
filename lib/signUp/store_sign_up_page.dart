import 'package:flutter/material.dart';

class StoreSignUpPage extends StatelessWidget {
  const StoreSignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    Color myColor = const Color(0xff456268);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage("images/craftsBackground.jpg"),
            fit: BoxFit.cover,
            colorFilter:
                ColorFilter.mode(myColor.withOpacity(0.5), BlendMode.dstATop),
          ),
        ),
        child: Center(
          child: Text(
            "Store Sign Up Page",
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      ),
    );
  }
}
