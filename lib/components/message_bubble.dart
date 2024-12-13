import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isSent;
  final String senderID;
  final String currentUserID;
  final String timestamp; // Add this property

  MessageBubble({
    required this.message,
    required this.isSent,
    required this.senderID,
    required this.currentUserID,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSent ? myColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment:
              isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isSent ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              timestamp, // Display the timestamp
              style: TextStyle(
                fontSize: 10,
                color: isSent ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
