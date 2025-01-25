import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../models/store_sign_up_data.dart';
import '../StoreSignUp/store_sign_up_page.dart';

class StoreSignUpLogoPage extends StatefulWidget {
  final StoreSignUpData storeSignUpData;

  const StoreSignUpLogoPage({super.key, required this.storeSignUpData});

  @override
  _StoreSignUpLogoPageState createState() => _StoreSignUpLogoPageState();
}

class _StoreSignUpLogoPageState extends State<StoreSignUpLogoPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImageToFirebase() async {
    if (_image == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete'),
          content: const Text('Please add a photo before saving.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String uniqueFileName =
          'storeLogos_images/logo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      UploadTask uploadTask =
          FirebaseStorage.instance.ref().child(uniqueFileName).putFile(_image!);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      TaskSnapshot snapshot = await uploadTask;
      if (snapshot.state == TaskState.success) {
        String downloadUrl = await snapshot.ref.getDownloadURL();
        setState(() {
          _isUploading = false;
        });

        // Save the download URL to the StoreSignUpData object
        widget.storeSignUpData.logo = downloadUrl;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Profile image uploaded successfully!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        // Navigate to the next page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StoreSignUpPage(
              signUpData: widget.storeSignUpData,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Image upload failed: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _skipProfile() {
    print("Profile creation skipped");

    // Navigate to the next page without setting a logo
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoreSignUpPage(
          signUpData: widget.storeSignUpData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Store Logo',
          style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: screenWidth * .06),
        ),
        foregroundColor: Colors.white70,
        backgroundColor: myColor,
        elevation: 5,
        toolbarHeight: appBarHeight,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: screenWidth * 0.3,
                      backgroundImage:
                          _image != null ? FileImage(_image!) : null,
                      child: _image == null
                          ? const Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  const Text(
                    "This step is optional. You can skip it.",
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  if (_isUploading) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: _uploadProgress),
                  ],
                  SizedBox(
                    width: screenWidth * 0.6,
                    child: ElevatedButton(
                      onPressed: _uploadImageToFirebase,
                      child: const Text("Next"),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextButton(
                    onPressed: _skipProfile,
                    child: const Text(
                      "Skip",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
