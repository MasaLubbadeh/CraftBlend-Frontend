import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';

import '../../services/authentication/auth_service.dart';
import '../../services/chat/chat_service.dart';
import '../../components/message_bubble.dart';

class ChatPage extends StatefulWidget {
  final String recieverEmail;
  final String receiverID;

  ChatPage({super.key, required this.recieverEmail, required this.receiverID});

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

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        // Check if the text field is not empty
        _isTyping = _messageController.text.isNotEmpty;
      });
    });
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
      stream: _chatService.getMessages(widget.receiverID, senderID),
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

    return MessageBubble(
      message: data['message'],
      isSent: isCurrentUser,
      senderID: data['senderID'],
      currentUserID: _authService.getCurrentUser()!.uid,
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
              backgroundImage:
                  NetworkImage('https://your-profile-image-url.com'),
            ),
            const SizedBox(width: 10),
            Text(
              widget.recieverEmail,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.video_call,
              color: myColor,
            ),
            onPressed: () {
              // Video call action
            },
          ),
          IconButton(
            icon: Icon(
              Icons.phone,
              color: myColor,
            ),
            onPressed: () {
              // Phone call action
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()), // Display all messages
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      hintStyle: TextStyle(
                        fontWeight: FontWeight.w300,
                        color: Colors.grey[400],
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                        borderSide: BorderSide(
                          color: Colors.grey[400]!,
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                        borderSide: BorderSide(
                          color: Colors.grey[400]!,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                        borderSide: BorderSide(
                          color: myColor,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 1),
                _isTyping
                    ? IconButton(
                        icon: Icon(Icons.arrow_circle_up),
                        color: myColor,
                        iconSize: 40,
                        onPressed: _sendMessage,
                      )
                    : SizedBox.shrink(), // Hide the button when no text
              ],
            ),
          ),
        ],
      ),
    );
  }
}
