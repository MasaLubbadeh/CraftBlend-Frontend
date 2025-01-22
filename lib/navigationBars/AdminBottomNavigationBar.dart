import 'package:flutter/material.dart';
import '../configuration/config.dart';
import '../pages/Admin/adminStatisticsPage.dart';
import '../pages/Admin/adminDashboard.dart';
import '../pages/User/profile.dart';
import '../pages/chatting/allChats.dart';

class AdminBottomNavigationBar extends StatefulWidget {
  const AdminBottomNavigationBar({super.key});

  @override
  _AdminBottomNavigationBarState createState() =>
      _AdminBottomNavigationBarState();
}

class _AdminBottomNavigationBarState extends State<AdminBottomNavigationBar> {
  int _currentIndex = 0;

  // List of admin pages
  final List<Widget> _adminPages = [
    const AdminStatisticsPage(),
    const AdminDashboardPage(),
    const ProfileScreen(),
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
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
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
        selectedItemColor: myColor, // Color for the selected item
        unselectedItemColor: Colors.black54, // Color for unselected items
        backgroundColor: Colors.white70,
        onTap: _onItemTapped,
      ),
    );
  }
}
