import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/Feed/favoritesPage.dart';
import '../pages/Feed/popularPosts.dart';

class MyAppBar extends StatefulWidget implements PreferredSizeWidget {
  const MyAppBar({Key? key}) : super(key: key);

  @override
  _MyAppBarState createState() => _MyAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _MyAppBarState extends State<MyAppBar> {
  String selectedItem = 'CraftBlend';
  bool isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: myColor, // Replace with your desired color
      elevation: 4,
      title: PopupMenuButton<String>(
        onSelected: (value) async {
          final SharedPreferences prefs = await SharedPreferences.getInstance();

          setState(() {
            selectedItem = value;
            prefs.setString('selectedItem', selectedItem);
          });
          if (value == 'Profile') {
            // Navigate to Profile
          } else if (value == 'Settings') {
            // Handle settings logic
          } else if (value == 'Favorites') {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => FavoritesPage()), // Adjust as needed
            );
            Navigator.pop(context);
          } else if (value == 'Popular') {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PopularPostsPage()), // Adjust as needed
            );
            Navigator.pop(context);
          }
        },
        onCanceled: () {
          setState(() {
            isMenuOpen = false;
          });
        },
        onOpened: () {
          setState(() {
            isMenuOpen = true;
          });
        },
        offset: const Offset(-5, 35),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedItem,
              style: const TextStyle(
                fontFamily: 'Pacifico',
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 5),
            AnimatedRotation(
              turns: isMenuOpen ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
              ),
            ),
          ],
        ),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            value: 'CraftBlend',
            child: Container(
              color: selectedItem == 'CraftBlend'
                  ? const Color.fromARGB(255, 219, 219, 219)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Row(
                children: [
                  Icon(Icons.home_rounded, color: Colors.black),
                  SizedBox(width: 15),
                  Text('Home'),
                ],
              ),
            ),
          ),
          PopupMenuItem<String>(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            value: 'Popular',
            child: Container(
              color: selectedItem == 'Popular'
                  ? const Color.fromARGB(255, 219, 219, 219)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Row(
                children: [
                  Icon(Icons.arrow_upward_rounded, color: Colors.black),
                  SizedBox(width: 15),
                  Text('Popular'),
                ],
              ),
            ),
          ),
          PopupMenuItem<String>(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            value: 'Favorites',
            child: Container(
              color: selectedItem == 'Favorites'
                  ? const Color.fromARGB(255, 219, 219, 219)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Row(
                children: [
                  Icon(Icons.favorite_sharp, color: Colors.black),
                  SizedBox(width: 15),
                  Text('Favorites'),
                ],
              ),
            ),
          ),
          PopupMenuItem<String>(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            value: 'Recents',
            child: Container(
              color: selectedItem == 'Recents'
                  ? const Color.fromARGB(255, 219, 219, 219)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Row(
                children: [
                  Icon(Icons.new_releases_rounded, color: Colors.black),
                  SizedBox(width: 15),
                  Text('Recents'),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          color: Colors.white,
          icon: const Icon(Icons.add),
          onPressed: () {
            // Handle button press
          },
        ),
      ],
    );
  }
}
