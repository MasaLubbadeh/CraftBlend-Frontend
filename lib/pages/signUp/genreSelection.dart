import 'package:flutter/material.dart';
import 'profilePageState.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What are you interested in?'),
        centerTitle: true,
        backgroundColor: const Color(0xff456268),
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
                // Send the selected genres along with other sign-up data
                widget.signUpData.selectedGenres = selectedGenres;

                // Here you can call a function to save the data to the database
                saveUserData(widget.signUpData);

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(),
                  ),
                );
              },
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

  void saveUserData(SignUpData signUpData) {
    // Here you can implement logic to save the user data to the database
    print(
        "Saving user data: ${signUpData.firstName}, ${signUpData.email}, ${signUpData.selectedGenres}");
    // Example: Use an API call or local database to save data
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
