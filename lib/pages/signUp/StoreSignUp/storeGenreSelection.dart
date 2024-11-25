import 'package:flutter/material.dart';

class StoreGenreSelectionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const StoreGenreSelectionScreen(),
    );
  }
}

class StoreGenreSelectionScreen extends StatefulWidget {
  const StoreGenreSelectionScreen({super.key});

  @override
  _StoreGenreSelectionScreenState createState() =>
      _StoreGenreSelectionScreenState();
}

class _StoreGenreSelectionScreenState extends State<StoreGenreSelectionScreen> {
  final List<Map<String, String>> genres = [
    {'title': 'Pastries', 'image': 'assets/images/pastries.jpg'},
    {'title': 'Pottery', 'image': 'assets/images/pottery.jpg'},
    {'title': 'Crochet', 'image': 'assets/images/crochet.png'},
    {'title': 'Build A Bear', 'image': 'assets/images/buildbear.png'},
    {'title': 'Phone Covers', 'image': 'assets/images/covers.png'},
    {'title': 'Flowers', 'image': 'assets/images/flowers.png'},
  ];

  String? selectedGenre;

  // Shared variable to hold store genre (use static for demo purposes)
  static String? storeGenre;

  void onNextPressed() {
    if (selectedGenre != null) {
      // Save the selected genre to the shared variable
      storeGenre = selectedGenre;

      // Navigate to the next page in the store signup process
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              const NextSignupPage(), // Replace with your next page
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Store Genre'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'This helps us customize your store setup',
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
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: onNextPressed,
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                elevation: 20,
                shadowColor: Colors.grey,
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
    );
  }
}

class NextSignupPage extends StatelessWidget {
  const NextSignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Next Signup Step'),
      ),
      body: Center(
        child: Text(
          'Selected Store Genre: ${_StoreGenreSelectionScreenState.storeGenre ?? 'None'}',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
