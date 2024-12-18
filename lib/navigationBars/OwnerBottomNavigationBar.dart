import 'package:craft_blend_project/configuration/config.dart';
import 'package:craft_blend_project/pages/Store/orders_page.dart';
import 'package:craft_blend_project/pages/User/profile.dart';
import 'package:flutter/material.dart';
import '../pages/Store/specialOrders/specialOrder_page.dart';
import '../pages/Product/Pastry/pastryOwner_page.dart';
import '../pages/chatting/allChats.dart';
import '../pages/Store/storeProfile_page.dart';

class OwnerBottomNavigationBar extends StatefulWidget {
  const OwnerBottomNavigationBar({super.key});

  @override
  _OwnerBottomNavigationBarState createState() =>
      _OwnerBottomNavigationBarState();
}

class _OwnerBottomNavigationBarState extends State<OwnerBottomNavigationBar> {
  int _currentIndex = 0;

  final List<Widget> _ownerPages = [
    const PastryOwnerPage(), // Manage Store
    // const SpecialOrdersPage(), // Orders
    const StoreOrdersPage(),
    const StoreProfileScreen(), // Profile
    AllChats(), // Chat
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
