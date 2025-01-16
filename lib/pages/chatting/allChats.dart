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
  String fullName = '';
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

      if (userDoc.exists) {
        final user = userDoc.data()!;
        // Check if the document has firstName and lastName fields
        if (user.containsKey('firstName') && user.containsKey('lastName')) {
          final String firstName = user['firstName'] ?? 'NO';
          final String lastName = user['lastName'] ?? 'User';
          fullName = '$firstName $lastName';
          return fullName;
        }
        // Otherwise, check for storeName
        else if (user.containsKey('storeName')) {
          final String storeName = user['storeName'] ?? 'Unknown Store';
          fullName = storeName;
          return fullName;
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
        print("Stream connection state: ${snapshot.connectionState}");
        if (snapshot.hasError) {
          print("Stream error: ${snapshot.error}");
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
          print("Waiting for stream data...");
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print("Stream has no data or is empty.");
          return const Center(
            child: Text(
              "No users found.",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          );
        }

        final userList = snapshot.data!;

        print("Stream data received: ${userList.length} users found.");
        for (var user in userList) {
          print("User data: $user");
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          itemCount: userList.length,
          itemBuilder: (context, index) {
            final userData = userList[index];
            return _buildUserListItem(userData, context);
          },
        );
      },
    );
  }

  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null || userData["email"] == currentUser.email) {
      print("Skipping current user: ${userData["email"]}");

      return const SizedBox(); // Skip displaying the current user
    }
    print("Building list item for user: ${userData["email"]}");

    return GestureDetector(
      onTap: () async {
        // final fullNameFetched = await _fetchFullName(userData["email"]);
        // print("Full name fetched: $fullNameFetched");
//fullName=

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              recieverEmail: userData["email"],
              receiverID: userData["uid"],
              firstName: userData["firstName"] ?? "NO",
              lastName: userData["lastName"] ?? "NAME",
              fullName: userData["storeName"] ?? "NAME",
              userType: userData["userType"] ?? "NOTYPE",
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
                      'https://picsum.photos/400/400', // Default placeholder
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
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
