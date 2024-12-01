import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../configuration/config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _saveProfile() {
    if (_image != null) {
      // Save the profile image here
      print("Profile Saved: Image Path - ${_image!.path}");
    } else {
      // Show an alert if no image is selected
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete'),
          content: const Text('Please add a photo.'),
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
    // Handle skip action here
    print("Profile creation skipped");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to make the UI responsive
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile Photo',
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
            // Center the entire content
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center the column vertically
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center items horizontally
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: screenWidth *
                          0.3, // Adjust size based on screen width
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
                  SizedBox(
                      height:
                          screenHeight * 0.02), // Responsive vertical spacing
                  const Text(
                    "This step is optional. You can skip it.",
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                      height: screenHeight *
                          0.04), // Additional space before buttons
                  SizedBox(
                    width: screenWidth * 0.6, // Adjust button width
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text("Save Profile"),
                    ),
                  ),
                  SizedBox(
                      height:
                          screenHeight * 0.01), // Responsive vertical spacing
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
