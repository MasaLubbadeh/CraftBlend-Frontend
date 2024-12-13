import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';
import '../pages/User/profile.dart';
import '../pages/chatting/allChats.dart';
import '../pages/categoriesPage.dart';

class UserBottomNavigationBar extends StatefulWidget {
  @override
  _UserBottomNavigationBarState createState() =>
      _UserBottomNavigationBarState();
}

class _UserBottomNavigationBarState extends State<UserBottomNavigationBar> {
  int _currentIndex = 0;
  final List<Widget> _userPages = [
    // WelcomePage(), // Home
    // OrdersPage(), // Orders
    CategoriesPage(),
    ProfileScreen(), // Profile
    AllChats(),

    // FeedPage(), // Feed
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _userPages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          /*
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          */
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: myColor,
        backgroundColor: Colors.white70,
        onTap: _onItemTapped,
      ),
    );
  }
}
