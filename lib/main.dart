import 'package:craft_blend_project/configuration/config.dart';
import 'package:craft_blend_project/pages/User/profile.dart';
import 'package:craft_blend_project/pages/signUp/UserSignUp/profilePageState.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/User/login_page.dart';
import 'pages/welcome.dart';
import 'pages/Product/Pastry/pastryUser_page.dart';
import 'pages/Product/Pastry/pastryOwner_page.dart';
import 'pages/specialOrders/specialOrder_page.dart';
import 'navigationBars/OwnerBottomNavigationBar.dart';
import 'navigationBars/UserBottomNavigationBar.dart';
import 'navigationBars/AdminBottomNavigationBar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
      title: 'Craft Blend',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WelcomePage(), // Start with WelcomePage
    );
  }
}

class MainPage extends StatelessWidget {
  final bool isOwner; // Determined after login

  MainPage({required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return isOwner
        ? OwnerBottomNavigationBar() // Owner navigation with stateful page management
        : UserBottomNavigationBar(); // User navigation with stateful page management
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isLoggedIn = false;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  void checkLoginStatus() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getString('token') != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return const LoginPage(); // Show login if not logged in
    } else {
      String? userType = prefs.getString('userType');
      if (userType == 'store') {
        return OwnerBottomNavigationBar();
      } else if (userType == 'user') {
        return UserBottomNavigationBar();
      } else {
        return AdminBottomNavigationBar();
      }
    }
  }
}
