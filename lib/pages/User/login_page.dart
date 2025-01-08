import 'package:flutter/material.dart';
import 'dart:convert'; // For JSON encoding/decoding
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../configuration/config.dart';
import 'forgotPassword.dart';
import '../../pages/signUp/account_type_selection_page.dart';
import '../../main.dart';
import '../../services/authentication/auth_service.dart';
=======
//import 'controller/Auth.dart'; // Import the AuthController
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../configuration/config.dart';
import 'profile.dart';
import 'forgotPassword.dart';
import '../Product/Pastry/pastryUser_page.dart';
import '../Product/Pastry/pastryOwner_page.dart';
>>>>>>> main

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

<<<<<<< HEAD
=======
  // final AuthController authController =   AuthController(); // Instantiate the AuthController

>>>>>>> main
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

<<<<<<< HEAD
      if (rememberUser && token.isNotEmpty) {
=======
      print('Remember Me: $rememberUser'); // Log rememberUser status
      print('Loaded Email: ${emailController.text}'); // Log loaded email
      print(
          'Loaded Password: ${passwordController.text}'); // Log loaded password

      if (rememberUser && token.isNotEmpty) {
        print('rememberUser && token.isNotEmpty');
>>>>>>> main
        validateToken(token); // Check if the token is valid
      }
    });
  }

  void validateToken(String token) async {
    try {
      var response = await http.post(
<<<<<<< HEAD
        Uri.parse(validateTokenEndpoint),
=======
        Uri.parse(validateTokenEndpoint), // Replace with your API endpoint
>>>>>>> main
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
<<<<<<< HEAD
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const MainScreen()), // Update this to your OwnerPage
        );
        /*
        if (prefs.getString('userType') == 'store') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const PastryOwnerPage()), // Update this to your OwnerPage
          );
        } else if (prefs.getString('userType') == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const AdminDashboardPage()), // Update this to your OwnerPage
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }*/
      } else {
=======
        // Token is valid, proceed to the main app
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      } else {
        // Token invalid/expired, require re-login
>>>>>>> main
        prefs.remove('token'); // Clear stored token
      }
    } catch (e) {
      print('Error validating token: $e');
    }
  }

<<<<<<< HEAD
/*  void loginUserWithCredentials(String email, String password) async {
    var reqBody = {"email": email, "password": password};
    try {
      var response = await http.post(
        Uri.parse(login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );

      var jsonResponse = jsonDecode(response.body);
      print('LOGIN jsonResponse:');
      print(jsonResponse);

      if (jsonResponse['status']) {
        // Extract token and user details
        var myToken = jsonResponse['token'];
        var userType = jsonResponse['userType'];

        // Extract data object, fallback to defaults if fields are missing
        var data = jsonResponse['data'] ?? {};
        var firstName = data['firstName'] ?? 'User';
        var lastName = data['lastName'] ?? '';
        var email = data['email'] ?? '';

        // Save data in SharedPreferences
        prefs.setString('token', myToken);
        prefs.setBool('rememberUser', rememberUser);
        prefs.setString('userType', userType);
        //prefs.setString('firstName', firstName);
        // prefs.setString('lastName', lastName);
        prefs.setString('email', email);

        // Save email and password only if "remember me" is checked
        if (rememberUser) {
          prefs.setString('email', email);
          prefs.setString('password', password);
        } else {
          prefs.remove('email');
          prefs.remove('password');
        }

        // Navigate to MainScreen after successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        setState(() {
          errorMessage =
              jsonResponse['message'] ?? 'Something went wrong with login';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'An error occurred. Please try again.';
        });
      }
    }
  }
*/

  void loginUserWithCredentials(String email, String password) async {
    var reqBody = {"email": email, "password": password};
=======
  void loginUserWithCredentials(String email, String password) async {
    var reqBody = {"email": email, "password": password};
    print(
        "Sending login request to $login with email: $email and password: $password");

>>>>>>> main
    try {
      var response = await http.post(
        Uri.parse(login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );

      var jsonResponse = jsonDecode(response.body);
<<<<<<< HEAD
      print('LOGIN jsonResponse:');
      print(jsonResponse);

      if (jsonResponse['status']) {
        // Extract token and user details
        var myToken = jsonResponse['token'];
        var userType = jsonResponse['userType'];

        // Extract data object, fallback to defaults if fields are missing
        var data = jsonResponse['data'] ?? {};
        print('data object:$data');
        var firstName = data['firstName'] ?? 'User';
        var lastName = data['lastName'] ?? '';
        var email = data['email'] ?? '';
        var storeName = data['storeName'] ?? 'test';
        // Save data in SharedPreferences
        prefs.setString('token', myToken);
        prefs.setBool('rememberUser', rememberUser);
        prefs.setString('userType', userType);
        prefs.setString('firstName', firstName);
        prefs.setString('lastName', lastName);
        prefs.setString('email', email);
        prefs.setString('storeName', storeName);
        print('store Name:$storeName');
        print('first Name:$firstName');
        print('last Name:$lastName');
        print('email:$email');
        print('userType:$userType');

        // Save email and password only if "remember me" is checked
=======
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");
      print('jsonResponse: $jsonResponse');

      if (jsonResponse['status']) {
        var myToken = jsonResponse['token'];

        prefs.setString('token', myToken);
        prefs.setBool('rememberUser', rememberUser);

>>>>>>> main
        if (rememberUser) {
          prefs.setString('email', email);
          prefs.setString('password', password);
        } else {
          prefs.remove('email');
          prefs.remove('password');
        }

<<<<<<< HEAD
        // Navigate to MainScreen after successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
=======
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
>>>>>>> main
        );
      } else {
        setState(() {
          errorMessage =
              jsonResponse['message'] ?? 'Something went wrong with login';
        });
      }
    } catch (e) {
<<<<<<< HEAD
      if (mounted) {
        setState(() {
          errorMessage = 'An error occurred. Please try again.';
        });
      }
    }
  }

  void firebse_login(String email, String pass, BuildContext context) async {
    //auth firebase//////////////////
    //auth service
    final authService = AuthService();
    try {
      await authService.signInWithEmainPassword(email, pass);
    } catch (err) {
      print("Firebase Login Error: $err"); // Log the exact error for debugging
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Login Failed"),
          content: Text(err.toString()),
        ),
      );
=======
      setState(() {
        errorMessage = 'An error occurred. Please try again.';
      });
>>>>>>> main
    }
  }

  void loginUser() async {
<<<<<<< HEAD
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    //prefs.remove('token');
=======
    String email =
        emailController.text.trim(); // Trim to remove leading/trailing spaces
    String password = passwordController.text.trim();
>>>>>>> main

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = "Email and password cannot be empty";
      });
      return;
    }
