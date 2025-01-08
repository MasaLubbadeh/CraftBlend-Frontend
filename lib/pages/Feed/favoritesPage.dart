import 'package:craft_blend_project/components/myAppBar.dart';
import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MyAppBar(),
      body: Center(
        child: Text(
          'This is the Favorites page for testing.',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
