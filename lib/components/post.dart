import 'package:flutter/material.dart';

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
  int currentImageIndex = 0; // Tracks the current image index
  final List<Map<String, String>> comments = [];

  @override
  void initState() {
    super.initState();
    likes = widget.likes;
    upvotes = widget.initialUpvotes;
    downvotes = widget.initialDownvotes;
    isLiked = widget.isLiked;
    isUpvoted = widget.isUpvoted;
    isDownvoted = widget.isDownvoted;
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
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(widget.profileImageUrl),
            ),
            title: Text(
              widget.username,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
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
                // Image count indicator at the top-right
                if (widget.photoUrls!.length > 1)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${currentImageIndex + 1}/${widget.photoUrls!.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                // Dots indicator at the bottom
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
                      onPressed: () {
                        _showCommentDialog(context);
                      },
                    ),
                    Text('${comments.length}'),
                  ],
                ),
              ],
            ),
          ),
          // Display Comments Section
          if (comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: comments.map((comment) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child:
                        Text("- ${comment['username']}: ${comment['comment']}"),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _showCommentDialog(BuildContext context) {
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
                  hintText: 'Write your comment...',
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
                if (_commentController.text.trim().isNotEmpty &&
                    _usernameController.text.trim().isNotEmpty) {
                  addComment(
                    _usernameController.text.trim(),
                    _commentController.text.trim(),
                  );
                }
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
