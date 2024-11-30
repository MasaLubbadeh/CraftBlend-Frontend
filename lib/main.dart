import 'package:craft_blend_project/services/authentication/auth_gate.dart';

import '../pages/chatting/allChats.dart';
import 'package:flutter/material.dart';
import 'pages/User/login_page.dart'; // Adjust the path to your LoginPage
import 'pages/User/profile.dart';
import 'configuration/config.dart';
import 'pages/User/editProfile.dart';
import 'pages/User/addCard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/Product/Pastry/pastryUser_page.dart';
import 'pages/Product/Pastry/pastryOwner_page.dart';
import 'pages/specialOrders/specialOrder_page.dart';
import 'pages/welcome.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Your App Name',
      theme: ThemeData(
        dialogTheme: DialogTheme(
          backgroundColor: Colors.white,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: const TextStyle(
            color: myColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          contentTextStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthGate(), // Start with MainScreen
    );
  }
}

// MainScreen handles the navigation and login state
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Define the pages for the bottom navigation bar
  final List<Widget> _pages = [
    const LoginPage(), // Login screen (shown if not logged in)
    const EditProfile(), // Orders screen
    const ProfileScreen(), // Profile screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoggedIn
          ? _pages[_selectedIndex] // Show bottom nav content if logged in
          : const LoginPage(), // Show login page if not logged in

      // Add BottomNavigationBar only if the user is logged in
      bottomNavigationBar: isLoggedIn
          ? BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart),
                  label: 'Orders',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.blue,
              onTap: _onItemTapped,
            )
          : null, // Don't show BottomNavigationBar if not logged in
    );
  }
}
