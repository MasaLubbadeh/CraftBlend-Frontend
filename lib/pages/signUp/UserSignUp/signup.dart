import 'dart:convert';

import 'package:flutter/material.dart';
import 'genreSelection.dart';
import 'package:http/http.dart' as http;
import '../../User/login_page.dart';

import '../../../configuration/config.dart';
import '../../../models/user_sign_up_data.dart';

class SignUpPage extends StatefulWidget {
  final SignUpData signUpData;

  const SignUpPage({super.key, required this.signUpData});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late Size mediaSize;
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool showPassword = false;
  final bool _isNotValid = false;

  // Form Key to validate fields
  final _formKey = GlobalKey<FormState>();

  Future<bool> _isEmailAvailable(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$checkEmail?email=$email'), // Update with your endpoint
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['status'];
      } else if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Email already in use: ${jsonDecode(response.body)['message']}"),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Error checking email availability: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error occurred: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Function to handle the sign-up button press
  void _handleSignUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      bool emailAvailable =
          await _isEmailAvailable(emailController.text.trim());
      if (emailAvailable) {
        // Proceed to Genre Selection if email is available
        SignUpData signUpData = SignUpData(
          firstName: firstNameController.text,
          lastName: lastNameController.text,
          email: emailController.text.trim(),
          phoneNumber: phoneController.text,
          password: passwordController.text.trim(),
          accountType: widget.signUpData.accountType,
        );

        // Navigate to Genre Selection Page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GenreSelectionApp(signUpData: signUpData),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    mediaSize = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        color: myColor,
        image: DecorationImage(
          image: const AssetImage("assets/images/craftsBackground.jpg"),
          fit: BoxFit.cover,
          colorFilter:
              ColorFilter.mode(myColor.withOpacity(0.1), BlendMode.dstATop),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [
          Positioned(bottom: -10, child: _buildBottom()),
        ]),
      ),
    );
  }

  Widget _buildBottom() {
    return SizedBox(
      width: mediaSize.width,
      height: mediaSize.height * .93,
      child: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey, // Form key to manage form validation
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create Account",
              style: TextStyle(
                  color: myColor, fontSize: 28, fontWeight: FontWeight.w500),
            ),
            _buildGreyText("Please sign up with your information"),
            const SizedBox(height: 20),
            _buildGreyText("First Name"),
            _buildInputField(firstNameController, validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your first name';
              }
              return null;
            }),
            const SizedBox(height: 12),
            _buildGreyText("Last Name"),
            _buildInputField(lastNameController, validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your last name';
              }
              return null;
            }),
            const SizedBox(height: 12),
            _buildGreyText("Email"),
            _buildInputField(emailController, isEmail: true,
                validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            }),
            const SizedBox(height: 12),
            _buildGreyText("Phone Number"),
            _buildNumberInputField(phoneController, validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            }),
            const SizedBox(height: 12),
            _buildGreyText("Password"),
            _buildInputField(passwordController, isPassword: true,
                validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              } else if (value.length < 6) {
                return 'Password must be at least 6 characters long';
              }
              return null;
            }),
            const SizedBox(height: 12),
            _buildGreyText("Confirm Password"),
            _buildInputField(confirmPasswordController, isPassword: true,
                validator: (value) {
              if (value == null || value != passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            }),
            const SizedBox(height: 18),
            _buildSignUpButton(),
            const SizedBox(height: 5),
            _buildGoToLogin(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInputField(TextEditingController controller,
      {String? Function(String?)? validator}) {
    return SizedBox(
      height: 40,
      child: TextFormField(
        controller: controller,
        decoration: const InputDecoration(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: myColor),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: myColor),
          ),
        ),
        validator: validator,
        keyboardType: TextInputType.phone,
      ),
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _handleSignUp,
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        elevation: 20,
        shadowColor: myColor,
        minimumSize: const Size.fromHeight(50),
      ),
      child: const Text(
        "Next",
        style: TextStyle(fontWeight: FontWeight.w700, color: myColor),
      ),
    );
  }

  Widget _buildGreyText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.grey),
    );
  }

  Widget _buildInputField(TextEditingController controller,
      {bool isPassword = false,
      bool isEmail = false,
      String? Function(String?)? validator}) {
    return SizedBox(
      height: 40,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                      color: myColor),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                )
              : null,
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: myColor),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: myColor),
          ),
        ),
        obscureText: isPassword ? !showPassword : false,
        validator: validator,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      ),
    );
  }

  Widget _buildGoToLogin() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildGreyText("Already have an account?"),
          const SizedBox(width: 0),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              elevation: 0,
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            ),
            child: const Text(
              "Log In",
              style: TextStyle(color: myColor),
            ),
          ),
        ],
      ),
    );
  }
}
