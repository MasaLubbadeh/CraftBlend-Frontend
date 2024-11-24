import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'profilePageState.dart'; // Assuming ProfilePage exists
import '../../configuration/config.dart'; // Assuming configuration includes the registration endpoint
import '../../models/sign_up_data.dart';

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
  final List<Map<String, String>> genres = [
    {'title': 'Pastries', 'image': 'assets/images/pastaries.jpg'},
    {'title': 'Pottery', 'image': 'assets/images/pottery.jpg'},
    {'title': 'Crochet', 'image': 'assets/images/crochet.png'},
    {'title': 'Build A Bear', 'image': 'assets/images/buildbear.png'},
    {'title': 'Phone Covers', 'image': 'assets/images/covers.png'},
    {'title': 'Flowers', 'image': 'assets/images/flowers.png'},
  ];

  List<String> selectedGenres = [];

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
        "accountType": widget.signUpData.accountType = "U",
        "selectedGenres": selectedGenres,
      };

      // Send data to the server
      var response = await http.post(
        Uri.parse(registration), // Use your registration endpoint here
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(regbody),
      );

      // Handle server response
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == "success") {
          print("Registration successful!");
          // Navigate to ProfilePage after successful registration
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => ProfilePage()),
          );
        } else {
          widget.signUpData.accountType = "U";
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
            content: Text("Server error: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill in all fields!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What are you interested in?'),
        centerTitle: true,
        backgroundColor: myColor,
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                  isSelected: selectedGenres.contains(genres[index]['title']),
                  onTap: () {
                    setState(() {
                      if (selectedGenres.contains(genres[index]['title'])) {
                        selectedGenres.remove(genres[index]['title']);
                      } else {
                        selectedGenres.add(genres[index]['title']!);
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
                // Save selected genres to signUpData before registration
                widget.signUpData.selectedGenres = selectedGenres;
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
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const GenreCard({
    super.key,
    required this.title,
    required this.imagePath,
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
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(isSelected ? 0.5 : 0.2),
                  BlendMode.darken,
                ),
              ),
              border:
                  isSelected ? Border.all(color: Colors.white, width: 3) : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
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
