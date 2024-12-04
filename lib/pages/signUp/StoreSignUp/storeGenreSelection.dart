import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonEncode and jsonDecode
import '../../../configuration/config.dart'; // Assuming configuration includes the registration endpoint
import '../../../models/store_sign_up_data.dart';
import '../StoreSignUp/store_sign_up_page.dart';

class StoreGenreSelectionScreen extends StatefulWidget {
  final StoreSignUpData storeSignUpData;

  const StoreGenreSelectionScreen({super.key, required this.storeSignUpData});

  @override
  _GenreSelectionScreenState createState() => _GenreSelectionScreenState();
}

class _GenreSelectionScreenState extends State<StoreGenreSelectionScreen> {
  List<Map<String, dynamic>> genres = [];
  String? selectedGenreId; // Store the ID of the selected genre

  @override
  void initState() {
    super.initState();
    _fetchGenres();
  }

  // Function to fetch genres from the backend
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
        setState(() {
          genres = genreList
              .map((genre) => {
                    'id': genre['_id'], // Assuming the category ID is `_id`
                    'title': genre['name'],
                    'image':
                        genre['image'] ?? '', // Use the photo URL from backend
                  })
              .toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to fetch categories: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred: $e')),
      );
    }
  }

  void onNextPressed() {
    if (selectedGenreId != null) {
      // Update the StoreSignUpData with the selected genre ID
      widget.storeSignUpData.selectedGenreId = selectedGenreId;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              StoreSignUpPage(SignUpData: widget.storeSignUpData),
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
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'You must select a genre for your store',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
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
            border:
                isSelected ? Border.all(color: Colors.white, width: 3) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.grey : Colors.white,
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
