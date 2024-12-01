import 'package:flutter/material.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../configuration/config.dart';
import 'profile.dart';
import 'forgotPassword.dart';
import '../../pages/signUp/account_type_selection_page.dart';
import '../Product/Pastry/pastryUser_page.dart';
import '../Product/Pastry/pastryOwner_page.dart';
import '../Admin/adminDashboard.dart';

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

      if (rememberUser && token.isNotEmpty) {
        validateToken(token); // Check if the token is valid
      }
    });
  }

  void validateToken(String token) async {
    try {
      var response = await http.post(
        Uri.parse(validateTokenEndpoint),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
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
        }
      } else {
        prefs.remove('token'); // Clear stored token
      }
    } catch (e) {
      print('Error validating token: $e');
    }
  }

  void loginUserWithCredentials(String email, String password) async {
    var reqBody = {"email": email, "password": password};
    try {
      var response = await http.post(
        Uri.parse(login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );

      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status']) {
        var myToken = jsonResponse['token'];
        var userType = jsonResponse['userType'];

        prefs.setString('token', myToken);
        prefs.setBool('rememberUser', rememberUser);

        if (rememberUser) {
          prefs.setString('email', email);
          prefs.setString('password', password);
        } else {
          prefs.remove('email');
          prefs.remove('password');
        }

        // Save user type to SharedPreferences
        prefs.setString('userType', userType);

        // If the user is a store owner, save additional information
        if (userType == 'store') {
          var storeName = jsonResponse[
              'storeName']; // Assuming this is returned from the backend
          var storeId = jsonResponse[
              'storeId']; // Assuming this is returned from the backend
          prefs.setString('storeName', storeName);
          prefs.setString('storeId', storeId);
        }

        // Navigate to the appropriate screen based on user type
        if (userType == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
          );
        } else if (userType == 'store') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
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
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = "Email and password cannot be empty";
      });
      return;
    }

    loginUserWithCredentials(email, password);
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
            fontSize: mediaSize.width * 0.08,
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
        const SizedBox(height: 18),
        _buildRememberForgot(),
        const SizedBox(height: 13),
        _buildLoginButton(),
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
          child: _buildGreyText("forgot my password"),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: loginUser,
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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AccountTypeSelectionPage(),
                ),
              );
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
