import 'package:flutter/material.dart';
import 'dart:convert'; // For JSON encoding/decoding
//import 'controller/Auth.dart'; // Import the AuthController
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'profile.dart';
import 'forgotPassword.dart';
import '../Product/Pastry/pastryUser_page.dart';
import '../Product/Pastry/pastryOwner_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late Size mediaSize;
  late SharedPreferences prefs;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool rememberUser = false;
  bool showPassword = false; // Variable to track password visibility
  String errorMessage = ""; // For displaying errors

  // final AuthController authController =   AuthController(); // Instantiate the AuthController

  @override
  void initState() {
    super.initState();
    initSharedPref();
  }

  void initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      rememberUser = prefs.getBool('rememberUser') ?? false;
      emailController.text = prefs.getString('email') ?? '';
      passwordController.text = prefs.getString('password') ?? '';
      var token = prefs.getString('token') ?? '';

      print('Remember Me: $rememberUser'); // Log rememberUser status
      print('Loaded Email: ${emailController.text}'); // Log loaded email
      print(
          'Loaded Password: ${passwordController.text}'); // Log loaded password

      if (rememberUser && token.isNotEmpty) {
        print('rememberUser && token.isNotEmpty');
        validateToken(token); // Check if the token is valid
      }
    });
  }

  void validateToken(String token) async {
    try {
      var response = await http.post(
        Uri.parse(validateTokenEndpoint), // Replace with your API endpoint
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        // Token is valid, proceed to the main app
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
      } else {
        // Token invalid/expired, require re-login
        prefs.remove('token'); // Clear stored token
      }
    } catch (e) {
      print('Error validating token: $e');
    }
  }

  void loginUserWithCredentials(String email, String password) async {
    var reqBody = {"email": email, "password": password};
    print(
        "Sending login request to $login with email: $email and password: $password");

    try {
      var response = await http.post(
        Uri.parse(login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );

      var jsonResponse = jsonDecode(response.body);
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");
      print('jsonResponse: $jsonResponse');

      if (jsonResponse['status']) {
        var myToken = jsonResponse['token'];

        prefs.setString('token', myToken);
        prefs.setBool('rememberUser', rememberUser);

        if (rememberUser) {
          prefs.setString('email', email);
          prefs.setString('password', password);
        } else {
          prefs.remove('email');
          prefs.remove('password');
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
      } else {
        setState(() {
          errorMessage =
              jsonResponse['message'] ?? 'Something went wrong with login';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  void loginUser() async {
    String email =
        emailController.text.trim(); // Trim to remove leading/trailing spaces
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = "Email and password cannot be empty";
      });
      return;
    }

    loginUserWithCredentials(
        email, password); // Call the new method with the entered credentials
  }
/*
  void loginUser() async {
    String email =
        emailController.text.trim(); // Trim to remove leading/trailing spaces
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = "Email and password cannot be empty";
      });
      return;
    }

    var reqBody = {"email": email, "password": password};

    try {
      var response = await http.post(
        Uri.parse(login), // Your local API URL for login
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );

      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status']) {
        var myToken = jsonResponse['token'];
        prefs.setString('token', myToken);
        // handle if user checked remmember
        if (rememberUser) {
          prefs.setString('email', email); // Store email
          prefs.setString('password', password); // Store password securely
        } else {
          prefs.remove('email'); // Clear email if not remembered
          prefs.remove('password'); // Clear password if not remembered
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      } else {
        setState(() {
          errorMessage =
              jsonResponse['message'] ?? 'Something went wrong with login';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        errorMessage = 'An error occurred. Please try again.';
      });
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    mediaSize = MediaQuery.of(context).size; // Get the media size
    return Container(
      decoration: BoxDecoration(
        color: myColor,
        image: DecorationImage(
          image: const AssetImage("images/craftsBackground.jpg"),
          fit: BoxFit.cover,
          colorFilter:
              ColorFilter.mode(myColor.withOpacity(0.1), BlendMode.dstATop),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [
          Positioned(top: 80, child: _buildTop()),
          Positioned(bottom: 0, child: _buildBottom()),
        ]),
      ),
    );
  }

  Widget _buildTop() {
    return SizedBox(
      width: mediaSize.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.card_giftcard,
            size: mediaSize.width * 0.25, // Responsive size
            color: Colors.white,
          ),
          Text(
            "CraftBlend",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: mediaSize.width * 0.1, // Responsive font size
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    return SizedBox(
      width: mediaSize.width,
      height: mediaSize.height * 0.64,
      child: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(mediaSize.width * 0.07), // Responsive padding
          child: _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome Back!",
          style: TextStyle(
            color: myColor,
            fontSize: mediaSize.width * 0.08, // Responsive font size
            fontWeight: FontWeight.w500,
          ),
        ),
        _buildGreyText("Please login with your information"),
        const SizedBox(height: 25),
        _buildGreyText("Email address"),
        _buildInputField(emailController),
        const SizedBox(height: 15),
        _buildGreyText("Password"),
        _buildInputField(passwordController, isPassword: true),
        const SizedBox(height: 8),
        _buildRememberForgot(),
        const SizedBox(height: 12),
        _buildLoginButton(),
        //const SizedBox(height: 5),
        if (errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 30),
            child: Text(
              errorMessage,
              style:
                  const TextStyle(color: myColor, fontWeight: FontWeight.w700),
            ),
          ),
        _buildGoToSignUp(),
      ],
    );
  }

  Widget _buildGreyText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.grey),
    );
  }

  Widget _buildInputField(TextEditingController controller,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                  color: myColor,
                ),
                onPressed: () {
                  setState(() {
                    showPassword = !showPassword;
                  });
                },
              )
            : const Icon(
                Icons.email,
                color: Color(0xff6B4F4F),
              ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xff79a3b1)),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: myColor),
        ),
      ),
      obscureText: isPassword ? !showPassword : false,
    );
  }

  Widget _buildRememberForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: rememberUser,
              onChanged: (value) {
                setState(() {
                  rememberUser = value!;
                  print(
                      'Checkbox changed: $rememberUser'); // Print the new state
                });
              },
              activeColor: myColor,
              checkColor: Colors.white,
            ),
            _buildGreyText("Remember me"),
          ],
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ForgotPasswordPage()),
            );
          },
          child: _buildGreyText("I forgot my password"),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: () async {
        loginUser();
      },
      /*
        String email = emailController.text;
        String password = passwordController.text;

        if (email.isEmpty || password.isEmpty) {
          setState(() {
            errorMessage = "Email and password cannot be empty";
          });
          return;
        }

        // Call the AuthController's loginAuth method
        try {
          String token = await authController.loginAuth(email, password);

          // Save token to local storage
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          print('Login successful, token: $token');

          // Navigate to the home page or another page after successful login
          // Navigator.pushNamed(context, '/home');  // Example of navigation
        } catch (e) {
          /* setState(() {
            errorMessage = e.toString(); // Set error message for UI
          });
          */
        }
      },*/
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        elevation: 20,
        shadowColor: myColor,
        minimumSize: const Size.fromHeight(60),
      ),
      child: const Text(
        "LOGIN",
        style: TextStyle(fontWeight: FontWeight.w700, color: myColor),
      ),
    );
  }

  Widget _buildGoToSignUp() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildGreyText("Don't have an account yet?"),
          const SizedBox(width: 0),
          ElevatedButton(
            onPressed: () {
              debugPrint("Navigate to Sign Up page (not implemented yet)");
            },
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              elevation: 0,
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            ),
            child: const Text(
              "Sign Up",
              style: TextStyle(color: myColor),
            ),
          ),
        ],
      ),
    );
  }
}
