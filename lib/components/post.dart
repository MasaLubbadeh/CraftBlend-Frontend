import 'dart:convert';

import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'badge.dart';

class PostCard extends StatefulWidget {
  final String profileImageUrl;
  final String username;
  final String content;
  final int likes;
  final int initialUpvotes;
  final int initialDownvotes;
  final int commentsCount;
  final bool isLiked;
  final bool isUpvoted;
  final bool isDownvoted;
  final VoidCallback onLike;
  final Function(int) onUpvote;
  final Function(int) onDownvote;
  final VoidCallback onComment;
  final List<String>? photoUrls;
  final String creatorId;
  final VoidCallback onUsernameTap;
  final DateTime? createdAt;
  final String postType;
  final String store_id;

  const PostCard({
    Key? key,
    required this.profileImageUrl,
    required this.username,
    required this.content,
    required this.likes,
    required this.initialUpvotes,
    required this.initialDownvotes,
    required this.commentsCount,
    required this.isLiked,
    required this.isUpvoted,
    required this.isDownvoted,
    required this.onLike,
    required this.onUpvote,
    required this.onDownvote,
    required this.onComment,
    this.photoUrls,
    required this.creatorId,
    required this.onUsernameTap,
    required this.createdAt,
    required this.postType,
    required this.store_id,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int likes = 0;
  int upvotes = 0;
  int downvotes = 0;
  bool isLiked = false;
  bool isUpvoted = false;
  bool isDownvoted = false;
  int currentImageIndex = 0;
  final List<Map<String, String>> comments = [];
  String formattedDate = '';
  String displayPostType = '';
  String storeName = '';
  @override
  void initState() {
    super.initState();
    likes = widget.likes;
    upvotes = widget.initialUpvotes;
    downvotes = widget.initialDownvotes;
    isLiked = widget.isLiked;
    isUpvoted = widget.isUpvoted;
    isDownvoted = widget.isDownvoted;
    formattedDate = DateFormat('EEEE, MMM d').format(widget.createdAt!);
    getStoreName(widget.store_id);
    print('storeName:$storeName');
    // Map postType to display value
    displayPostType = widget.postType == 'F'
        ? 'Feedback'
        : widget.postType == 'P'
            ? 'Store Post'
            : '';
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likes += isLiked ? 1 : -1;
    });
    widget.onLike();
  }

  void toggleUpvote() {
    setState(() {
      isUpvoted = !isUpvoted;
      upvotes += isUpvoted ? 1 : -1;
    });
    widget.onUpvote(upvotes);
  }

  void toggleDownvote() {
    setState(() {
      isDownvoted = !isDownvoted;
      downvotes += isDownvoted ? 1 : -1;
    });
    widget.onDownvote(downvotes);
  }

  void addComment(String username, String comment) {
    setState(() {
      comments.add({'username': username, 'comment': comment});
    });
    widget.onComment();
  }

  Future<void> getStoreName(String storeID) async {
    print('store id: $storeID');
    try {
      final response = await http.get(Uri.parse('$fetchProfileInfo/$storeID'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        storeName = data['storeName'];
        print('storeName2: $storeName');

        // Use setState to trigger a rebuild with the updated storeName
        setState(() {});
      } else {
        print('Failed to fetch store details');
      }
    } catch (error) {
      print('Error occurred: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Section
          // Badge Section (only visible for 'Feedback' posts)
          if (widget.postType == 'F')
            Align(
              alignment:
                  Alignment.topCenter, // Align to the top-center of the Card
              child: Container(
                width: double
                    .infinity, // Makes the container the same width as the PostCard
                margin: const EdgeInsets.all(
                    0), // Remove any space between badge and the card edges
                child: badge(
                  text: 'What ${widget.username} said about $storeName',
                  color: const Color.fromARGB(
                      255, 169, 163, 172), // Customize color
                  fontSize: 14,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(
                        8), // Custom radius for the top-left corner
                    topRight: Radius.circular(
                        8), // Custom radius for the top-right corner
                    bottomLeft: Radius.circular(
                        0), // Custom radius for the bottom-left corner
                    bottomRight: Radius.circular(
                        15), // Custom radius for the bottom-right corner
                  ),
                ),
              ),
            ),

          Stack(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: (widget.profileImageUrl != null &&
                          widget.profileImageUrl.isNotEmpty)
                      ? NetworkImage(widget.profileImageUrl)
                      : const AssetImage('assets/images/profilePURPLE.jpg')
                          as ImageProvider,
                  backgroundColor: Colors.white,
                ),
                title: GestureDetector(
                  onTap: widget.onUsernameTap,
                  child: Text(
                    widget.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (displayPostType.isNotEmpty)
                Positioned(
                  top: 10,
                  right: 8,
                  child: badge(
                    text: displayPostType,
                    color: displayPostType == "Feedback"
                        ? const Color.fromARGB(255, 106, 98, 112)
                        : const Color.fromARGB(255, 192, 194, 212),
                    fontSize: 12,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
            ],
          ),
          // Date Section
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              widget.content,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          // Image Carousel Section
          if (widget.photoUrls != null && widget.photoUrls!.isNotEmpty)
            Stack(
              children: [
                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    itemCount: widget.photoUrls!.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final photoUrl = widget.photoUrls![index];
                      return ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: photoUrl.startsWith('http')
                            ? Image.network(
                                photoUrl,
                                height: 300,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                photoUrl,
                                height: 300,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      );
                    },
                  ),
                ),
                if (widget.photoUrls!.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:
                          List.generate(widget.photoUrls!.length, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: currentImageIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          // Action Buttons Section
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Heart Button
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border),
                      color: Colors.red,
                      onPressed: toggleLike,
                    ),
                    Text('$likes'),
                  ],
                ),
                // Upvote Button
                Row(
                  children: [
                    IconButton(
                      icon: Icon(isUpvoted
                          ? Icons.arrow_upward
                          : Icons.arrow_upward_outlined),
                      color: Colors.blue,
                      onPressed: toggleUpvote,
                    ),
                    Text('$upvotes'),
                  ],
                ),
                // Downvote Button
                Row(
                  children: [
                    IconButton(
                      icon: Icon(isDownvoted
                          ? Icons.arrow_downward
                          : Icons.arrow_downward_outlined),
                      color: Colors.red,
                      onPressed: toggleDownvote,
                    ),
                    Text('$downvotes'),
                  ],
                ),
                // Comment Button
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.comment),
                      color: Colors.grey,
                      onPressed: _showCommentDialog,
                    ),
                    Text('${comments.length}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentDialog() {
    final TextEditingController _commentController = TextEditingController();
    final TextEditingController _usernameController = TextEditingController();

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
                decoration: const InputDecoration(
                  hintText: 'Your username',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Your comment',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                addComment(_usernameController.text, _commentController.text);
                _commentController.clear();
                Navigator.pop(context);
              },
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }
}
