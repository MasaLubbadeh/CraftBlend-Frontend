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
        print("posts fetched succefully");
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

  Future<void> handleLike(String postId) async {
    try {
      final response = await http.post(
        Uri.parse('${likes}posts/$postId/like'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Post liked successfully. Total likes: ${data['likes']}');
      } else {
        print('Failed to like post: ${response.body}');
      }
    } catch (e) {
      print('Error liking post: $e');
    }
  }

  Future<void> handleUpvote(String postId) async {
    try {
      final response = await http.post(
        Uri.parse('${upvotes}posts/$postId/upvote'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Post upvoted successfully. Total upvotes: ${data['upvotes']}');
      } else {
        print('Failed to upvote post: ${response.body}');
      }
    } catch (e) {
      print('Error upvoting post: $e');
    }
  }

  Future<void> handleComment(String postId) async {
    final TextEditingController _usernameController = TextEditingController();
    final TextEditingController _commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Comment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(hintText: 'Your username'),
              ),
              TextField(
                controller: _commentController,
                decoration:
                    const InputDecoration(hintText: 'Write your comment'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_usernameController.text.isNotEmpty &&
                    _commentController.text.isNotEmpty) {
                  try {
                    final response = await http.post(
                      Uri.parse('${comments}posts/$postId/comment'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({
                        'username': _usernameController.text.trim(),
                        'comment': _commentController.text.trim(),
                      }),
                    );

                    if (response.statusCode == 200) {
                      print('Comment added successfully.');
                    } else {
                      print('Failed to add comment: ${response.body}');
                    }
                  } catch (e) {
                    print('Error adding comment: $e');
                  }

                  Navigator.pop(context);
                }
              },
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
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
                    print(post); // Debugging line to check the data

                    PostCard(
                      profileImageUrl: 'https://via.placeholder.com/100',
                      username: '${post['firstName']} ${post['lastName']}',
                      content: post['content'],
                      likes: post['likes'] ?? 0,
                      initialUpvotes: post['upvotes'] ?? 0,
                      commentsCount: (post['comments'] as List).length,
                      onLike: () {
                        handleLike(post['_id']); // Pass the post ID
                      },
                      onUpvote: (newUpvotes) {
                        handleUpvote(post['_id']); // Pass the post ID
                      },
                      onComment: () {
                        handleComment(post['_id']); // Pass the post ID
                      },
                      photoUrls: List<String>.from(post['images'] ?? []),
                    );
                  },
                ),
    );
  }
}
