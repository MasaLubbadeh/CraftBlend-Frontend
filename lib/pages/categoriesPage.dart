import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../components/post.dart';
import '../configuration/config.dart';
import 'Posts/createPost.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<dynamic> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      // Replace with your backend URL
      // const String url = 'http://your-backend-url/api/posts';

      // Fetch posts
      final response = await http.get(Uri.parse(fetchAllPosts));

      if (response.statusCode == 200) {
        // Parse JSON response
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          posts = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch posts');
      }
    } catch (e) {
      print('Error fetching posts: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'CraftBlend',
              style: TextStyle(
                fontFamily: 'Pacifico', // Use a cursive font
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(40, 40, 40, 40),
        elevation: 4,
        leading: SizedBox(width: 0),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreatePostPage()),
              );
            },
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              // Navigate to ChatPage when available
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
              ? const Center(child: Text('No posts available'))
              : ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return PostCard(
                      profileImageUrl:
                          'https://via.placeholder.com/100', // Placeholder for profile image
                      username:
                          '${post['firstName']} ${post['lastName']}', // Username from post data
                      content: post['content'], // Post content
                      likes:
                          0, // Set default likes or handle likes from backend
                      initialUpvotes:
                          0, // Default upvotes or fetch from backend
                      commentsCount:
                          0, // Default comments or fetch from backend
                      onLike: () {
                        print("Post liked!");
                      },
                      onUpvote: (newUpvotes) {
                        print("Updated upvotes: $newUpvotes");
                      },
                      onComment: () {
                        print("Comment button pressed!");
                      },
                      photoUrl:
                          post['images'] != null && post['images'].isNotEmpty
                              ? post['images'][0] // Display the first image
                              : null, // No image if none is provided
                    );
                  },
                ),
    );
  }
}
