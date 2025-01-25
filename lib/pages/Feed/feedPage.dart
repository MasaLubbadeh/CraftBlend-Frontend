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

import 'package:quickalert/quickalert.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<dynamic> posts = [];
  List<dynamic> favoritePosts = [];

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
    setState(() {
      isLoading = true; // Show loading indicator
      posts = []; // Reset the posts to an empty list before fetching new ones
    });

    try {
      final response = await http.get(Uri.parse(fetchAllPosts));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("These are the fetched posts:");
        print(data);

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        String? selectedItem =
            prefs.getString('selectedItem'); // Default to 'Recents'
        print('selectedItem:$selectedItem');

        // Sorting logic based on the selected item
        if (selectedItem == 'Popular') {
          data.sort((a, b) => (b['upvotes'] ?? 0).compareTo(a['upvotes'] ?? 0));
        } else if (selectedItem == 'Recents') {
          data.sort((a, b) => DateTime.parse(
                  b['createdAt'] ?? DateTime.now().toString())
              .compareTo(
                  DateTime.parse(a['createdAt'] ?? DateTime.now().toString())));
        } else if (selectedItem == 'Favorites') {
          getFavoriteStores();
          print('favoerite posts insode fetch:$favoritePosts');
          posts = [];
          posts = favoritePosts;
          print('favoeriteldjulidrgiergh posts insode fetch:$posts');
        }

        setState(() {
          if (selectedItem != 'Favorites') {
            posts = data.map((post) {
              final storeId = post['store_id'];
              createdAt = DateTime.parse(post['createdAt']);
              return {
                ...post,
                'isLiked': false,
                'isUpvoted': false,
                'storeId': storeId,
                'createdAt': createdAt,
              };
            }).toList();
          }

          isLoading = false; // Hide loading indicator after fetching data
        });
      } else {
        throw Exception('Failed to fetch posts');
      }
    } catch (e) {
      print('Error fetching posts: $e');
      setState(() {
        isLoading = false; // Hide loading indicator on error
      });
    }
  }

  void updateSorting(String selectedItem) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedItem', selectedItem);
    setState(() {
      isLoading = true; // Show loader during refresh
    });
    await fetchPosts(); // Fetch the posts again with the new selected item
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

  // Fetch favorite stores for the user
  Future<void> getFavoriteStores() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token')!;
    try {
      final response = await http.get(
        Uri.parse(getFavoriteStoress),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> favorites = data['data'];

        // Extract store IDs from the response
        List<String> storeIds = favorites
            .map<String>((favorite) =>
                favorite['_id'].toString()) // Convert storeId to String
            .toList();

        print('store idssss:$storeIds');
        fetchFavoritesPosts(storeIds);
        // return storeIds;
      } else {
        throw Exception('Failed to load favorite stores');
      }
    } catch (error) {
      throw Exception('Error fetching favorite stores: $error');
    }
  }

  Future<void> fetchFavoritesPosts(List<String> storeIds) async {
    print('im inside fetch favorite posts');
    try {
      for (String storeId in storeIds) {
        print('these are the stores ids:$storeId');
        print('$fetchAccountPosts/$storeId');
        final response = await http.get(Uri.parse('$fetchStorePosts/$storeId'));

        print('sent the request');
        print(
            'this is the status code for the feetch favorite:${response.body}');
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);

          // Here we add the posts for the store to a list
          data.forEach((post) {
            final postType = post['post_type']; // Check the post type

            final enrichedPost = {
              ...post,
              'isLiked': false,
              'isUpvoted': false,
              'storeId': storeId,
              'createdAt': DateTime.parse(post['createdAt']),
            };
            // Add enrichedPost to your posts list (ensure this list is initialized elsewhere)
            posts.add(enrichedPost);
            print('favorite posts:$posts');
          });
        } else {
          print('Failed to fetch posts for storeId: $storeId');
        }
      }
    } catch (e) {
      print('Error fetching posts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        onItemSelected: (selectedItem) {
          updateSorting(selectedItem);
        }, // Pass updateSorting function to MyAppBar
      ),
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
                        profileImageUrl: post['profileImageUrl'] ?? '',
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
                        postType: post['post_type'] ?? '',
                        store_id: post['store_id'] ?? '',
                      );
                    },
                  ),
      ),
    );
  }
}
