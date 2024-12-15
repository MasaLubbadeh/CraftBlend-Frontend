import 'package:flutter/material.dart';

import '../components/post.dart';
import 'Posts/createPost.dart';
import 'chatting/chat_page.dart';

class FeedPage extends StatelessWidget {
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
        backgroundColor: const Color.fromARGB(
            40, 40, 40, 40), // Match background color to PostCard
        elevation: 4, // Add shadow similar to PostCard's elevation
        leading: SizedBox(
          width: 0,
        ), // Removes the default back arrow
        actions: [
          // Add Icon (Navigates to CreatePostPage)
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              print("Add icon pressed!");
              // Navigate to CreatePostPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreatePostPage()),
              );
            },
          ),
          SizedBox(width: 10), // Adds space between icons
          // Chat Icon (Navigates to ChatPage)
          IconButton(
            icon: Icon(Icons.chat_bubble_outline),
            onPressed: () {
              print("Chat icon pressed!");
              // Navigate to ChatPage (You can uncomment this when you have the ChatPage)
              /* Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatPage()),
              );*/
            },
          ),
          SizedBox(width: 10), // Adds space between icons
        ],
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
          ),
          // Add more PostCard widgets here
        ],
      ),
    );
  }
}
