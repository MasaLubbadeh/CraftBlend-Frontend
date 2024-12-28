import 'dart:convert';
import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'storeProfile_page.dart'; // Import the intl package for date formatting

class StoreProfilePage extends StatefulWidget {
  final String userID;

  StoreProfilePage({required this.userID});

  @override
  _StoreProfilePageState createState() => _StoreProfilePageState();
}

class _StoreProfilePageState extends State<StoreProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Initialize variables with default values
  String _storeName = "Loading...";
  String _bio = "Loading...";
  String _profilePicture = 'https://via.placeholder.com/100';
  int _posts = 0;
  int _upvotes = 0;
  int _feedbacks = 0;
  List<String> _postImages = [];
  List<Map<String, String>> _feedbacksList = [];
  bool _isLoading = true; // To show loading indicator
  String _dateCreated = ""; // Add a new variable for the formatted date

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _fetchProfileData(); // Fetch profile data when the page initializes
  }

  Future<void> _fetchProfileData() async {
    final String userID = widget.userID;
    final response = await http.get(
      Uri.parse('$fetchProfileInfo/$userID'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Format the dateCreated value
      if (data['dateCreated'] != null) {
        DateTime dateTime = DateTime.parse(data['dateCreated']);
        _dateCreated = DateFormat('dd MMM yyyy')
            .format(dateTime); // Format the date to "23 Dec 2024"
      }

      setState(() {
        _storeName = data['storeName'] ?? "No Name";
        _bio = data['bio'] ?? "No Bio";
        _profilePicture =
            data['profilePicture'] ?? 'https://via.placeholder.com/100';
        _posts = data['posts'] ?? 0;
        _upvotes = data['upvotes'] ?? 0;
        _feedbacks = data['feedbacks'] ?? 0;
        _postImages = List<String>.from(data['postImages'] ?? []);
        _feedbacksList =
            List<Map<String, String>>.from(data['feedbacksList'] ?? []);
        _isLoading = false; // Stop loading when data is fetched
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load profile data")),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show loading indicator while fetching data
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: _profilePicture.startsWith('http')
                        ? NetworkImage(_profilePicture) as ImageProvider
                        : AssetImage(_profilePicture),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _storeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn("Posts", _posts.toString()),
                        _buildStatColumn("Upvotes", _upvotes.toString()),
                        _buildStatColumn("Feedbacks", _feedbacks.toString()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Date Created: $_dateCreated',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => StoreProfileScreen()),
                        );
                      },
                      child: const Text('Edit Profile'),
                    ),
                  ),
                  const SizedBox(height: 5),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on)),
                      Tab(icon: Icon(Icons.feedback)),
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.1,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        GridView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _postImages.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 2, // Reduced spacing
                            crossAxisSpacing: 2, // Reduced spacing
                            childAspectRatio: 0.9, // Smaller aspect ratio
                          ),
                          itemBuilder: (context, index) {
                            final String imageUrl = _postImages[index];
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                        ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _feedbacksList.length,
                          itemBuilder: (context, index) {
                            final feedback = _feedbacksList[index];
                            return Card(
                              margin: const EdgeInsets.only(
                                  bottom: 8.0), // Reduced margin
                              child: ListTile(
                                leading: const Icon(Icons.feedback),
                                title: Text(feedback['title'] ?? 'No title'),
                                subtitle:
                                    Text(feedback['content'] ?? 'No content'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14, // Reduced font size
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12), // Reduced font size
        ),
      ],
    );
  }
}
