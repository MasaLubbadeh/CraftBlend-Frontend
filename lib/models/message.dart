import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String? message;
  final Timestamp timestamp;
  final String? imageUrl;

  Message({
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    this.message,
    this.imageUrl,
    required this.timestamp,
  });

  // Factory method to create a Message instance from a map (e.g., Firestore document snapshot)
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderID: map['senderID'] ?? '',
      senderEmail: map['senderEmail'] ?? '',
      receiverID: map['receiverID'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  // Method to convert a Message instance to a map for storage (e.g., Firestore)
  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'receiverID': receiverID,
      'message': message,
      'timestamp': timestamp,
      'imageUrl': imageUrl,
    };
  }
}
