import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../components/button.dart';

class StoreProfilePage extends StatefulWidget {
  @override
  _StoreProfilePageState createState() => _StoreProfilePageState();
}

class _StoreProfilePageState extends State<StoreProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _storeName = "NO NAME"; // Default value

  // Static profile data
  final Map<String, dynamic> profileData = {
    'bio': 'Crafting unique handmade items with love.',
    'profilePicture': 'assets/default_profile.jpg',
    'posts': 12,
    'upvotes': 134,
    'feedbacks': 5,
    'postImages': [
      'https://via.placeholder.com/150',
      'https://via.placeholder.com/150',
      'https://via.placeholder.com/150',
      'https://via.placeholder.com/150',
    ],
    'feedbacksList': [
      {'title': 'Great Product!', 'content': 'I loved the craftsmanship.'},
      {'title': 'Amazing Quality', 'content': 'Exceeded my expectations!'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStoreName(); // Load the store name when the page initializes
  }

  Future<void> _loadStoreName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _storeName = prefs.getString('storeName') ?? "NoName"; // Default fallback
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String bio = profileData['bio'];
    final String profilePicture = profileData['profilePicture'];
    final int posts = profileData['posts'];
    final int upvotes = profileData['upvotes'];
    final int feedbacks = profileData['feedbacks'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage(profilePicture),
            ),
            const SizedBox(height: 12),
            Text(
              _storeName, // Use the dynamic _storeName here
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn("Posts", posts.toString()),
                  _buildStatColumn("Upvotes", upvotes.toString()),
                  _buildStatColumn("Feedbacks", feedbacks.toString()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                bio,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 150,
              child: CustomButton(
                onPressed: () {
                  // Define the action for the button
                },
                label: 'Edit Profile',
                icon: Icons.edit,
                color: Colors.blue,
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.grid_on), text: 'Posts'),
                Tab(icon: Icon(Icons.feedback), text: 'Feedbacks'),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: TabBarView(
                controller: _tabController,
                children: [
                  GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: profileData['postImages'].length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final String imageUrl = profileData['postImages'][index];
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
                    itemCount: profileData['feedbacksList'].length,
                    itemBuilder: (context, index) {
                      final feedback = profileData['feedbacksList'][index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: ListTile(
                          leading: const Icon(Icons.feedback),
                          title: Text(feedback['title']),
                          subtitle: Text(feedback['content']),
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
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
