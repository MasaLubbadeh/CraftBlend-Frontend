import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';
import '../pages/Admin/adminDashboard.dart';
//import '../pages/Admin/manageUsers.dart';
//import '../pages/Admin/manageStores.dart';

class AdminBottomNavigationBar extends StatefulWidget {
  @override
  _AdminBottomNavigationBarState createState() =>
      _AdminBottomNavigationBarState();
}

class _AdminBottomNavigationBarState extends State<AdminBottomNavigationBar> {
  int _currentIndex = 0;

  // List of pages corresponding to the bottom navigation items
  final List<Widget> _adminPages = [
    AdminDashboardPage(), // Admin Dashboard
    //ManageUsersPage(), // Manage Users
    //ManageStoresPage(), // Manage Stores
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _adminPages[_currentIndex], // Display the current page
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Manage Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Manage Stores',
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
