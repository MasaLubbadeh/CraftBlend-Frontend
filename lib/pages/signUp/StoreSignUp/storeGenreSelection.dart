import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonEncode and jsonDecode
import '../../../configuration/config.dart'; // Assuming configuration includes the registration endpoint
import '../../../models/store_sign_up_data.dart';
import '../StoreSignUp/store_signUp_addLogo.dart';
=======
import '../../../configuration/config.dart';
import '../../../models/user_sign_up_data.dart';
import '../../../models/store_sign_up_data.dart';
import '../StoreSignUp/store_sign_up_page.dart';
>>>>>>> main

class StoreGenreSelectionScreen extends StatefulWidget {
  final StoreSignUpData storeSignUpData;

  const StoreGenreSelectionScreen({super.key, required this.storeSignUpData});

  @override
  _GenreSelectionScreenState createState() => _GenreSelectionScreenState();
}

class _GenreSelectionScreenState extends State<StoreGenreSelectionScreen> {
<<<<<<< HEAD
  List<Map<String, dynamic>> genres = [];
  String? selectedGenreId; // Store the ID of the selected genre

  @override
  void initState() {
    super.initState();
    _fetchGenres();
  }

  Future<void> _fetchGenres() async {
    try {
      final response = await http.get(
        Uri.parse(getAllCategories),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> genreList = jsonDecode(response.body)['categories'];
        print("genreList");

        for (var genre in genreList) {
          print(genre);
        }

        if (mounted) {
          // Check if the widget is still mounted
          setState(() {
            genres = genreList
                .map((genre) => {
                      'id': genre['_id'],
                      'title': genre['name'],
                      'image': genre['image'] ?? '',
                    })
                .toList();
          });
        }
      } else {
        if (mounted) {
          // Check if the widget is still mounted
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to fetch categories: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Check if the widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred: $e')),
        );
      }
    }
  }

  void onNextPressed() {
    if (selectedGenreId != null) {
      // Update the StoreSignUpData with the selected genre ID
      widget.storeSignUpData.selectedGenreId = selectedGenreId;

      // Navigate to the logo upload page
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StoreSignUpLogoPage(
            storeSignUpData: widget.storeSignUpData,
          ),
=======
  final List<Map<String, String>> genres = [
    {'title': 'Pastries', 'image': 'assets/images/pastaries.jpg'},
    {'title': 'Pottery', 'image': 'assets/images/pottery.jpg'},
    {'title': 'Crochet', 'image': 'assets/images/crochet.png'},
    {'title': 'Build A Bear', 'image': 'assets/images/buildbear.png'},
    {'title': 'Phone Covers', 'image': 'assets/images/covers.png'},
    {'title': 'Flowers', 'image': 'assets/images/flowers.png'},
  ];

  String? selectedGenre;

  void onNextPressed() {
    if (selectedGenre != null) {
      // Update the SignUpData with the selected genre
      widget.storeSignUpData.selectedGenre = selectedGenre;
      print(widget.storeSignUpData.toString());
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              StoreSignUpPage(SignUpData: widget.storeSignUpData),
>>>>>>> main
        ),
      );
    } else {
      // Show a message if no genre is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a genre for your store!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'Select your store genre',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
=======
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Your Store Genre',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: myColor,
        foregroundColor: Colors.white,
        elevation: 0,
>>>>>>> main
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
<<<<<<< HEAD
              'You must select a genre for your store',
=======
              'You must select a genre for you store',
>>>>>>> main
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
<<<<<<< HEAD
            child: genres.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: genres.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedGenreId = genres[index]['id'];
                          });
                        },
                        child: GenreCard(
                          title: genres[index]['title'],
                          imagePath: genres[index]['image'],
                          isSelected: selectedGenreId == genres[index]['id'],
                        ),
                      );
                    },
                  ),
=======
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: genres.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedGenre = genres[index]['title'];
                    });
                  },
                  child: GenreCard(
                    title: genres[index]['title']!,
                    imagePath: genres[index]['image']!,
                    isSelected: selectedGenre == genres[index]['title'],
                  ),
                );
              },
            ),
>>>>>>> main
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: onNextPressed,
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                "Next",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GenreCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool isSelected;

  const GenreCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
<<<<<<< HEAD
            image: imagePath.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(imagePath),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(isSelected ? 0.5 : 0.2),
                      BlendMode.darken,
                    ),
                  )
                : null, // No image decoration if imagePath is empty
=======
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(isSelected ? 0.5 : 0.2),
                BlendMode.darken,
              ),
            ),
>>>>>>> main
            border:
                isSelected ? Border.all(color: Colors.white, width: 3) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                title,
<<<<<<< HEAD
                style: TextStyle(
                  color: isSelected ? Colors.grey : Colors.white,
=======
                style: const TextStyle(
                  color: Colors.white,
>>>>>>> main
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        if (isSelected)
          const Positioned(
            top: 8,
            right: 8,
            child: Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
          ),
      ],
    );
  }
}
<<<<<<< HEAD
=======

class NextSignUpScreen extends StatelessWidget {
  final StoreSignUpData signUpData;

  const NextSignUpScreen({super.key, required this.signUpData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Next Signup Step'),
      ),
      body: Center(
        child: Text(
          'SignUpData: ${signUpData.toString()}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
>>>>>>> main