<<<<<<< HEAD
    // firebse_login(email, password, context);
    loginUserWithCredentials(email, password);
  }

  @override
  Widget build(BuildContext context) {
    mediaSize = MediaQuery.of(context).size;
=======

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
>>>>>>> main
    return Container(
      decoration: BoxDecoration(
        color: myColor,
        image: DecorationImage(
<<<<<<< HEAD
          image: const AssetImage("assets/images/craftsBackground.jpg"),
=======
          image: const AssetImage("images/craftsBackground.jpg"),
>>>>>>> main
          fit: BoxFit.cover,
          colorFilter:
              ColorFilter.mode(myColor.withOpacity(0.1), BlendMode.dstATop),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
<<<<<<< HEAD
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: mediaSize.height,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  SizedBox(height: mediaSize.height * 0.1),
                  _buildTop(),
                  const SizedBox(height: 30),
                  Expanded(child: _buildBottom()),
                ],
              ),
            ),
          ),
        ),
=======
        body: Stack(children: [
          Positioned(top: 80, child: _buildTop()),
          Positioned(bottom: 0, child: _buildBottom()),
        ]),
>>>>>>> main
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
<<<<<<< HEAD
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(mediaSize.width * 0.07),
        child: _buildForm(),
=======
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
>>>>>>> main
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
<<<<<<< HEAD
            fontSize: mediaSize.width * 0.08,
=======
            fontSize: mediaSize.width * 0.08, // Responsive font size
>>>>>>> main
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
<<<<<<< HEAD
        const SizedBox(height: 18),
        _buildRememberForgot(),
        const SizedBox(height: 13),
        _buildLoginButton(),
=======
        const SizedBox(height: 8),
        _buildRememberForgot(),
        const SizedBox(height: 12),
        _buildLoginButton(),
        //const SizedBox(height: 5),
>>>>>>> main
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
<<<<<<< HEAD
=======
                  print(
                      'Checkbox changed: $rememberUser'); // Print the new state
>>>>>>> main
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
<<<<<<< HEAD
          child: _buildGreyText("forgot my password"),
=======
          child: _buildGreyText("I forgot my password"),
>>>>>>> main
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
<<<<<<< HEAD
      onPressed: loginUser,
=======
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
>>>>>>> main
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
<<<<<<< HEAD
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AccountTypeSelectionPage(),
                ),
              );
=======
              debugPrint("Navigate to Sign Up page (not implemented yet)");
>>>>>>> main
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
