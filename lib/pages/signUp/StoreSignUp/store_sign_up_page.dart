import 'package:craft_blend_project/main.dart';
import 'package:flutter/material.dart';
import '../../../models/store_sign_up_data.dart';
import '../../../models/store_sign_up_data.dart';
import '../../../configuration/config.dart';
import '../../../pages/User/login_page.dart';
import '../../../pages/Product/Pastry/pastryOwner_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:http/http.dart' as http;

class StoreSignUpPage extends StatefulWidget {
  final StoreSignUpData SignUpData;

  const StoreSignUpPage({super.key, required this.SignUpData});

  @override
  _StoreSignUpPageState createState() => _StoreSignUpPageState();
}

class _StoreSignUpPageState extends State<StoreSignUpPage> {
  TextEditingController storeNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool allowSpecialOrders = false; // Tracks Yes/No toggle for special orders
  bool showPassword = false;

  late Size mediaSize;

  List<String> countries = [
    'Palestine',
    'Bahrain',
    'Iran',
    'Iraq',
    'Jordan',
    'Kuwait',
    'Lebanon',
    'Oman',
    'Qatar',
    'Saudi Arabia',
    'Syria',
    'United Arab Emirates',
    'Yemen'
  ];
  String? selectedCountry;

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
        body: Stack(
          children: [
            Positioned(bottom: -10, child: _buildBottom(myColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottom(Color myColor) {
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
          child: _buildForm(myColor),
        ),
      ),
    );
  }

  Widget _buildForm(Color myColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Create Your Store Account",
            style: TextStyle(
              color: Color.fromARGB(255, 122, 104, 135),
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          _buildGreyText("Please sign up with your store information"),
          const SizedBox(height: 20),
          _buildGreyText("Store Name"),
          _buildInputField(storeNameController, myColor),
          const SizedBox(height: 12),
          _buildGreyText("Contact Email"),
          _buildInputField(emailController, myColor),
          const SizedBox(height: 12),
          _buildGreyText("Phone Number"),
          _buildInputField(phoneController, myColor, isNumber: true),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCountryDropdown(myColor),
              const SizedBox(height: 14),
              _buildInputField(cityController, myColor, label: "City"),
            ],
          ),
          const SizedBox(height: 12),
          _buildGreyText("Password"),
          _buildInputField(passwordController, myColor, isPassword: true),
          const SizedBox(height: 12),
          _buildGreyText("Confirm Password"),
          _buildInputField(confirmPasswordController, myColor,
              isPassword: true),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Allow Special Orders?",
                style: TextStyle(fontSize: 16),
              ),
              Switch(
                value: allowSpecialOrders,
                onChanged: (value) {
                  setState(() {
                    allowSpecialOrders = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSignUpButton(myColor),
          const SizedBox(height: 5),
          _buildGoToLogin(myColor),
        ],
      ),
    );
  }

  Widget _buildCountryDropdown(Color myColor) {
    return DropdownButtonFormField<String>(
      value: selectedCountry,
      items: countries
          .map(
            (country) => DropdownMenuItem<String>(
              value: country,
              child: Text(country),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          selectedCountry = value;
        });
      },
      decoration: InputDecoration(
        labelText: "Country",
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: myColor),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: myColor),
        ),
      ),
    );
  }

  Widget _buildGreyText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.grey),
    );
  }

  Widget _buildInputField(TextEditingController controller, Color myColor,
      {String? label, bool isPassword = false, bool isNumber = false}) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        obscureText: isPassword ? !showPassword : false,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
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
              : null,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: myColor),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: myColor),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpButton(Color myColor) {
    return ElevatedButton(
      onPressed: () {
        _validateAndSubmit();
      },
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        elevation: 12,
        //elevation: 12,
        shadowColor: myColor,
        minimumSize: const Size.fromHeight(50),
      ),
      child: Text(
        "Submit",
        style: TextStyle(fontWeight: FontWeight.w700, color: myColor),
      ),
    );
  }

  Widget _buildGoToLogin(Color myColor) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildGreyText("Already have an account?"),
          const SizedBox(width: 5),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              elevation: 0,
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            ),
            child: Text(
              "Log In",
              style: TextStyle(color: myColor),
            ),
          ),
        ],
      ),
    );
  }

  void _validateAndSubmit() async {
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 6 characters long"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save the entered data to the shared variable
    StoreSignUpData signUpData = StoreSignUpData(
      storeName: storeNameController.text.trim(),
      contactEmail: emailController.text.trim(),
      phoneNumber: phoneController.text,
      password: passwordController.text.trim(),
      country: selectedCountry,
      city: cityController.text,
      allowSpecialOrders: allowSpecialOrders,
      accountType: widget.SignUpData.accountType,
      selectedGenreId: widget.SignUpData.selectedGenreId,
    );

    // Register user
    await registerUser(signUpData);
  }

  Future<void> registerUser(StoreSignUpData signUpData) async {
    if (signUpData.storeName != null &&
        signUpData.contactEmail != null &&
        signUpData.phoneNumber != null &&
        signUpData.password != null &&
        signUpData.country != null &&
        signUpData.city != null) {
      try {
        // Prepare request body using StoreSignUpData model as JSON
        var url = Uri.parse(storeRegistration);

        // Send data as JSON
        var response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json', // Set content-type to JSON
          },
          body: jsonEncode(signUpData.toJson()),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final jsonResponse = jsonDecode(response.body);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!')),
          );

          // Save token and user type to SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('token', jsonResponse['token']);
          prefs.setString('userType', jsonResponse['userType']);

          // Navigate to MainScreen after successful registration
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          final errorMessage = jsonDecode(response.body)['message'] ??
              'Registration failed. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $errorMessage')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }
}
