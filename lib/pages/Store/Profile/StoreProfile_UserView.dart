import 'dart:convert';
import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../components/post.dart';
import '../../Posts/createUserPost.dart';
import 'dashboard.dart';
import 'storeProfile.dart';
import 'storeProfile_page.dart'; // Import the intl package for date formatting

class StoreProfilePage_UserView extends StatefulWidget {
  final String userID;

  StoreProfilePage_UserView({required this.userID});

  @override
  _StoreProfilePage_UserViewState createState() =>
      _StoreProfilePage_UserViewState();
}

class _StoreProfilePage_UserViewState extends State<StoreProfilePage_UserView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  //fetching posts
  List<dynamic> posts = [];
  List<dynamic> feedbacks = [];
  bool isLoading = true;

  late DateTime createdAt;

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
  String userType = '';
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserDetails();
    _fetchProfileData(); // Fetch profile data when the page initializes
    fetchPosts();
  }

  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userType = prefs.getString('userType') ?? 'No Type';
    });
  }

  Future<void> fetchPosts() async {
    final String userID = widget.userID; // Get the userID from the widget
    final String apiUrl = '$fetchAllPosts/$userID'; // Construct the API URL

    try {
      final response = await http.get(Uri.parse('$fetchAccountPosts/$userID'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        /* setState(() {
          posts = data.map((post) {
            final storeId = post['store_id']; // Ensure this field exists
            return {
              ...post,
              'isLiked': false,
              'isUpvoted': false,
              'storeId': storeId,
            };
          }).toList();
          isLoading = false;
        });*/
        setState(() {
          data.forEach((post) {
            final storeId = post['store_id']; // Ensure this field exists
            final postType = post['post_type']; // Check the post type
            createdAt = DateTime.parse(post['createdAt']);

            final enrichedPost = {
              ...post,
              'isLiked': false,
              'isUpvoted': false,
              'storeId': storeId,
              'createdAt': createdAt,
            };

            if (postType == 'P') {
              posts.add(enrichedPost);
            } else if (postType == 'F') {
              feedbacks.add(enrichedPost);
            }
          });

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
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // SizedBox(width: 5),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => StoreProfileScreen()),
                            );
                          },
                          child: const Text('View Products'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => StoreProfileScreen()),
                            );
                          },
                          child: const Text('Message'),
                        ),
                      ],
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
                    height: MediaQuery.of(context).size.height *
                        0.9, // Adjust height as needed
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ListView.builder(
                          physics:
                              NeverScrollableScrollPhysics(), // Prevent ListView scrolling
                          shrinkWrap: true, // Allow ListView to fit its content
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return PostCard(
                              profileImageUrl:
                                  'https://via.placeholder.com/100',
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
                              photoUrls: post['images'] != null &&
                                      post['images'].isNotEmpty
                                  ? List<String>.from(post['images'])
                                  : [],
                              creatorId: post['storeId'] ?? '',
                              onUsernameTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        StoreProfilePage_UserView(
                                            userID: post['storeId'].toString()),
                                  ),
                                );
                              },
                              postType: post['post_type'] ?? '',
                              store_id: post['store_id'] ?? '',
                            );
                          },
                        ),
                        ListView.builder(
                          physics:
                              NeverScrollableScrollPhysics(), // Prevent ListView scrolling
                          shrinkWrap: true, // Allow ListView to fit its content
                          itemCount: feedbacks.length,
                          itemBuilder: (context, index) {
                            final feedback = feedbacks[index];
                            return PostCard(
                              profileImageUrl:
                                  'https://via.placeholder.com/100',
                              username: '${feedback['fullName']}',
                              content: feedback['content'],
                              likes: feedback['likes'] ?? 0,
                              initialUpvotes: feedback['upvotes'] ?? 0,
                              initialDownvotes: feedback['downvotes'] ?? 0,
                              commentsCount: feedback['comments']?.length ?? 0,
                              isLiked: feedback['isLiked'],
                              isUpvoted: feedback['isUpvoted'],
                              isDownvoted: feedback['isDownvoted'] ?? false,
                              createdAt: feedback['createdAt'],
                              onLike: () {
                                handleLike(feedback['_id']);
                              },
                              onUpvote: (newUpvotes) {
                                handleUpvote(feedback['_id']);
                              },
                              onDownvote: (newDownvotes) {
                                handleDownvote(feedback['_id']);
                              },
                              onComment: () {
                                handleComment(feedback['_id']);
                              },
                              photoUrls: feedback['images'] != null &&
                                      feedback['images'].isNotEmpty
                                  ? List<String>.from(feedback['images'])
                                  : [],
                              creatorId: feedback['storeId'] ?? '',
                              onUsernameTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StoreProfilePage(
                                        userID: feedback['storeId'].toString()),
                                  ),
                                );
                              },
                              postType: feedback['post_type'] ?? '',
                              store_id: feedback['store_id'] ?? '',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: userType == 'user'
          ? Material(
              shape: CircleBorder(),
              elevation: 5,
              child: Container(
                width: 70, // Adjust radius
                height: 70,
                child: FloatingActionButton(
                  onPressed: () {
                    String userID = widget.userID;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CreateUserPostPage(userID: userID.toString()),
                      ),
                    );
                  },
                  backgroundColor: myColor,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            )
          : null,
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
