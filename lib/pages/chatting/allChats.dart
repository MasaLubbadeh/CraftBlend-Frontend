import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:craft_blend_project/models/message.dart';
import 'package:craft_blend_project/services/authentication/auth_service.dart';
import 'package:flutter/material.dart';
import '../../configuration/config.dart';
import '../../pages/chatting/chat_page.dart';
import '../../services/chat/chat_service.dart';

class AllChats extends StatelessWidget {
  AllChats({super.key});

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildUserList(),
      ),
    );
  }

  Future<String?> _fetchFullName(String email) async {
    try {
      print("Fetching full name...");

      // Get user details from Firestore
      final userDoc = await _firestore.collection("Users").doc(email).get();

      /*if (userDoc.exists) {
        final user = userDoc.data()!;
        final String firstName = user['firstName'] ?? 'Unknown';
        final String lastName = user['lastName'] ?? 'User';
        return '$firstName $lastName';
      } else {
        print('User not found in Firestore');
      }*/
      if (userDoc.exists) {
        final user = userDoc.data()!;

        // Check if the document has firstName and lastName fields
        if (user.containsKey('firstName') && user.containsKey('lastName')) {
          final String firstName = user['firstName'] ?? 'Unknown';
          final String lastName = user['lastName'] ?? 'User';
          return '$firstName $lastName';
        }
        // Otherwise, check for storeName
        else if (user.containsKey('storeName')) {
          final String storeName = user['storeName'] ?? 'Unknown Store';
          return storeName;
        }
        // Fallback for any unexpected case
        else {
          return 'Unknown User';
        }
      } else {
        print('User not found in Firestore');
        return 'Unknown User';
      }
    } catch (error) {
      print('Error fetching user data from Firestore: $error');
    }
    return null;
  }

  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  "An error occurred: ${snapshot.error}",
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No users found.",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final userData = snapshot.data![index];
            return _buildUserListItem(userData, context);
          },
        );
      },
    );
  }

  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    final currentUser = _authService.getCurrentUser();
    /*  if (currentUser == null || userData["email"] == currentUser.email) {
      return const SizedBox(); // Skip displaying the current user
    }*/

    return GestureDetector(
      onTap: () async {
        final fullName = await _fetchFullName(userData["email"]);
        print("Full name: $fullName");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              recieverEmail: userData["email"],
              receiverID: userData["uid"],
              firstName: userData["firstName"] ?? "Unknown",
              lastName: userData["lastName"] ?? "User",
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(
                  userData["profilePicture"] ??
                      "https://via.placeholder.com/150", // Default placeholder
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData.containsKey("firstName") &&
                            userData.containsKey("lastName")
                        ? "${userData["firstName"] ?? "Unknown"} ${userData["lastName"] ?? "User"}"
                        : userData["storeName"] ?? "Unknown Store",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Tap to start a conversation",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
