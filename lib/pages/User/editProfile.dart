import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../configuration/config.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  String? _originalFirstName;
  String? _originalLastName;
  String? _originalPhoneNumber;

  bool _isSaving = false; // to track saving state
  bool hasChanges = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token != null) {
      final response = await http.get(
        Uri.parse(getPersonalInfo),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _originalFirstName = data['user']['firstName'] ?? '';
          _originalLastName = data['user']['lastName'] ?? '';
          _originalPhoneNumber = data['user']['phoneNumber'] ?? '';

          _firstNameController.text = _originalFirstName!;
          _lastNameController.text = _originalLastName!;
          _phoneNumberController.text = _originalPhoneNumber!;

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [myColor.withOpacity(0.9), Colors.blueGrey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: DecorationImage(
          image: const AssetImage("assets/images/craftsBackground.jpg"),
          fit: BoxFit.cover,
          colorFilter:
              ColorFilter.mode(myColor.withOpacity(0.05), BlendMode.dstATop),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: myColor,
          toolbarHeight: appBarHeight,
          title: const Text(
            "Edit Profile",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Edit the fields below to update your information:",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        "First Name",
                        _firstNameController,
                        Icons.person,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        "Last Name",
                        _lastNameController,
                        Icons.person,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        "Phone Number",
                        _phoneNumberController,
                        Icons.phone,
                        isNumber: true,
                      ),
                      const SizedBox(height: 24),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInputField(
      String label, TextEditingController controller, IconData icon,
      {bool isNumber = false}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            Icon(icon, color: myColor),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType:
                    isNumber ? TextInputType.phone : TextInputType.text,
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(color: Colors.black54),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  _checkForChanges();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: hasChanges && !_isSaving ? _saveChanges : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Text(
                "Save Changes",
                style: TextStyle(fontSize: 18, color: myColor),
              ),
      ),
    );
  }

  void _checkForChanges() {
    setState(() {
      hasChanges = (_firstNameController.text != _originalFirstName) ||
          (_lastNameController.text != _originalLastName) ||
          (_phoneNumberController.text != _originalPhoneNumber);
    });
  }

  Future<void> _saveChanges() async {
    if (!hasChanges) return;

    setState(() {
      _isSaving = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token != null) {
      final response = await http.post(
        Uri.parse(updateUserPersonalInfo),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'phoneNumber': _phoneNumberController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your information has been updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Error saving changes: please make sure that you entered valid data'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    setState(() {
      _isSaving = false;
    });
  }
}
