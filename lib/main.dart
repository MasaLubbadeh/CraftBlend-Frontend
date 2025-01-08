import 'package:craft_blend_project/pages/Home_page.dart';

import "configuration/config.dart";
import 'pages/User/profile.dart';
import 'pages/signUp/UserSignUp/profilePageState.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/User/login_page.dart';
import 'pages/welcome.dart';
import 'pages/Product/Pastry/pastryUser_page.dart';
import 'pages/Product/Pastry/pastryOwner_page.dart';
import 'pages/Store/specialOrders/specialOrder_page.dart';
import 'navigationBars/OwnerBottomNavigationBar.dart';
import 'navigationBars/UserBottomNavigationBar.dart';
import 'navigationBars/AdminBottomNavigationBar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'pages/googleMapsPage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
////////Notifications
//import 'services/Notifications/notify_testPage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

// Notification channel constants
const String channelId = 'default_notification_channel';
const String channelName = 'General Notifications';
const String channelDescription = 'This channel is for general notifications.';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingForegroundHandler(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = notification?.android;

  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

// Function to show local notification
void _showNotification(RemoteMessage message) async {
  AndroidNotificationDetails androidPlatformChannelSpecifics =
      const AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: channelDescription,
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title,
    message.notification?.body,
    platformChannelSpecifics,
  );
}

// Background message handler
Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  if (message.notification != null) {
    flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

// Request notification permissions for Android 13+
void requestNotificationPermissions() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Create notification channel
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
      ));

  // Firebase messaging setup
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  FirebaseMessaging.onMessage.listen(_firebaseMessagingForegroundHandler);
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);

  // Print FCM token for testing
  String? tokenn = await messaging.getToken();
  print("FCM Token: $tokenn");

  // Request permissions
  requestNotificationPermissions();

  await dotenv.load(fileName: "assets/.env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Craft Blend',
        initialRoute: '/welcome',
        routes: {
          '/welcome': (context) => const WelcomePage(),
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
          '/map': (context) => const MapPage(),
          '/userNavBar': (context) =>
              const UserBottomNavigationBar(), // Add this
        },
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const WelcomePage());
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
