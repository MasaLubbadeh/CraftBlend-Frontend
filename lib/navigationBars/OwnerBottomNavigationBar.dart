import 'package:craft_blend_project/configuration/config.dart';
import 'package:craft_blend_project/pages/User/profile.dart';
import 'package:flutter/material.dart';
import '../pages/specialOrders/specialOrder_page.dart';
import '../pages/Product/Pastry/pastryOwner_page.dart';

class OwnerBottomNavigationBar extends StatefulWidget {
  @override
  _OwnerBottomNavigationBarState createState() =>
      _OwnerBottomNavigationBarState();
}

class _OwnerBottomNavigationBarState extends State<OwnerBottomNavigationBar> {
  int _currentIndex = 0;

  // List of pages corresponding to the bottom navigation items
  final List<Widget> _ownerPages = [
    PastryOwnerPage(), // Manage Store
    SpecialOrdersPage(),
    ProfileScreen(), // Special Orders
    //add more
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Manage Store',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Special Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        //add here too
        currentIndex: _currentIndex,
        selectedItemColor: myColor,
        backgroundColor: Colors.white70,
        onTap: _onItemTapped,
      ),
    );
  }
}
