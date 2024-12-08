////this file is to use a stream builder,it checks if the user is logged in or not

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../pages/User/login_page.dart';
import '../../pages/chatting/allChats.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            //if user is logged in
            print("logged in-auth gate");
            return AllChats();
          } else {
            //if the user is NOT logged in
            print("failed-auth gate");

            return const LoginPage();
          }
        },
      ),
    );
  }
}
