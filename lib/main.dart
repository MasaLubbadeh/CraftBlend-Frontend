import 'package:flutter/material.dart';
import 'account_type_selection_page.dart';
import 'welcome.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Account Type Selection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      //home: const AccountTypeSelectionPage(),
      home: const WelcomePage(), // Set WelcomePage as the home screen
    );
  }
}
