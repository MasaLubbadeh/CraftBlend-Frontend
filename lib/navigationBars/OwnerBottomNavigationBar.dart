import 'dart:convert';

import 'dart:convert';

import 'package:craft_blend_project/configuration/config.dart';
import 'package:craft_blend_project/pages/Store/storeOrders_page.dart';
import 'package:craft_blend_project/pages/User/profile.dart';
import 'package:craft_blend_project/services/userServices.dart';
import 'package:craft_blend_project/services/userServices.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/Store/Profile/storeProfile.dart';
import '../pages/Feed/feedPage.dart';
//import '../pages/specialOrders/specialOrder_page.dart';
import '../pages/Product/Pastry/pastryOwner_page.dart';
import '../pages/chatting/allChats.dart';
import '../pages/Store/Profile/storeProfile_page.dart';
import '../pages/Store/Profile/storeProfile_page.dart';

class OwnerBottomNavigationBar extends StatefulWidget {
  const OwnerBottomNavigationBar({super.key});

  @override
  _OwnerBottomNavigationBarState createState() =>
      _OwnerBottomNavigationBarState();
}

class _OwnerBottomNavigationBarState extends State<OwnerBottomNavigationBar> {
  int _currentIndex = 0;
  String? userID; // Make it nullable
  bool isLoading = true; // Track loading state
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    print("inside initstate of navbar");
    _getUserId(); // Fetch the user ID when the widget is initialized
  }

  Future<void> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token'); // Retrieve the stored token
    print("this is the token:");
    print(jsonEncode(token));
    try {
      final String id = await UserService.fetchUserId(token!);
      print("this is the store id nav bar");
      print(id);
      setState(() {
        userID = id;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Handle loading state
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Handle error state
    if (errorMessage != null) {
      return Scaffold(
        body: Center(child: Text('Error: $errorMessage')),
      );
    }
    print("hheeelllllololo");
    print(userID);
    // List of pages with userID dynamically added
    final List<Widget> _ownerPages = [
      const PastryOwnerPage(), // Manage Store
      FeedPage(), // Feed
      StoreProfilePage(userID: userID!),
      // Profile Page
      AllChats(), // Chat
    ];

    return Scaffold(
      body: _ownerPages[_currentIndex], // Display the current page
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting, // Enable shifting behavior
        currentIndex: _currentIndex,
        selectedItemColor: myColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Manage Store',
            backgroundColor: Colors.white, // Background for this tab
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Orders',
            backgroundColor: Colors.white, // Background for this tab
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
            backgroundColor: Colors.white, // Background for this tab
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
            backgroundColor: Colors.white, // Background for this tab
          ),
        ],
      ),
    );
  }
}
