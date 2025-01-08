import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Feed/feedPage.dart';

class CreateStorePostPage extends StatefulWidget {
  @override
  _CreateStorePostPageState createState() => _CreateStorePostPageState();
}

class _CreateStorePostPageState extends State<CreateStorePostPage> {
  final TextEditingController _productDescriptionController =
      TextEditingController();
  final List<File> _selectedImages = [];
  int _currentPage = 0;

  String storeName = ''; // To hold the store name

  @override
  void initState() {
    super.initState();
    _loadStoreDetails();
  }

  Future<void> _loadStoreDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      storeName =
          prefs.getString('storeName') ?? 'My Store'; // Default store name
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
            'store_posts_images/${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';

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
    String productDescription = _productDescriptionController.text.trim();

    if (productDescription.isEmpty && _selectedImages.isEmpty) {
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
    await sendStorePostToBackend(
        context, productDescription, uploadedImageUrls);

    // Clear the form or navigate away
    setState(() {
      _productDescriptionController.clear();
      _selectedImages.clear();
    });

    // Optionally navigate to another page, e.g., Store Feed page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            FeedPage(), // Change to StoreFeedPage for store-related posts
      ),
    );
  }

  Future<void> sendStorePostToBackend(
      BuildContext context, String description, List<String> imageUrls) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? storeName = prefs.getString('storeName');
      String? token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Authentication token not found. Please log in again.')),
        );
        return;
      }
      Map<String, dynamic> postData = {
        "fullName": storeName,
        "content": description,
        "images": imageUrls, // Add uploaded image URLs
      };
      print(jsonEncode(postData));

      var response = await http.post(
        Uri.parse(createStorePost), // Use store-specific endpoint
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(postData),
      );
      print("response status code store post creation:");
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
                    "Post Created Successfully",
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
    return _productDescriptionController.text.isNotEmpty ||
        _selectedImages.isNotEmpty;
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
        title: Center(child: const Text("New Store Post")),
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
                    storeName,
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth * 0.04),
                  child: TextField(
                    controller: _productDescriptionController,
                    maxLines: null,
                    style: const TextStyle(color: Colors.black, fontSize: 18),
                    decoration: const InputDecoration(
                      hintText: "Describe your product...",
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
                      vertical: constraints.maxHeight * 0.02),
                  child: ElevatedButton(
                    onPressed: _pickImages,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(14),
                      backgroundColor: myColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.add_a_photo,
                          size: 20,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Add Images (Max 5)",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
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
        backgroundColor: Colors.black,
        title: const Text('Image Preview'),
      ),
      body: Center(
        child: Image.file(image),
      ),
    );
  }
}
