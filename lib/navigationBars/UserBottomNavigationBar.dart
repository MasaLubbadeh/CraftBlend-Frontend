import 'package:craft_blend_project/configuration/config.dart';
import 'package:craft_blend_project/pages/Posts/createPost.dart';
import 'package:flutter/material.dart';
import '../pages/User/profile.dart';
import '../pages/chatting/allChats.dart';
import '../pages/categoriesPage.dart'; // Ensure you have all pages imported

class UserBottomNavigationBar extends StatefulWidget {
  @override
  _UserBottomNavigationBarState createState() =>
      _UserBottomNavigationBarState();
}

class _UserBottomNavigationBarState extends State<UserBottomNavigationBar> {
  int _currentIndex = 0;

  // Ensure that the number of pages here matches the BottomNavigationBar items.
  final List<Widget> _userPages = [
    FeedPage(), // Home
    CreatePostPage(), // Create Post
    ProfileScreen(), // Profile
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
      body: _userPages[_currentIndex], // Display current page
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home', // This matches FeedPage()
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Create', // This matches CreatePostPage()
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile', // This matches ProfileScreen()
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat', // This matches AllChats()
          ),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: myColor, // Define `myColor` in your config
        backgroundColor: Colors.white70,
        onTap: _onItemTapped,
      ),
    );
  }
}
