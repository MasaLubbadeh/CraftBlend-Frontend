import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  bool isLiked = false;
  bool isUpvoted = false;
  // int likes = 0;
  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse(fetchAllPosts));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Sort posts by upvotes in ascending order before updating state
        data.sort((a, b) => (b['upvotes'] ?? 0).compareTo(a['upvotes'] ?? 0));
        posts.sort(
            (a, b) => (a['downvotes'] ?? 0).compareTo(b['downvotes'] ?? 0));

        setState(() {
          posts = data.map((post) {
            return {
              ...post,
              'isLiked': false,
              'isUpvoted': false,
            };
          }).toList();
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
    final postIndex = posts.indexWhere((post) => post['_id'] == postId);
    if (postIndex == -1) return;

    if (posts[postIndex]['isLiked']) {
      print('Post already liked.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${likes}posts/$postId/like'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          posts[postIndex]['isLiked'] = true;
          posts[postIndex]['likes'] = data['likes'];
        });
        print('Post liked successfully. Total likes: ${data['likes']}');
      } else {
        print('Failed to like post: ${response.body}');
      }
    } catch (e) {
      print('Error liking post: $e');
    }
  }

  Future<void> handleUpvote(String postId) async {
    final postIndex = posts.indexWhere((post) => post['_id'] == postId);
    if (postIndex == -1) return;

    if (posts[postIndex]['isUpvoted']) {
      print('Post already upvoted.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${upvotes}posts/$postId/upvote'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          posts
              .sort((a, b) => (b['upvotes'] ?? 0).compareTo(a['upvotes'] ?? 0));

          posts[postIndex]['isUpvoted'] = true;
          posts[postIndex]['upvotes'] = data['upvotes'];
        });
        print('Post upvoted successfully. Total upvotes: ${data['upvotes']}');
      } else {
        print('Failed to upvote post: ${response.body}');
      }
    } catch (e) {
      print('Error upvoting post: $e');
    }
  }

  Future<void> handleDownvote(String postId) async {
    final postIndex = posts.indexWhere((post) => post['_id'] == postId);
    if (postIndex == -1) return;

    if (posts[postIndex]['isDownvoted'] != null &&
        posts[postIndex]['isDownvoted']) {
      print('Post already downvoted.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${downvotes}posts/$postId/downvote'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          posts.sort(
              (a, b) => (a['downvotes'] ?? 0).compareTo(b['downvotes'] ?? 0));

          posts[postIndex]['isDownvoted'] = true;
          posts[postIndex]['downvotes'] = data['downvotes'];
        });
        print(
            'Post downvoted successfully. Total downvotes: ${data['downvotes']}');
      } else {
        print('Failed to downvote post: ${response.body}');
      }
    } catch (e) {
      print('Error downvoting post: $e');
    }
  }

  Future<void> handleComment(String postId) async {
    final TextEditingController _commentController = TextEditingController();

    // Fetch user details from SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? firstName = prefs.getString('firstName');
    String? lastName = prefs.getString('lastName');

    // If first name or last name is not available, set a default
    String username = (firstName != null && lastName != null)
        ? '$firstName $lastName'
        : 'Anonymous';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Comment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                if (_commentController.text.isNotEmpty) {
                  try {
                    final response = await http.post(
                      Uri.parse(
                          'https://your-api-endpoint/posts/$postId/comment'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({
                        'username':
                            username, // Use the username from shared preferences
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
      body: RefreshIndicator(
        onRefresh: fetchPosts, // Trigger the fetchPosts function on pull-down
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : posts.isEmpty
                ? const Center(child: Text('No posts available'))
                : ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];

                      return PostCard(
                        profileImageUrl: 'https://via.placeholder.com/100',
                        username: '${post['firstName']} ${post['lastName']}',
                        content: post['content'],
                        likes: post['likes'] ??
                            0, // Fetch likes from the post, default to 0 if null
                        initialUpvotes: post['upvotes'] ??
                            0, // Fetch upvotes, default to 0 if null
                        initialDownvotes:
                            post['downvotes'] ?? 0, // Pass initial downvotes

                        commentsCount: post['comments']?.length ??
                            0, // Count comments, default to 0 if null
                        isLiked: post['isLiked'],
                        isUpvoted: post['isUpvoted'],
                        isDownvoted:
                            post['isDownvoted'] ?? false, // Add downvoted state

                        onLike: () {
                          handleLike(post['_id']); // Pass the post ID
                        },
                        onUpvote: (newUpvotes) {
                          handleUpvote(post['_id']); // Pass the post ID
                        },
                        onDownvote: (newDownvotes) {
                          handleDownvote(post['_id']); // Pass downvote logic
                        },
                        onComment: () {
                          handleComment(post['_id']); // Pass the post ID
                        },
                        photoUrls:
                            post['images'] != null && post['images'].isNotEmpty
                                ? List<String>.from(
                                    post['images']) // Convert to List<String>
                                : [],
                      );
                    },
                  ),
      ),
    );
  }
}
