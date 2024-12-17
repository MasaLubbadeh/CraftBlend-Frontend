import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:craft_blend_project/models/message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class ChatService {
  //get instance of firestore & auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  //get users
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      print("Snapshot data: ${snapshot.docs.length} documents found");
      return snapshot.docs.map((doc) {
        //go through each individual user
        final user = doc.data();
        print("User data: $user"); // Check if you are getting user data here
        return user;
      }).toList();
    });
  }

  //send message
  Future<void> sendMessage(
    String receiverID,
    message,
  ) async {
    //get current user info
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();
    //create a new message
    Message newMessage = Message(
        senderID: currentUserID,
        senderEmail: currentUserEmail,
        receiverID: receiverID,
        message: message,
        timestamp: timestamp);
    //construct chat room ID for the two users (sorted to ensure uniqueness)
    List<String> ids = [currentUserID, receiverID];
    ids.sort(); // Sort the IDs (this ensures that the chat room id is the same for any 2 people)
    String chatRoomID = ids.join("_"); // Combine with an underscore
    //add message to database
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());

    print("Message sent to chat room $chatRoomID.");
  }

  //get message
  Stream<QuerySnapshot> getMessages(String userID, receiverID) {
    // Construct the chat room ID for the two users (sorted)
    List<String> ids = [userID, receiverID];
    ids.sort();
    String chatRoomID = ids.join("_");

    // Stream messages from the database
    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }
}
