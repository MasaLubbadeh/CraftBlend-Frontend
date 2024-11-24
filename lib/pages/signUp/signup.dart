import 'dart:convert';

import 'package:flutter/material.dart';
import 'genreSelection.dart';
import 'package:http/http.dart' as http;

import '../../configuration/config.dart';
import '../../models/sign_up_data.dart';

class SignUpPage extends StatefulWidget {
  // const SignUpPage({super.key});
  final SignUpData signUpData;

  const SignUpPage({super.key, required this.signUpData});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late Color myColor;
  late Size mediaSize;
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController =
      TextEditingController(); // New phone number field
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool showPassword = false; // Variable to track password visibility

  bool _isNotValid = false;

  void registerUser() async {
    if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      var regbody = {
        "email": emailController.text,
        "password": passwordController.text
      };
      var response = await http.post(
        Uri.parse(registration),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(regbody),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == "success") {
          print("Registration successful!");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Registration failed: ${jsonResponse['message']}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Server error: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      setState(() {
        _isNotValid = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Fields cannot be empty!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    myColor = const Color(0xff456268);
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
          Positioned(bottom: 0, child: _buildBottom()),
        ]),
      ),
    );
  }

  Widget _buildBottom() {
    return SizedBox(
      width: mediaSize.width,
      height: mediaSize.height * .9,
      child: Card(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        )),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      // Makes the page scrollable
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Create Account",
            style: TextStyle(
                color: myColor, fontSize: 28, fontWeight: FontWeight.w500),
          ),
          _buildGreyText("Please sign up with your information"),
          const SizedBox(height: 20),
          _buildGreyText("First Name"),
          _buildInputField(firstNameController),
          const SizedBox(height: 12),
          _buildGreyText("Last Name"),
          _buildInputField(lastNameController),
          const SizedBox(height: 12),
          _buildGreyText("Email"),
          _buildInputField(emailController),
          const SizedBox(height: 12),
          _buildGreyText("Phone Number"), // Phone number label
          _buildNumberInputField(phoneController), // Phone number input field
          const SizedBox(height: 12),
          _buildGreyText("Password"),
          _buildInputField(passwordController, isPassword: true),
          const SizedBox(height: 12),
          _buildGreyText("Confirm Password"),
          _buildInputField(confirmPasswordController, isPassword: true),
          const SizedBox(height: 18),
          _buildSignUpButton(),
          const SizedBox(height: 5),
          _buildGoToLogin(),
        ],
      ),
    );
  }

  Widget _buildGreyText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.grey),
    );
  }

  Widget _buildNumberInputField(TextEditingController controller,
      {bool isPassword = false}) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xff79a3b1),
                  ),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                )
              : null,
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xff79a3b1)),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xff456268)),
          ),
        ),
        obscureText: isPassword ? !showPassword : false,
        keyboardType: isPassword ? TextInputType.text : TextInputType.phone,
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller,
      {bool isPassword = false}) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xff79a3b1),
                  ),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                )
              : null,
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xff79a3b1)),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xff456268)),
          ),
        ),
        obscureText: isPassword ? !showPassword : false,
        //  keyboardType: isPassword ? TextInputType.text : TextInputType.phone,
      ),
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: () {
        registerUser();

        String password = passwordController.text;
        String confirmPassword = confirmPasswordController.text;

        if (password == confirmPassword) {
          // Sign-up logic here
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GenreSelectionApp(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Passwords do not match!"),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        elevation: 20,
        shadowColor: myColor,
        minimumSize: const Size.fromHeight(50),
      ),
      child: const Text(
        "Next",
        style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xff456268)),
        //GenreSelectionPage
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
              debugPrint("Navigate to Login page (not implemented yet)");
            },
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              elevation: 0,
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            ),
            child: const Text(
              "Log In",
              style: TextStyle(color: Color(0xff79a3b1)),
            ),
          ),
        ],
      ),
    );
  }
}
