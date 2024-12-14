import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';
import '../pages/User/profile.dart';
import '../pages/chatting/allChats.dart';
import '../pages/categoriesPage.dart';
import '../pages/cart_checkout_pages/cart_page.dart';

class UserBottomNavigationBar extends StatefulWidget {
  const UserBottomNavigationBar({super.key});

  @override
  _UserBottomNavigationBarState createState() =>
      _UserBottomNavigationBarState();
}

class _UserBottomNavigationBarState extends State<UserBottomNavigationBar> {
  int _currentIndex = 0;

  // Updated _userPages to include the callback for CartPage
  late final List<Widget> _userPages;

  @override
  void initState() {
    super.initState();
    _userPages = [
      CategoriesPage(), // Home
      const ProfileScreen(), // Profile
      CartPage(onTabChange: _onItemTapped), // Cart with callback
      AllChats(), // Chat
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _userPages[_currentIndex], // Display the current page
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: myColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white70,
        onTap: _onItemTapped,
      ),
    );
  }
}
