import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Feed/feedPage.dart'; // Add this import

class CreateUserPostPage extends StatefulWidget {
  final String userID;
  CreateUserPostPage({required this.userID});
  @override
  _CreateUserPostPageState createState() => _CreateUserPostPageState();
}

class _CreateUserPostPageState extends State<CreateUserPostPage> {
  final TextEditingController _contentController = TextEditingController();
  final List<File> _selectedImages = [];
  int _currentPage = 0;

  String firstName = ''; // To hold the first name
  String lastName = ''; // To hold the last name
  String userType = '';

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
      // userType = prefs.getString('userType') ?? 'No Type';
    });
  }

  Future<List<String>> _uploadImagesToFirebase(List<File> images) async {
    List<String> downloadUrls = [];
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        await FirebaseAuth.instance.signInAnonymously();
        user = FirebaseAuth.instance.currentUser;
      }

      for (var image in images) {
        String uniqueFileName =
            'posts_images/${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';

        UploadTask uploadTask =
            FirebaseStorage.instance.ref().child(uniqueFileName).putFile(image);

        TaskSnapshot snapshot = await uploadTask;

        if (snapshot.state == TaskState.success) {
          String downloadUrl = await snapshot.ref.getDownloadURL();
          downloadUrls.add(downloadUrl);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    }

    return downloadUrls;
  }

  Future<void> _submitPost() async {
    String content = _contentController.text.trim();

    if (content.isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Post content cannot be empty or select at least one image")),
      );
      return;
    }

    // Upload images to Firebase
    List<String> uploadedImageUrls =
        await _uploadImagesToFirebase(_selectedImages);

    if (uploadedImageUrls.isEmpty && _selectedImages.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload images. Please try again.")),
      );
      return;
    }

    // Add uploaded image URLs to post data
    await sendPostToBackend(context, content, uploadedImageUrls);

    // Clear the form or navigate away
    setState(() {
      _contentController.clear();
      _selectedImages.clear();
    });

    // Optionally navigate to another page
    /* Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => FeedPage(),
    ),
  ); */
  }

  Future<void> sendPostToBackend(
      BuildContext context, String content, List<String> imageUrls) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');
      String? firstName = prefs.getString('firstName');
      String? lastName = prefs.getString('lastName');
      print('firstname create user post:$firstName');
      print('lastname create user post:$lastName');
      print('email create user post:$email');
      String? token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Authentication token not found. Please log in again.')),
        );
        return;
      }
      String storeID = widget.userID;
      Map<String, dynamic> postData = {
        "firstName": firstName,
        "lastName": lastName,
        "content": content,
        "images": imageUrls, // Add uploaded image URLs
        "store_id": storeID,
      };

      var response = await http.post(
        Uri.parse(createUserPost),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(postData),
      );
      print("response status code user post creation:");
      print(response.statusCode);
      if (response.statusCode == 201) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save post. Try again later.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending post: $e")),
      );
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
    double appBarHeight = MediaQuery.of(context).size.height * 0.08;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'Feedback',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isPostButtonEnabled ? _submitPost : null,
            child: Text(
              "Post",
              style: TextStyle(
                color: _isPostButtonEnabled ? myColor : Colors.white,
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
            child: Center(
              child: FractionallySizedBox(
                widthFactor:
                    0.9, // Makes the content width dynamic and responsive
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Note outside the card
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                      child: Text(
                        "Post your feedback about this store and add images (up to 5).",
                        style: TextStyle(
                          color: myColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Card widget
                    Card(
                      color: Colors.white, // Set card color to white
                      margin: const EdgeInsets.all(
                          16.0), // Adds some space around the card
                      elevation: 4, // Optional: Adds a shadow effect
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16), // Rounded corners
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(
                            16.0), // Padding inside the card
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: const CircleAvatar(
                                backgroundImage: NetworkImage(
                                    'https://via.placeholder.com/150'),
                              ),
                              title: Text(
                                "$firstName $lastName",
                                style: TextStyle(
                                    color: myColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: constraints.maxWidth * 0.04,
                              ),
                              child: TextField(
                                controller: _contentController,
                                maxLines: null,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                ),
                                decoration: const InputDecoration(
                                  hintText: "What's on your mind?",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: 10),
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
                                                onTap: () =>
                                                    _viewImageFullScreen(
                                                        _selectedImages[index]),
                                                child: Center(
                                                  child: AspectRatio(
                                                    aspectRatio: 1.0,
                                                    child: Container(
                                                      margin:
                                                          EdgeInsets.symmetric(
                                                        horizontal: constraints
                                                                .maxWidth *
                                                            0.02,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        image: DecorationImage(
                                                          image: FileImage(
                                                              _selectedImages[
                                                                  index]),
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
                                                  onTap: () => _removeImage(
                                                      _selectedImages[index]),
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
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      _selectedImages.length,
                                      (index) => Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4.0),
                                        width:
                                            _currentPage == index ? 12.0 : 8.0,
                                        height:
                                            _currentPage == index ? 12.0 : 8.0,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _currentPage == index
                                              ? myColor
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: constraints.maxWidth * 0.04,
                                ),
                                child: OutlinedButton.icon(
                                  onPressed: _pickImages,
                                  icon:
                                      Icon(Icons.photo_library, color: myColor),
                                  label: Text(
                                    "Add Images",
                                    style: TextStyle(color: myColor),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0), // Space at the bottom
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
