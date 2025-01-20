import 'package:flutter/material.dart';
import '../configuration/config.dart';

class MessageBubble extends StatelessWidget {
  final String? imageUrl; // URL of the image if the message is an image
  final String message; // The text message
  final bool isSent; // Whether the message is sent by the current user
  final String senderID; // The ID of the sender
  final String currentUserID; // The ID of the current user
  final String timestamp; // The timestamp of the message

  const MessageBubble({
    required this.message,
    required this.isSent,
    required this.senderID,
    required this.currentUserID,
    required this.timestamp,
    this.imageUrl, // Optional parameter for image URL
    Key? key,
  }) : super(key: key);

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
            if (imageUrl != null && imageUrl!.isNotEmpty)
              // Display the image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.red,
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              )
            else
              // Display the text message
              Text(
                message,
                style: TextStyle(
                  color: isSent ? Colors.white : Colors.black,
                ),
              ),
            const SizedBox(height: 5),
            // Display the timestamp
            Text(
              timestamp,
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
