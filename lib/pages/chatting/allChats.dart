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
  int userNumber = 0;
  int counter = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        //automaticallyImplyLeading: false,
        backgroundColor: myColor,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'C H A T S',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
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
              "No messages yet.",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          );
        }

        final userList = snapshot.data!;

        print("Stream data received: ${userList.length} users found.");
        for (var user in userList) {
          print("User data: $user");
        }
        userNumber = userList.length;
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
    // Use a FutureBuilder to check if the chat has messages
    return FutureBuilder(
      future: _hasMessages(currentUser.uid, userData["uid"]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While loading, show a placeholder or nothing
          return const SizedBox();
        }
    /*  if (currentUser == null || userData["email"] == currentUser.email) {
      return const SizedBox(); // Skip displaying the current user
    }*/

        if (snapshot.hasData && snapshot.data == true) {
          print("Building list item for user: ${userData["email"]}");
          //userNumber--;
          // Only show the user if there are messages
          return GestureDetector(
            onTap: () async {
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
        } else {
          counter++;
          print('counter value:$counter');
          print('number of users:$userNumber');

          if (counter == userNumber) {
            return SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * .8,
              child: const Center(
                child: Text(
                  "No messages",
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              ),
            );
          }

          // Skip displaying the user if there are no messages
          else
            return const SizedBox();
        }
      },
    );
  }

// Helper function to check if a chat has messages
  Future<bool> _hasMessages(String userID, String receiverID) async {
    try {
      final querySnapshot = await _chatService
          .getMessages(userID, receiverID)
          .first; // Get the first snapshot of the stream
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking messages: $e");
      return false;
    }
  }
}
