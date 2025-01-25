import 'package:craft_blend_project/services/authentication/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../configuration/config.dart';

class AddAdminPage extends StatefulWidget {
  const AddAdminPage({super.key});

  @override
  State<AddAdminPage> createState() => _AddAdminPageState();
}

class _AddAdminPageState extends State<AddAdminPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isLoading = false;

  Future<void> _addAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    final adminData = {
      "firstName": firstNameController.text.trim(),
      "lastName": lastNameController.text.trim(),
      "email": emailController.text.trim(),
      "phoneNumber": phoneController.text.trim(),
      "password": passwordController.text.trim(),
      "accountType": "A", // Admin-specific account type
    };

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(registration), // Use your backend admin registration endpoint
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(adminData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);

        final auth = AuthService();
        auth.signUpWithEmailPassword(
          emailController.text.trim(),
          passwordController.text.trim(),
          firstNameController.text.trim(),
          lastNameController.text.trim(),
          "A", // Admin account type
        );

        // Save token and user type to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('token', jsonResponse['token']);
        prefs.setString('userType', jsonResponse['userType']);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Admin added successfully!"),
            backgroundColor: Colors.greenAccent,
          ),
        );

        Navigator.pop(context); // Navigate back to the admin dashboard
      } else {
        final errorResponse = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add admin: ${errorResponse['message']}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error occurred: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
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
        color: Colors.white,
        image: DecorationImage(
          image: const AssetImage("assets/images/craftsBackground.jpg"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.1), BlendMode.dstATop),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            "Add New Admin",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white70),
          ),
          backgroundColor: myColor,
          elevation: 5,
          toolbarHeight: appBarHeight,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Enter Admin Details",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: firstNameController,
                    label: "First Name",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "First Name is required";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: lastNameController,
                    label: "Last Name",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Last Name is required";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: emailController,
                    label: "Email",
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null ||
                          !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return "Enter a valid email";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: phoneController,
                    label: "Phone Number",
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Phone Number is required";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: passwordController,
                    label: "Password",
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: confirmPasswordController,
                    label: "Confirm Password",
                    obscureText: true,
                    validator: (value) {
                      if (value != passwordController.text) {
                        return "Passwords do not match";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _addAdmin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: myColor,
                            shape: const StadiumBorder(),
                            elevation: 20,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text(
                            "Add Admin",
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white70),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: myColor),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: myColor),
        ),
      ),
      validator: validator,
    );
  }
}
