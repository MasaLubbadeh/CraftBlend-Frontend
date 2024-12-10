import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isSent; // true if sent, false if received
  final bool isImageMessage; // Optional: Check if it's an image message or text
  final String senderID;
  final String currentUserID;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSent,
    required this.senderID,
    required this.currentUserID,
    this.isImageMessage = false, // Option to support image messages
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: isSent ? myColor : Colors.grey[300],
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(12),
          child: isImageMessage
              ? Image.network(message) // If message is an image, load the URL
              : Text(
                  message,
                  style: TextStyle(
                    color: isSent ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
