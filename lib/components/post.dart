import 'package:flutter/material.dart';

class PostCard extends StatefulWidget {
  final String profileImageUrl;
  final String username;
  final String content;
  final int likes;
  final int initialUpvotes;
  final int commentsCount;
  final VoidCallback onLike;
  final Function(int) onUpvote;
  final VoidCallback onComment;
  final String? photoUrl; // Optional photo URL

  const PostCard({
    Key? key,
    required this.profileImageUrl,
    required this.username,
    required this.content,
    required this.likes,
    required this.initialUpvotes,
    required this.commentsCount,
    required this.onLike,
    required this.onUpvote,
    required this.onComment,
    this.photoUrl, // Optional parameter
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int likes = 0;
  int upvotes = 0;
  bool isLiked = false;
  bool isUpvoted = false;

  final List<Map<String, String>> comments = [];

  @override
  void initState() {
    super.initState();
    likes = widget.likes;
    upvotes = widget.initialUpvotes;
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
          // Optional Image Section
// Optional Image Section
          if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: widget.photoUrl!
                      .startsWith('http') // Check if it's a network URL
                  ? Image.network(
                      widget.photoUrl!, // Network image
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      // Local asset image
                      widget.photoUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
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
