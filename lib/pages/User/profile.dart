import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'editProfile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart'; // Make sure to import your login screen
import 'resetPassword.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../configuration/config.dart';
import 'addCard.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData; // Store user data
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data when the screen initializes
    _fetchCreditCardData();
  }

  Future<void> _fetchCreditCardData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token'); // Retrieve the stored token

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse(getCreditCardData), // Replace with your API endpoint
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final creditCardData = json.decode(response.body);
          setState(() {
            print("creditCardData");
            print(creditCardData);

            // Extract the 'creditCard' map from the response
            var creditCard = creditCardData['creditCard'] ?? {};

            // Handle the creditCard field properly - convert it into a string or meaningful data
            userData?['creditCard'] = creditCard.isNotEmpty
                ? '${creditCard['cardNumber'] ?? 'N/A'}' // Assigning cardNumber as string
                : 'N/A';

            // Constructing expiryDate from expiryMonth and expiryYear
            var expiryDate = (creditCard['expiryMonth'] != null &&
                    creditCard['expiryYear'] != null)
                ? '${creditCard['expiryMonth']}/${creditCard['expiryYear']}'
                : 'N/A';

            userData?['expiryDate'] = expiryDate;

            // Assigning CVV (from cardCode)
            userData?['cvv'] = creditCard['cardCode']?.toString() ?? 'N/A';
          });
        } else {
          print('Error fetching credit card data: ${response.statusCode}');
        }
      } catch (e) {
        print('Exception while fetching credit card data: $e');
      }
    } else {
      print('Token not found. Cannot fetch credit card data.');
    }
  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token'); // Retrieve the stored token
    print('token');
    print(token);
    if (token != null) {
      final response = await http.get(
        Uri.parse(getPersonalInfo), // Replace with your API endpoint
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body); // Decode the response
          print('userData');
          print(userData);
          isLoading = false; // Update loading state
        });
      } else {
        // Handle errors (e.g., user not found)
        print('error in retrieving data');
        setState(() {
          isLoading = false; // Stop loading
        });
      }
    } else {
      print('missing token');
      // Handle missing token
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  void _navigateToEditProfile(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfile()),
    );

    if (result == true) {
      _fetchUserData(); // Call your method to refresh data here
    }
  }

  @override
  Widget build(BuildContext context) {
    const String tProfile = "Profile";
    const String tProfileImage =
        "images/profilePURPLE.jpg"; // Example profile image path
    const double tDefaultSize = 20.0; // Example padding size
    const Color tPrimaryColor = myColor; // Pastel teal color

    // Checking the brightness for dark mode
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Responsive dimensions
    var mediaSize = MediaQuery.of(context).size;
    double profileImageSize = mediaSize.width * 0.28; // 28% of screen width

    return DefaultTabController(
      length: 2, // Two tabs for 'Your Info' and 'Your Activity'
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: myColor, // Change to your desired color
          leading: IconButton(
            onPressed: () {}, // Removed function call for now
            icon: const Icon(LineAwesomeIcons.angle_left),
          ),
          title: Text(
            tProfile,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white, // Set your desired color here
                ),
          ),
          actions: [
            IconButton(
              onPressed: () {}, // No function for the toggle
              icon: Icon(isDark ? LineAwesomeIcons.sun : LineAwesomeIcons.moon),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white, // Selected tab text color
            unselectedLabelColor: Colors.white70, // Unselected tab text color
            indicatorColor: Colors.white, // Indicator color under the tab
            tabs: [
              Tab(text: "Your Info"),
              Tab(text: "Your Activity"),
            ],
          ),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator()) // Show loading indicator
            : TabBarView(
                children: [
                  // First tab for 'Your Info'
                  SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(tDefaultSize),
                      decoration: const BoxDecoration(
                        color: Colors
                            .white, //Color.fromARGB( 255, 240, 240, 240), // Off-white background color

                        /* image: DecorationImage(
                          image: const AssetImage("images/white-teal.jpg"),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                              Color(0xff456268).withOpacity(0.9),
                              BlendMode.dstATop),
                        ),*/
                      ),
                      child: Column(
                        children: [
                          /// -- IMAGE
                          Stack(
                            children: [
                              SizedBox(
                                width: profileImageSize,
                                height: profileImageSize,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: const Image(
                                      image: AssetImage(tProfileImage),
                                      fit: BoxFit.cover),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: tPrimaryColor,
                                  ),
                                  child: const Icon(
                                    LineAwesomeIcons.alternate_pencil,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            userData?['user']['firstName'] ??
                                'First Name', // Display fetched first name
                            style: const TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            userData?['user']['lastName'] ??
                                'Last Name', // Display fetched last name
                            style: const TextStyle(
                                fontSize: 16.0, color: Colors.grey),
                          ),
                          const SizedBox(height: 15),

                          // Personal Information Card
                          _buildInfoCard("Personal Information", [
                            _buildUserInfoCard(
                                "First Name",
                                userData?['user']['firstName'] ?? 'N/A',
                                Icons.person),
                            _buildUserInfoCard(
                                "Last Name",
                                userData?['user']['lastName'] ?? 'N/A',
                                Icons.person),
                            _buildUserInfoCard(
                                "Phone Number",
                                userData?['user']['phoneNumber'] ?? 'N/A',
                                Icons.phone),
                            _buildUserInfoCard(
                                "Email",
                                userData?['user']['email'] ?? 'N/A',
                                Icons.email),
                          ]),
                          _spacing(), // Space after the personal information card

                          // Edit Profile Button
                          SizedBox(
                            width: mediaSize.width * 0.6, // 50% of screen width
                            child: ElevatedButton(
                              onPressed: () {
                                _navigateToEditProfile(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tPrimaryColor,
                                shape: const StadiumBorder(),
                              ),
                              child: const Text(
                                'Edit Personal Information',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Payment Information Card
                          _buildInfoCard("Payment Information", [
                            _buildUserInfoCard(
                                "Credit Card",
                                userData?['creditCard'] ?? 'No Info Yet',
                                Icons.credit_card),
                            _buildUserInfoCard(
                                "Expiry Date",
                                userData?['expiryDate'] ?? 'No Info Yet',
                                Icons.date_range),
                            _buildUserInfoCard("CVV",
                                userData?['cvv'] ?? 'No Info Yet', Icons.lock),
                          ]),

                          _spacing(), // Space after the payment information card
                          SizedBox(
                            width: mediaSize.width * 0.6, // 50% of screen width
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const AddCardView()),
                                );
                              }, // No navigation or function call
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tPrimaryColor,
                                shape: const StadiumBorder(),
                              ),
                              child: const Text(
                                'Edit Payment information',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
/*
                    // Logout Menu
                    ProfileMenuWidget(
                      title: "Logout",
                      icon: LineAwesomeIcons.alternate_sign_out,
                      textColor: Colors.red,
                      endIcon: false,
                      onPress: () {},
                    ),
                    */

                          ListTile(
                            onTap: () {
                              // Handle change pass logic here
                              //ResetPasswordPage
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ResetPasswordPage()),
                              );
                            },
                            leading: const Icon(LineAwesomeIcons.key,
                                color: myColor),
                            title: const Text(
                              "Change Password",
                              style: TextStyle(
                                color: myColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            trailing: const Icon(LineAwesomeIcons.angle_right,
                                color: myColor),
                          ),
                          ListTile(
                            onTap: () async {
                              // Handle logout logic here
                              // Clear any stored user data (like tokens)
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs
                                  .clear(); // Clear all stored preferences

                              // Navigate to the login screen
                              isLoggedIn = false;
                              print('');
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('You have logged out successfully.'),
                                ),
                              );
                            },
                            leading: const Icon(
                                LineAwesomeIcons.alternate_sign_out,
                                color: myColor),
                            title: const Text(
                              "Logout",
                              style: TextStyle(
                                color: myColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Second tab for 'Your Activity'
                  Center(
                    child: Text(
                      'Your Activity Data Here', // Placeholder for activity data
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _spacing() {
    return const SizedBox(height: 16); // Adjust height as needed
  }

  static Widget _buildUserInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: Icon(icon, color: myColor),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    const Color cardBackgroundColor =
        myColor; // Pastel background color of the card
    const Color titleColor = Colors.white; // Title text color

    return Card(
      elevation: 3,
      color: cardBackgroundColor, // Set the overall card background color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // Header
          Container(
            child: ListTile(
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: titleColor, // Set the title text color
                ),
              ),
            ),
          ),
          const Divider(),
          Column(children: children), // Child widgets
        ],
      ),
    );
  }
}

class ProfileMenuWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPress;
  final Color? textColor;
  final bool endIcon;

  const ProfileMenuWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.onPress,
    this.textColor,
    this.endIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onPress,
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: TextStyle(color: textColor ?? Colors.black),
      ),
      trailing: endIcon
          ? const Icon(LineAwesomeIcons.angle_right, color: Colors.black)
          : null,
    );
  }
}
