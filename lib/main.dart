import "configuration/config.dart";
import 'pages/User/profile.dart';
import 'pages/signUp/UserSignUp/profilePageState.dart';
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
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'pages/googleMapsPage.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //await FirebaseAppCheck.instance.activate(androidProvider: null);
  // Disable App Check for development
  /*await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );*/
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
        dialogTheme: const DialogTheme(
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: myColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: TextStyle(
            color: Colors.black38,
            fontSize: 16,
          ),
        ),
      ),
      home:
          const WelcomePage(), //MapPage(), //WelcomePage(), //MapPage(), // // Start with WelcomePage WelcomePage(), //
    );
  }
}

class MainPage extends StatelessWidget {
  final bool isOwner; // Determined after login

  const MainPage({super.key, required this.isOwner});

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
