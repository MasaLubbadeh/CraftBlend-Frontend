import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For jsonEncode and jsonDecode
import '../../../configuration/config.dart'; // Assuming configuration includes the registration endpoint
import '../../../models/store_sign_up_data.dart';
import '../StoreSignUp/store_signUp_addLogo.dart';

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

  void _showSuggestionForm(BuildContext context) {
    // Declare controllers outside the builder to retain their state
    final TextEditingController categoryController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String? errorMessage; // Error message for category validation

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Suggest a New Category",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: myColor,
                        letterSpacing: 1),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: categoryController,
                    decoration: InputDecoration(
                      labelText: "Category Name",
                      border: const OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(10.0))),
                      errorText: errorMessage, // Show the error message
                    ),
                    onChanged: (_) {
                      setState(() {
                        errorMessage = null; // Clear error on input
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText:
                          "Why should we add this category?\n (Optional)",
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(10.0))),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the modal
                        },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: myColor),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final category = categoryController.text.trim();
                          final description = descriptionController.text.trim();

                          if (category.isEmpty) {
                            setState(() {
                              errorMessage = "Category name cannot be empty.";
                            });
                            return;
                          }

                          _submitCategorySuggestion(
                              category, description); // Submit the suggestion
                          Navigator.pop(context); // Close the modal
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: myColor, // Set the background color
                          foregroundColor: Colors.white, // Set the text color
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12), // Optional padding
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                30), // Optional rounded corners
                          ),
                        ),
                        child: const Text(
                          "Submit",
                          style: TextStyle(
                              fontWeight:
                                  FontWeight.bold), // Additional text styling
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitCategorySuggestion(
      String category, String description) async {
    try {
      final response = await http.post(
        Uri.parse(submitNewSuggestionByStore),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode({
          "categoryName": category, // Correct key
          "description": description,
          "userType": 'Store', // Assuming UserType is 'User'
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Suggestion submitted successfully!")),
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? "Failed to submit suggestion.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
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
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: Colors.white70),
            tooltip: "Suggest a Category",
            onPressed: () {
              _showSuggestionForm(context); // Open suggestion form
            },
          ),
        ],
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
