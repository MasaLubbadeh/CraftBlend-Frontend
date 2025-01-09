import 'dart:convert';
import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../components/post.dart';
import '../../User/login_page.dart';
import '../../User/resetPassword.dart';
import '../../specialOrders/specialOrder_page.dart';
import '../ManageAdvertisement_Page.dart';
import '../manageDeliveryLocations_page.dart';
import '../ownerManagesTheirSubscription.dart';
import 'dashboard.dart';
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
  //fetching posts
  List<dynamic> posts = [];
  List<dynamic> feedbacks = [];
  bool isLoading = true;
  Map<String, dynamic>? storeData; // Store data

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
  late DateTime createdAt;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _fetchProfileData(); // Fetch profile data when the page initializes
    fetchPosts();
    _fetchStoreDetails();
  }

  Future<void> _fetchStoreDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token'); // Retrieve the stored token

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse(getStoreDetails), // Use the store details API endpoint
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
        print(response.body);

        if (response.statusCode == 200) {
          setState(() {
            storeData = json.decode(response.body); // Decode the response
            isLoading = false; // Stop loading
          });
        } else {
          print('Error fetching store data: ${response.statusCode}');
          setState(() {
            isLoading = false; // Stop loading
          });
        }
      } catch (e) {
        print('Exception while fetching store data: $e');
        setState(() {
          isLoading = false; // Stop loading
        });
      }
    } else {
      print('Token not found. Cannot fetch data.');
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  Future<void> fetchPosts() async {
    final String userID = widget.userID; // Get the userID from the widget
    final String apiUrl = '$fetchAllPosts/$userID'; // Construct the API URL

    try {
      final response = await http.get(Uri.parse('$fetchAccountPosts/$userID'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        /*   setState(() {
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
    double appBarHeight = MediaQuery.of(context).size.height * 0.08;
    var mediaSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(LineAwesomeIcons.bars, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Open the drawer
              },
            );
          },
        ),

        // backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: mediaSize.height * 0.27,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/arcTest2.png'),
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: mediaSize.height * 0.18,
                    left: mediaSize.width / 4.5,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white24,
                          width: 7,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: mediaSize.height * 0.07,
                        backgroundImage: (storeData?['logo'] != null &&
                                storeData!['logo'].isNotEmpty)
                            ? NetworkImage(storeData!['logo'])
                            : const AssetImage(
                                    'assets/images/profilePURPLE.jpg')
                                as ImageProvider,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: mediaSize.height * 0.09),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delivery_dining, color: myColor),
                title: const Text(
                  "Your Account",
                  style: TextStyle(
                    color: myColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const StoreProfileScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delivery_dining, color: myColor),
                title: const Text(
                  "Manage your delivery locations",
                  style: TextStyle(
                    color: myColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const ManageDeliveryLocationsPage()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(LineAwesomeIcons.ad, color: myColor),
                title: const Text(
                  "Home Page Ad Management",
                  style: TextStyle(
                    color: myColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ManageAdvertisementPage()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.shopping_cart, color: myColor),
                title: const Text(
                  "Manage special orders",
                  style: TextStyle(
                    color: myColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () {
                  final category = storeData?['category'];
                  if (category != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SpecialOrdersPage(category: category),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Category not found for this store.')),
                    );
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.subscriptions, color: myColor),
                title: const Text(
                  "Manage your subscription",
                  style: TextStyle(
                    color: myColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ManageSubscriptionPage()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(LineAwesomeIcons.key, color: myColor),
                title: const Text(
                  "Change Password",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: myColor,
                      letterSpacing: 1),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResetPasswordPage(),
                    ),
                  );
                },
              ),
              const Divider(),
              const SizedBox(height: 20), // Optional spacing
              ListTile(
                leading: const Icon(LineAwesomeIcons.alternate_sign_out,
                    color: myColor),
                title: const Text(
                  "Logout",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: myColor,
                      letterSpacing: 1),
                ),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You have logged out successfully.'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show loading indicator while fetching data
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
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
                        /* ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => StoreProfileScreen()),
                            );
                          },
                          child: const Text('Edit Profile'),
                        ),*/
                        const SizedBox(width: 5),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DashboardPage()),
                            );
                          },
                          child: const Text('Dashboard'),
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
                        0.8, // Adjust height as needed
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
                                    builder: (context) => StoreProfilePage(
                                        userID: post['storeId'].toString()),
                                  ),
                                );
                              },
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
