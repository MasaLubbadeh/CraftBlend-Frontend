import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this package for date formatting

import '../../services/authentication/auth_service.dart';
import '../../services/chat/chat_service.dart';
import '../../components/message_bubble.dart';

class ChatPage extends StatefulWidget {
  final String recieverEmail;
  final String receiverID;
  final String firstName; // Add this parameter
  final String lastName; // Add this parameter

  ChatPage({
    super.key,
    required this.recieverEmail,
    required this.receiverID,
    required this.firstName,
    required this.lastName,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Text controller
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;

  // Chat and auth services
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  // To store the receiver's profile details
  String receiverFirstName = '';
  String receiverLastName = '';
  String receiverProfileImage =
      'https://via.placeholder.com/150'; // Placeholder image

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        // Check if the text field is not empty
        _isTyping = _messageController.text.isNotEmpty;
      });
    });
    receiverFirstName = widget.firstName;
    receiverLastName = widget.lastName;
  }

  // Fetch receiver details from Firestore
  void _fetchReceiverDetails() async {
    try {
      print("im here0");

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverID) // Get user by receiver's ID
          .get();
      print("im here1");
      if (userDoc.exists) {
        print("im here2");

        final userData = userDoc.data()!;
        setState(() {
          receiverFirstName = userData['firstName'] ?? 'Unknown';
          receiverLastName = userData['lastName'] ?? 'User';
          receiverProfileImage = userData['profilePicture'] ??
              'https://via.placeholder.com/150'; // Default placeholder
        });
      } else
        print("user does not exist");
    } catch (e) {
      print("Failed to fetch user details: $e");
    }
  }

  // Send message
  void _sendMessage() async {
    final String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      try {
        print(
            "Sending message to receiverID: ${widget.receiverID}"); // Debug log
        await _chatService.sendMessage(widget.receiverID, message);
        _messageController.clear(); // Clear after sending
      } catch (e) {
        print("Failed to send message: $e");
      }
    }
  }

  // Build message list
  Widget _buildMessageList() {
    String senderID = _authService.getCurrentUser()!.uid;

    return StreamBuilder(
      stream: _chatService.getMessages(senderID, widget.receiverID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading messages."));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          children:
              snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

// Build message item
  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    bool isCurrentUser = data['senderID'] == _authService.getCurrentUser()!.uid;

    // Extract and format the timestamp
    Timestamp? timestamp = data['timestamp'];
    String formattedTime = '';
    if (timestamp != null) {
      DateTime dateTime = timestamp.toDate();
      formattedTime =
          DateFormat('hh:mm a').format(dateTime); // Format as 12-hour time
    }

    return MessageBubble(
      message: data['message'],
      isSent: isCurrentUser,
      senderID: data['senderID'],
      currentUserID: _authService.getCurrentUser()!.uid,
      timestamp: formattedTime, // Pass the formatted timestamp to MessageBubble
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(receiverProfileImage),
            ),
            const SizedBox(width: 10),
            Text(
              '$receiverFirstName $receiverLastName',
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: _isTyping ? Colors.blue : Colors.grey,
                  ),
                  onPressed: _isTyping ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
