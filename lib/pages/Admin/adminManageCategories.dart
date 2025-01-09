import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../configuration/config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  _ManageCategoriesPageState createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  final List<Map<String, dynamic>> categories = [];

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse(getAllCategories),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> categoryList =
            jsonDecode(response.body)['categories'];

        setState(() {
          categories.clear();
          categories.addAll(categoryList.map((category) => {
                'id': category['_id'],
                'name': category['name'],
                'description': category['description'],
                'image': category[
                    'image'], // Add your image handling logic if needed
              }));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to fetch categories: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred: $e')),
      );
    }
  }

  Future<void> _addCategory() async {
    if (nameController.text.isNotEmpty) {
      // Disable button while uploading
      setState(() {
        _isUploading = true;
      });

      String? imageUrl = await _uploadImageToFirebase(_selectedImage!);
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }

      try {
        final response = await http.post(
          Uri.parse(addNewCategory),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': nameController.text,
            'description': descriptionController.text,
            'image': imageUrl, // Include the image URL here
          }),
        );

        if (response.statusCode == 201) {
          final newCategory = jsonDecode(response.body)['category'];

          setState(() {
            categories.add({
              'id': newCategory['_id'],
              'name': newCategory['name'],
              'description': newCategory['description'],
              'image': imageUrl, // Save the image URL in the local list
            });
            _isUploading = false;
          });

          nameController.clear();
          descriptionController.clear();
          _selectedImage = null;

          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category added successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add category: ${response.body}')),
          );
          setState(() {
            _isUploading = false;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred: $e')),
        );
        setState(() {
          _isUploading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and select an image')),
      );
    }
  }

  Future<void> _confirmDeleteCategory(int index) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(index);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(int index) async {
    try {
      final categoryId = categories[index]['id'];
      final response = await http.delete(
        Uri.parse('$deleteCategory/$categoryId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          categories.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete category: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred: $e')),
      );
    }
  }

  Future<void> signInAnonymously() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      print("User signed in anonymously");
    } catch (e) {
      print("Failed to sign in anonymously: $e");
    }
  }

  Future<String?> _uploadImageToFirebase(File image) async {
    try {
      // Make sure user is logged in
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      // Get the category name and sanitize it for the file name
      String categoryName = nameController.text
          .trim()
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_');

      // Generate a unique file name based on the category name and the current time
      String fileName =
          '${categoryName}_${DateTime.now().millisecondsSinceEpoch.toString()}.jpg';

      // Upload the image to Firebase Storage
      UploadTask uploadTask = FirebaseStorage.instance
          .ref()
          .child('category_images/$fileName')
          .putFile(image);

      // Track upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      TaskSnapshot snapshot = await uploadTask;
      if (snapshot.state == TaskState.success) {
        // Get the download URL of the uploaded image
        String downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    }
    return null;
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add New Category'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'Enter category name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter category description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      await _pickImage();
                      setDialogState(() {});
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.grey),
                      ),
                      child: _selectedImage != null
                          ? Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            )
                          : const Center(
                              child: Text(
                                'Tap to select image',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                    ),
                  ),
                  if (_isUploading) ...[
                    const SizedBox(height: 16),
                    Stack(
                      children: [
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: Colors.grey,
                          color: Colors.green,
                        ),
                        Center(
                          child: Text(
                            '${(_uploadProgress * 100).toStringAsFixed(2)}%',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: _isUploading ? null : _addCategory,
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'Manage Categories',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [myColor.withOpacity(0.9), Colors.blueGrey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _showAddCategoryDialog,
                icon:
                    const Icon(Icons.add_circle_rounded, color: Colors.white70),
                label: const Text(
                  "Add New Category",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: myColor,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 24.0),
                ),
              ),
              const SizedBox(height: 16),
              ...categories.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> category = entry.value;

                return Card(
                  color: const Color.fromARGB(171, 243, 229, 245),
                  elevation: 6,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 120,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 5.0, horizontal: 10.0),
                      child: Row(
                        children: [
                          category['image'].isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    category['image'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.category,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                Text(
                                  category['name'],
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: myColor,
                                      letterSpacing: 1),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  category['description'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDeleteCategory(index),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
