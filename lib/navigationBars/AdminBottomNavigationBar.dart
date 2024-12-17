import 'package:flutter/material.dart';
import '../pages/Admin/adminDashboard.dart';
import '../pages/Admin/adminManageStores.dart';
import '../pages/chatting/allChats.dart';
//import '../pages/Admin/manageUsers.dart';
//import '../pages/Admin/manageStores.dart';

class AdminBottomNavigationBar extends StatefulWidget {
  const AdminBottomNavigationBar({super.key});

  @override
  _AdminBottomNavigationBarState createState() =>
      _AdminBottomNavigationBarState();
}

class _AdminBottomNavigationBarState extends State<AdminBottomNavigationBar> {
  int _currentIndex = 0;

  // List of pages corresponding to the bottom navigation items
  final List<Widget> _adminPages = [
    const AdminDashboardPage(), // Admin Dashboard
    //ManageUsersPage(), // Manage Users
    const AdminManageStoresPage(), // Manage Stores
    AllChats(),
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
          /* BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Manage Users',
          ),*/
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Manage Stores',
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
