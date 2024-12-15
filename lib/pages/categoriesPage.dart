import 'package:flutter/material.dart';

import '../components/post.dart';

class FeedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        backgroundColor: const Color.fromARGB(255, 200, 191, 207),
      ),
      body: ListView(
        children: [
          PostCard(
            profileImageUrl:
                'https://via.placeholder.com/100', // Replace with the actual profile image URL
            username: 'Bees Masa', // Replace with the actual username
            content: "I'm going to do a Black Friday sale next week.",
            likes: 10,
            initialUpvotes: 5, // Initial upvotes passed to the PostCard
            commentsCount: 2, // Initial comment count displayed
            onLike: () {
              print("Post liked!");
              // Perform any additional actions on like
            },
            onUpvote: (newUpvotes) {
              print("Updated upvotes: $newUpvotes");
              // Perform any additional actions when upvotes are updated
              // For example, updating the backend or re-sorting posts in the feed
            },
            onComment: () {
              print("Comment button pressed!");
              // Handle any additional actions on comment, such as showing a comments page
            },
          )

          // Add more PostCard widgets here
        ],
      ),
    );
  }
}
