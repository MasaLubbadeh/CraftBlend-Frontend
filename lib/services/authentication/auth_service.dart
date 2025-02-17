import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  //instance of auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//get current user
  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  //sign in
  /*Future<UserCredential> signInWithEmainPassword(String email, password) async {
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
  }*/
/*  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Optionally update Firestore without overwriting existing fields
      await _firestore.collection("Users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid, 'email': email,
        'lastLogin': DateTime.now(), // Example of updating only specific fields
      }, SetOptions(merge: true));

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException code: ${e.code}');
      throw e.message ?? "An unexpected error occurred.";
    }
  }
*/

  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    try {
      // Sign in the user with the provided credentials
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Ensure the user is non-null before accessing their UID
      User? user = userCredential.user;
      if (user == null) {
        throw "User is null, sign-in failed";
      }

      // Optionally update Firestore with additional information without overwriting existing fields
      await _firestore.collection("Users").doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'lastLogin': DateTime.now(), // Update lastLogin timestamp
      }, SetOptions(merge: true));

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle specific authentication exceptions and print out the error code
      print('FirebaseAuthException code: ${e.code}');
      throw e.message ?? "An unexpected error occurred.";
    } catch (e) {
      // General error handling for unexpected errors
      print('Unexpected error: $e');
      throw "An unexpected error occurred.";
    }
  }

  //sign up
  /* Future<UserCredential> signUpWithEmainPassword(String email, password) async {
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
*/
// Sign up with email and password
  Future<UserCredential> signUpWithEmailPassword(String email, String password,
      String firstName, String lastName, String userType) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save user info in a separate document in Firestore
      _firestore.collection("Users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'firstName': firstName, // Save first name
        'lastName': lastName, // Save last name
        'userType': userType,
      }).then((value) {
        print("User info saved successfully!");
      }).catchError((error) {
        print("Failed to save user info: $error");
      });

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

// Sign up store with email and password
  Future<UserCredential> signUpStoreWithEmailPassword(
      String email, String password, String storeName, String userType) async {
    try {
      print("im inside firebase store signup");
      // Create user with email and password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save user info in a separate document in Firestore
      _firestore.collection("Users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'storeName': storeName, // Save first name
        'userType': userType,
      }).then((value) {
        print("User info saved successfully!");
      }).catchError((error) {
        print("Failed to save user info: $error");
      });

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

  // Re-authenticate the user
  Future<void> reauthenticate(String password) async {
    User? user = _auth.currentUser;

    if (user == null) {
      throw 'No user is currently logged in.';
    }

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      print("Re-authentication successful!");
    } on FirebaseAuthException catch (e) {
      print('Re-authentication failed: ${e.message}');
      throw 'Re-authentication failed: ${e.message}';
    }
  }

  //log out
  Future<void> signOut() async {
    return await _auth.signOut();
  }
}
