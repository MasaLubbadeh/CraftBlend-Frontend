import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'profilePageState.dart'; // Assuming ProfilePage exists
import '../../../configuration/config.dart'; // Assuming configuration includes the registration endpoint
import '../../../models/user_sign_up_data.dart';
import '../../../main.dart';
import '../../../services/authentication/auth_service.dart';

class GenreSelectionApp extends StatelessWidget {
  final SignUpData signUpData;

  const GenreSelectionApp({super.key, required this.signUpData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GenreSelectionScreen(signUpData: signUpData),
    );
  }
}

class GenreSelectionScreen extends StatefulWidget {
  final SignUpData signUpData;

  const GenreSelectionScreen({super.key, required this.signUpData});

  @override
  _GenreSelectionScreenState createState() => _GenreSelectionScreenState();
}

class _GenreSelectionScreenState extends State<GenreSelectionScreen> {
  List<Map<String, dynamic>> genres =
      []; // Update type to dynamic to handle various types
  List<String> selectedGenres = [];

  @override
  void initState() {
    super.initState();
    _fetchGenres();
  }

  Future<void> _fetchGenres() async {
    try {
      final response = await http.get(
        Uri.parse(
            getAllCategories), // Use the correct endpoint to get all categories
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> genreList = jsonDecode(response.body)['categories'];
        setState(() {
          genres = genreList
              .map((genre) => {
                    'title': genre['name'] as String,
                    'image': genre[
                        'image'], // Use photo URL directly from the backend
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

  // Function to register user
  void registerUser() async {
    if (widget.signUpData.firstName != null &&
        widget.signUpData.lastName != null &&
        widget.signUpData.email != null &&
        widget.signUpData.phoneNumber != null &&
        widget.signUpData.password != null &&
        selectedGenres.isNotEmpty) {
      // Prepare request body using SignUpData model
      var regbody = {
        "firstName": widget.signUpData.firstName,
        "lastName": widget.signUpData.lastName,
        "email": widget.signUpData.email,
        "phoneNumber": widget.signUpData.phoneNumber,
        "password": widget.signUpData.password,
        "accountType": widget.signUpData.accountType,
        "selectedGenres": selectedGenres,
      };

      // Send data to the server
      var response = await http.post(
        Uri.parse(registration), // Use your registration endpoint here
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(regbody),
      );

      // Handle server response
      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == "success" ||
            jsonResponse['status'] == 201 ||
            jsonResponse['status'] == true) {
          print("Registration successful!");
          final auth = AuthService();
          auth.signUpWithEmailPassword(
            widget.signUpData.email!,
            widget.signUpData.password!,
            widget.signUpData.firstName!,
            widget.signUpData.lastName!,
          );
          // Save token and user type to SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('token', jsonResponse['token']);
          prefs.setString('userType', jsonResponse['userType']);

          // Navigate to MainScreen after successful registration
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Registration failed: ${jsonResponse['message']}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Registration failed, ${jsonDecode(response.body)['message']}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'What are you interested in?',
          style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: screenWidth * .06),
        ),
        foregroundColor: Colors.white70,
        backgroundColor: myColor,
        elevation: 5,
        toolbarHeight: appBarHeight,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'This will customize your feed',
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
                      return GenreCard(
                        title: genres[index]['title'],
                        imagePath: genres[index]['image'],
                        isSelected:
                            selectedGenres.contains(genres[index]['title']),
                        onTap: () {
                          setState(() {
                            if (selectedGenres
                                .contains(genres[index]['title'])) {
                              selectedGenres.remove(genres[index]['title']);
                              widget.signUpData.selectedGenres = selectedGenres;
                            } else {
                              selectedGenres.add(genres[index]['title']);
                              widget.signUpData.selectedGenres = selectedGenres;
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                print(widget.signUpData.toString());

                // Register user and navigate
                registerUser();
              },
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                elevation: 20,
                shadowColor: Colors.grey,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                "Next",
                style: TextStyle(fontWeight: FontWeight.w700, color: myColor),
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
  final String? imagePath; // Make imagePath nullable
  final bool isSelected;
  final VoidCallback onTap;

  const GenreCard({
    super.key,
    required this.title,
    this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: imagePath != null && imagePath!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imagePath!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(isSelected ? 0.5 : 0.2),
                        BlendMode.darken,
                      ),
                    )
                  : null, // If no image, keep it null
              color: imagePath == null || imagePath!.isEmpty
                  ? Colors.grey[300]
                  : null, // Show a grey background if there's no image
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
                    color: isSelected
                        ? Colors.grey
                        : Colors.white, // Change color based on selection
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
      ),
    );
  }
}
