import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class ChatService {
  //get instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  //get message
}
