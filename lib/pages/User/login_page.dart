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
import '../../main.dart';
import '../../services/authentication/auth_service.dart';

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
      print('LOGIN jsonResponse:');
      print(jsonResponse);

      if (jsonResponse['status']) {
        // Extract token and user details
        var myToken = jsonResponse['token'];
        var userType = jsonResponse['userType'];

        // Assuming the API also sends firstName, lastName, and email in the response
        var firstName = jsonResponse['data']['firstName'];
        var lastName = jsonResponse['data']['lastName'];
        var email = jsonResponse['data']['email'];

        // Save data in SharedPreferences
        prefs.setString('token', myToken);
        prefs.setBool('rememberUser', rememberUser);
        prefs.setString('userType', userType);
        prefs.setString('firstName', firstName);
        prefs.setString('lastName', lastName);
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
      setState(() {
        errorMessage = 'An error occurred. Please try again.';
      });
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
    }
  }

  void loginUser() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    //prefs.remove('token');

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = "Email and password cannot be empty";
      });
      return;
    }
    firebse_login(email, password, context);
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
