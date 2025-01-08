import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../components/myAppBar.dart';
import '../../components/post.dart';
import '../../configuration/config.dart';
import '../Posts/createStorePost.dart';
import '../Posts/createUserPost.dart';
import '../Store/Profile/StoreProfile_UserView.dart';
import '../Store/Profile/storeProfile.dart';

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

  late DateTime createdAt;

/////////so it will only open profile if store is pressed
  bool isStore(String type) {
    if (type == 'S') {
      return true;
    } else {
      return false;
    }
  }

  Future<void> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse(fetchAllPosts));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("these are the fetched posts:");
        print(data);

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        String? selectedItem = prefs.getString('selectedItem');
        print('selectedItem:$selectedItem');
        // Sorting logic based on the selected item
        if (selectedItem == 'Popular') {
          data.sort((a, b) => (b['upvotes'] ?? 0).compareTo(a['upvotes'] ?? 0));
          posts.sort(
              (a, b) => (a['downvotes'] ?? 0).compareTo(b['downvotes'] ?? 0));
        } else if (selectedItem == 'Favorites') {
          // Sort posts based on favorites, assuming there's a 'favorites' field
          //data.sort((a, b) => (b['favorites'] ?? 0).compareTo(a['favorites'] ?? 0));
        } else if (selectedItem == 'Recents') {
          // Sort posts by creation date or recency, assuming there's a 'createdAt' field
          data.sort((a, b) => DateTime.parse(b['createdAt'] ?? '')
              .compareTo(DateTime.parse(a['createdAt'] ?? '')));
        } else {
          // Default to sorting by upvotes (Home)
          data.sort((a, b) => (b['upvotes'] ?? 0).compareTo(a['upvotes'] ?? 0));
        }
        // Sort posts by upvotes in ascending order before updating state

        setState(() {
          posts = data.map((post) {
            final storeId = post['store_id']; // Check this field exists
            createdAt = DateTime.parse(post['createdAt']);

            return {
              ...post,
              'isLiked': false,
              'isUpvoted': false,
              'storeId': storeId,
              'createdAt': createdAt,
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
      appBar: MyAppBar(),
      body: RefreshIndicator(
        onRefresh: fetchPosts,
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
                        username: '${post['fullName']}',
                        content: post['content'],
                        likes: post['likes'] ?? 0,
                        initialUpvotes: post['upvotes'] ?? 0,
                        initialDownvotes: post['downvotes'] ?? 0,
                        commentsCount: post['comments']?.length ?? 0,
                        isLiked: post['isLiked'],
                        isUpvoted: post['isUpvoted'],
                        isDownvoted: post['isDownvoted'] ?? false,
                        createdAt: post['createdAt'],
                        onLike: () {
                          handleLike(post['_id']);
                        },
                        onUpvote: (newUpvotes) {
                          handleUpvote(post['_id']);
                        },
                        onDownvote: (newDownvotes) {
                          handleDownvote(post['_id']);
                        },
                        onComment: () {
                          handleComment(post['_id']);
                        },
                        photoUrls:
                            post['images'] != null && post['images'].isNotEmpty
                                ? List<String>.from(post['images'])
                                : [],
                        creatorId: post['storeId'] ?? '',
                        onUsernameTap: () {
                          print("this is the id of the store:");
                          print(post['storeId'].toString());
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StoreProfilePage_UserView(
                                  userID: post['storeId'].toString()),
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
