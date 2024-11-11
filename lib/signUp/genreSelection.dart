import 'package:flutter/material.dart';

void main() {
  runApp(GenreSelectionApp());
}

class GenreSelectionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GenreSelectionScreen(),
    );
  }
}

class GenreSelectionScreen extends StatelessWidget {
  final List<Map<String, String>> genres = [
    {'title': 'Pastries', 'image': 'assets/images/pastaries.jpg'},
    {'title': 'Pottery', 'image': 'assets/images/pottery.jpg'},
    {'title': 'Crochet', 'image': 'assets/images/crochet.png'},
    {'title': 'Build A Bear', 'image': 'assets/images/buildbear.png'},
    {'title': 'Phone Covers', 'image': 'assets/images/covers.png'},
    {'title': 'Flowers', 'image': 'assets/images/flowers.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('What are you interested in?'),
        centerTitle: true,
        backgroundColor: Color(0xff456268), // AppBar and background color
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'This will customize your new home feed',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: genres.length,
              itemBuilder: (context, index) {
                return GenreCard(
                  title: genres[index]['title']!,
                  imagePath: genres[index]['image']!,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                elevation: 20,
                shadowColor: Colors.grey,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                "Next",
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: Color(0xff456268)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GenreCard extends StatefulWidget {
  final String title;
  final String imagePath;

  GenreCard({required this.title, required this.imagePath});

  @override
  _GenreCardState createState() => _GenreCardState();
}

class _GenreCardState extends State<GenreCard> {
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isSelected = !isSelected;
        });
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                image: AssetImage(widget.imagePath),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(isSelected ? 0.5 : 0.2), // 0.2 opacity when not selected, 0.5 when selected
                  BlendMode.darken,
                ),
              ),
              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Padding to the left
              child: Align(
                alignment: Alignment.bottomLeft, // Align text to the left corner
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left, // Align text left
                ),
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}
