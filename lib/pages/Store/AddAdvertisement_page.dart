import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../configuration/config.dart';

class AddAdvertisementPage extends StatefulWidget {
  const AddAdvertisementPage({Key? key}) : super(key: key);

  @override
  _AddAdvertisementPageState createState() => _AddAdvertisementPageState();
}

class _AddAdvertisementPageState extends State<AddAdvertisementPage> {
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Cannot select past dates
      lastDate: DateTime.now().add(const Duration(days: 365)), // Within a year
    );
    if (pickedDate != null) {
      setState(() {
        startDateController.text = pickedDate.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (startDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date first.')),
      );
      return;
    }

    final DateTime startDate = DateTime.parse(startDateController.text);
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          startDate.add(const Duration(days: 1)), // Minimum 1 day after
      firstDate: startDate.add(const Duration(days: 1)),
      lastDate: startDate.add(const Duration(days: 7)), // Max 7 days after
    );

    if (pickedDate != null) {
      setState(() {
        endDateController.text = pickedDate.toIso8601String().split('T')[0];
      });
    }
  }

  Future<String?> _uploadImageToFirebase(File image) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await FirebaseAuth.instance.signInAnonymously();
        user = FirebaseAuth.instance.currentUser;
      }

      final String uniqueFileName =
          'advertisements_images/${DateTime.now().millisecondsSinceEpoch.toString()}';

      UploadTask uploadTask =
          FirebaseStorage.instance.ref(uniqueFileName).putFile(image);

      TaskSnapshot snapshot = await uploadTask;
      if (snapshot.state == TaskState.success) {
        return await snapshot.ref.getDownloadURL();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    }
    return null;
  }

  Future<void> _uploadAdvertisement() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please upload an image for the advertisement')),
      );
      return;
    }

    if (startDateController.text.isEmpty || endDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final String? imageUrl = await _uploadImageToFirebase(_selectedImage!);
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload advertisement image')),
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final Map<String, dynamic> advertisementData = {
        'startDate': startDateController.text,
        'endDate': endDateController.text,
        'image': imageUrl,
      };

      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Authentication token not found. Please log in again.')),
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(addNewAdvertisement),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(advertisementData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advertisement uploaded successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to upload advertisement: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
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
          'Add Advertisement',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white70,
                        border: Border.all(
                          color: myColor,
                        ),
                      ),
                      child: _selectedImage != null
                          ? Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: myColor,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _selectStartDate,
                    child: AbsorbPointer(
                      child: _buildInputField(
                          startDateController, 'Start Date (YYYY-MM-DD)'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _selectEndDate,
                    child: AbsorbPointer(
                      child: _buildInputField(
                          endDateController, 'End Date (YYYY-MM-DD)'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSubmitButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String labelText) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: ElevatedButton(
        onPressed: _uploadAdvertisement,
        style: ElevatedButton.styleFrom(
          backgroundColor: myColor,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
        ),
        child: const Text(
          'Submit Advertisement',
          style: TextStyle(fontSize: 15, color: Colors.white),
        ),
      ),
    );
  }
}
