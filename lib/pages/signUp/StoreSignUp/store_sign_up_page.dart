import 'package:craft_blend_project/main.dart';
import 'package:flutter/material.dart';
import '../../../models/store_sign_up_data.dart';
import '../../../configuration/config.dart';
import '../../../pages/User/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:http/http.dart' as http;

import '../../../services/authentication/auth_service.dart';

class StoreSignUpPage extends StatefulWidget {
  final StoreSignUpData signUpData;

  const StoreSignUpPage({super.key, required this.signUpData});

  @override
  _StoreSignUpPageState createState() => _StoreSignUpPageState();
}

class _StoreSignUpPageState extends State<StoreSignUpPage> {
  TextEditingController storeNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool allowSpecialOrders = false; // Tracks Yes/No toggle for special orders
  bool showPassword = false;

  late Size mediaSize;

  String? selectedCountry = 'Palestine'; // Default country
  List<String> countries = ['Palestine'];
  List<Map<String, dynamic>> cities =
      []; // List of city objects with id and name
  String? selectedCity;

  @override
  void initState() {
    super.initState();
    _fetchCities(); // Fetch cities for the default country
  }

  Future<void> _fetchCities() async {
    try {
      var url = Uri.parse(getAllCities);
      var response = await http.get(url);

      if (response.statusCode == 200 && response.body.contains('cities')) {
        final List<dynamic> cityList = jsonDecode(response.body)['cities'];
        setState(() {
          cities = cityList
              .map((city) =>
                  {'id': city['_id'].toString(), 'name': city['name']})
              .toList();
          selectedCity = cities.isNotEmpty ? cities.first['id'] : null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cities: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching cities: $e')),
      );
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
        body: SingleChildScrollView(
          // Makes the entire page scrollable
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context)
                  .viewInsets
                  .bottom, // Adjust for keyboard
            ),
            child: Column(
              children: [
                SizedBox(
                    height: mediaSize.height * 0.07), // Optional top spacing
                _buildBottom(myColor), // The card with the form
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottom(Color myColor) {
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _buildForm(myColor), // Contains the form
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
          _buildCountryDropdown(myColor),
          const SizedBox(height: 12),
          _buildCityDropdown(myColor),
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
          _fetchCities();
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

  Widget _buildCityDropdown(Color myColor) {
    return DropdownButtonFormField<String>(
      value: selectedCity,
      items: cities
          .map(
            (city) => DropdownMenuItem<String>(
              value: city['id'], // Use city ID as the value
              child: Text(city['name']), // Display city name
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          selectedCity = value; // Update the selected city ID
        });
      },
      decoration: InputDecoration(
        labelText: "City",
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
      {bool isPassword = false, bool isNumber = false}) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        obscureText: isPassword ? !showPassword : false,
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
            },
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              elevation: 0,
              backgroundColor: Colors.transparent,
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
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    StoreSignUpData signUpData = StoreSignUpData(
      storeName: storeNameController.text.trim(),
      contactEmail: emailController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      password: passwordController.text.trim(),
      country: selectedCountry,
      city: selectedCity,
      allowSpecialOrders: allowSpecialOrders,
      accountType: widget.signUpData.accountType,
      selectedGenreId: widget.signUpData.selectedGenreId,
      logo: widget.signUpData.logo, // Include logo URL if applicable
    );

    // Validate required fields
    if (signUpData.storeName == null ||
        signUpData.contactEmail == null ||
        signUpData.phoneNumber == null ||
        signUpData.password == null ||
        signUpData.country == null ||
        signUpData.city == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields!")),
      );
      return;
    }
    print("await registerUser(signUpData);");
    await registerUser(signUpData);
  }

  Future<void> registerUser(StoreSignUpData signUpData) async {
    try {
      var url = Uri.parse(storeRegistration);
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(signUpData.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("this is before calling function");
        final auth = AuthService();
        print(signUpData.contactEmail);
        print(signUpData.password);
        print(signUpData.storeName);

        auth.signUpStoreWithEmailPassword(
            signUpData.contactEmail!,
            signUpData.password!,
            signUpData.storeName!,
            signUpData.accountType!);
        print("this is after calling function");
        final jsonResponse = jsonDecode(response.body);
        print("this is the json response:");
        print(jsonResponse);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );

        // Save token and navigate
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('token', jsonResponse['token']);
        prefs.setString('userType', jsonResponse['userType']);

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
