import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  //instance of auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  //sign in
  Future<UserCredential> signInWithEmainPassword(String email, password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      //save user info in a separate doc
      _firestore
          .collection("Users")
          .doc(userCredential.user!.uid)
          .set({'uid': userCredential.user!.uid, 'email': email});
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException code: ${e.code}');
      print('FirebaseAuthException message: ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          throw 'No user found for that email.';
        case 'wrong-password':
          throw 'Wrong password provided.';
        default:
          throw 'An unexpected error occurred: ${e.message}';
      }
    }
  }

  //sign up
  Future<UserCredential> signUpWithEmainPassword(String email, password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      //save user info in a separate doc
      _firestore
          .collection("Users")
          .doc(userCredential.user!.uid)
          .set({'uid': userCredential.user!.uid, 'email': email});
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException code: ${e.code}');
      print('FirebaseAuthException message: ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          throw 'No user found for that email.';
        case 'wrong-password':
          throw 'Wrong password provided.';
        default:
          throw 'An unexpected error occurred: ${e.message}';
      }
    }
  }

  //log out
  Future<void> signOut() async {
    return await _auth.signOut();
  }
}
