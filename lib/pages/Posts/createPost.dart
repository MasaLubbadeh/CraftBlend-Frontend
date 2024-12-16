import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../categoriesPage.dart'; // Add this import

class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  final List<File> _selectedImages = [];
  int _currentPage = 0;

  String firstName = ''; // To hold the first name
  String lastName = ''; // To hold the last name

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName') ?? 'Guest';
      lastName = prefs.getString('lastName') ?? 'User';
    });
  }

  Future<void> sendPostToBackend(BuildContext context, String content) async {
    try {
      // Fetch user details from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');
      String? firstName = prefs.getString('firstName');
      String? lastName = prefs.getString('lastName');
      print("email:{$email}");
      print("firstname:{$firstName}");
      print("lastname:{$lastName}");

      // Validate if the necessary data exists
      /*  if (email == null || firstName == null || lastName == null) {
        throw Exception("User details are missing from SharedPreferences");
      }*/

      // API endpoint for storing the post
      // String url = "https://your-backend-url.com/api/posts";

      // Prepare post data
      Map<String, dynamic> postData = {
        // "email": email,
        "firstName": firstName,
        "lastName": lastName,
        "content": content, // Post content
      };

      // Make the HTTP POST request
      var response = await http.post(
        Uri.parse(createPost),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(postData),
      );

      // Check response status
      if (response.statusCode == 201) {
        print("it worked");
        // Show success dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 50,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Posted Successfully",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                      Navigator.pop(context); // Navigate back
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text("OK"),
                  ),
                ),
              ],
            );
          },
        );
      } else {
        print("Failed to save post: ${response.statusCode}");
        print("Response body: ${response.body}");
        //print("message:${response.m}")
      }
    } catch (e) {
      print("Error sending post to backend: $e");
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker _picker = ImagePicker();
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        if (_selectedImages.length + pickedFiles.length <= 5) {
          _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
        } else {
          int remaining = 5 - _selectedImages.length;
          _selectedImages.addAll(
              pickedFiles.take(remaining).map((file) => File(file.path)));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Maximum of 5 images allowed.")),
          );
        }
      });
    }
  }

  bool get _isPostButtonEnabled {
    return _contentController.text.isNotEmpty || _selectedImages.isNotEmpty;
  }

  void _submitPost() async {
    String content = _contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Post content cannot be empty")),
      );
      return;
    }

    await sendPostToBackend(context, content);

    // Clear the form or navigate away
    setState(() {
      _contentController.clear();
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FeedPage(),
      ),
    );
  }

  void _removeImage(File image) {
    setState(() {
      _selectedImages.remove(image);
    });
  }

  void _viewImageFullScreen(File image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageView(image: image),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Center(child: const Text("New Post")),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isPostButtonEnabled ? _submitPost : null,
            child: Text(
              "Post",
              style: TextStyle(
                color: _isPostButtonEnabled ? myColor : Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundImage:
                        NetworkImage('https://via.placeholder.com/150'),
                  ),
                  title: Text(
                    "$firstName $lastName",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth * 0.04),
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    style: const TextStyle(color: Colors.black, fontSize: 18),
                    decoration: const InputDecoration(
                      hintText: "What's new?",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                if (_selectedImages.isNotEmpty)
                  Column(
                    children: [
                      SizedBox(
                        height: constraints.maxWidth * 0.7,
                        child: Container(
                          color: Colors.grey.shade300,
                          child: PageView.builder(
                            itemCount: _selectedImages.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  GestureDetector(
                                    onTap: () => _viewImageFullScreen(
                                        _selectedImages[index]),
                                    child: Center(
                                      child: AspectRatio(
                                        aspectRatio: 1.0,
                                        child: Container(
                                          margin: EdgeInsets.symmetric(
                                              horizontal:
                                                  constraints.maxWidth * 0.02),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            image: DecorationImage(
                                              image: FileImage(
                                                  _selectedImages[index]),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _removeImage(_selectedImages[index]),
                                      child: Icon(
                                        Icons.cancel,
                                        color: Colors.grey,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _selectedImages.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            width: _currentPage == index ? 12.0 : 8.0,
                            height: _currentPage == index ? 12.0 : 8.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  _currentPage == index ? myColor : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth * 0.04,
                      vertical: constraints.maxHeight * 0.01),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_outlined, color: myColor),
                        onPressed: _pickImages,
                      ),
                      Text(
                        "${_selectedImages.length}/5",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final File image;

  const FullScreenImageView({Key? key, required this.image}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 3.0,
          child: Image.file(image, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
