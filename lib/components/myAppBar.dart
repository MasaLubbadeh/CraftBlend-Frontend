import 'package:flutter/material.dart';
import 'package:craft_blend_project/configuration/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/Feed/favoritesPage.dart';
import '../pages/Feed/popularPosts.dart';

class MyAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Function(String) onItemSelected;

  const MyAppBar({required this.onItemSelected});

  @override
  _MyAppBarState createState() => _MyAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(
        WidgetsBinding.instance.window.physicalSize.height *
            0.1 /
            WidgetsBinding.instance.window.devicePixelRatio,
      );
}

class _MyAppBarState extends State<MyAppBar> {
  String selectedItem = 'CraftBlend'; // Default item
  bool isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedItem();
  }

  void _loadSelectedItem() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedItem = prefs.getString('selectedItem') ?? 'CraftBlend';
    });
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return AppBar(
      backgroundColor: myColor,
      elevation: 4,
      toolbarHeight: appBarHeight,
      automaticallyImplyLeading: false,
      title: PopupMenuButton<String>(
        onSelected: (value) async {
          final SharedPreferences prefs = await SharedPreferences.getInstance();

          setState(() {
            selectedItem = value;
            prefs.setString('selectedItem', selectedItem);
          });

          // Call the parent widget's callback with the selected item
          widget.onItemSelected(selectedItem);
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
                fontSize: 26,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 5),
            AnimatedRotation(
              turns: isMenuOpen ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white70,
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
          color: Colors.white70,
          icon: const Icon(Icons.add),
          onPressed: () {
            // Handle button press
          },
        ),
      ],
    );
  }
}
