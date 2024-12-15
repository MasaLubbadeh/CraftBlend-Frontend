import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class AudioUploader {
  /// Uploads an audio file to Firebase Storage and returns the URL of the uploaded file.
  Future<String?> uploadAudio(String filePath) async {
    try {
      final File file = File(filePath);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('voice_messages/${DateTime.now().millisecondsSinceEpoch}.aac');

      final uploadTask = await storageRef.putFile(file);

      // Return the download URL of the uploaded file
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading audio: $e");
      return null;
    }
  }
}
