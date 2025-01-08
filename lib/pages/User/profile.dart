<<<<<<< HEAD
import 'package:craft_blend_project/services/authentication/auth_service.dart';
=======
>>>>>>> main
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
<<<<<<< HEAD
  bool isUser = false; // Determine if the user is not  owner nor admin
=======
>>>>>>> main

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _fetchUserDetails(); // Fetch user data when the screen initializes
  }

  Future<void> _fetchUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token'); // Retrieve the stored token
    final String? userType =
        prefs.getString('userType'); // Retrieve the user type

    if (token != null) {
      try {
        // Set isOwner based on userType
        if (mounted) {
          setState(() {
            isUser = (userType == 'user');
          });
        }

        // Fetch User Information
        final userResponse = await http.get(
          Uri.parse(getPersonalInfo), // Replace with your API endpoint
=======
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
>>>>>>> main
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

<<<<<<< HEAD
        if (userResponse.statusCode == 200) {
          if (mounted) {
            setState(() {
              userData =
                  json.decode(userResponse.body); // Decode the user response

              // Only fetch and add credit card info if the user is not an owner
              if (isUser) {
                _fetchCreditCardDetails(token);
              } else {
                isLoading = false; // Stop loading
              }
            });
          }
        } else {
          print('Error fetching user data: ${userResponse.statusCode}');
          if (mounted) {
            setState(() {
              isLoading = false; // Ensure the loading state is properly handled
            });
          }
        }
      } catch (e) {
        print('Exception while fetching data: $e');
        if (mounted) {
          setState(() {
            isLoading = false; // Ensure the loading state is properly handled
          });
        }
        // Stop loading
      }
    } else {
      print('Token not found. Cannot fetch data.');
      if (mounted) {
        setState(() {
          isLoading = false; // Ensure the loading state is properly handled
        });
      }
    }
  }

  Future<void> _fetchCreditCardDetails(String token) async {
    try {
      // Fetch Credit Card Information
      final cardResponse = await http.get(
        Uri.parse(getCreditCardData), // Replace with your API endpoint
=======
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
>>>>>>> main
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

<<<<<<< HEAD
      if (cardResponse.statusCode == 200) {
        setState(() {
          final creditCardData = json.decode(cardResponse.body);
          var creditCard = creditCardData['creditCard'] ?? {};

          // Mask the credit card number to show only the last 4 digits
          String maskedCardNumber = creditCard.isNotEmpty
              ? '**** **** **** ' +
                  (creditCard['cardNumber']
                          ?.substring(creditCard['cardNumber'].length - 4) ??
                      'N/A')
              : 'No Info Yet';

          // Assign payment information to userData
          userData?['creditCard'] = maskedCardNumber;

          // Constructing expiryDate from expiryMonth and expiryYear
          userData?['expiryDate'] = (creditCard['expiryMonth'] != null &&
                  creditCard['expiryYear'] != null)
              ? '${creditCard['expiryMonth']}/${creditCard['expiryYear']}'
              : 'No Info Yet';

          // Assigning CVV (not displayed for security reasons)
          userData?['cvv'] =
              creditCard.containsKey('cardCode') ? '***' : 'No Info Yet';

          isLoading = false; // Update loading state
        });
      } else {
        print('Error fetching credit card data: ${cardResponse.statusCode}');
        if (mounted) {
          setState(() {
            isLoading = false; // Ensure the loading state is properly handled
          });
        }
      }
    } catch (e) {
      print('Exception while fetching credit card data: $e');
      if (mounted) {
        setState(() {
          isLoading = false; // Ensure the loading state is properly handled
        });
      }
=======
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
>>>>>>> main
    }
  }

  void _navigateToEditProfile(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfile()),
    );

    if (result == true) {
<<<<<<< HEAD
      _fetchUserDetails(); // Refresh user data after edit
    }
  }

  void _logout() async {
    // Perform logout actions
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have logged out successfully.'),
      ),
    );
  }

  Widget _buildYourInfoTab() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Add your profile and other details here
            const SizedBox(height: 20),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ResetPasswordPage()),
                );
              },
              leading: const Icon(LineAwesomeIcons.key, color: myColor),
              title: const Text(
                "Change Password",
                style: TextStyle(
                  color: myColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              trailing:
                  const Icon(LineAwesomeIcons.angle_right, color: myColor),
            ),
            ListTile(
              onTap: () {
                _logout();
              },
              leading: const Icon(LineAwesomeIcons.alternate_sign_out,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    const String tProfile = "Profile";
    const double tDefaultSize = 20.0; // Example padding size
    const Color tPrimaryColor = myColor; // Primary color
=======
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
>>>>>>> main

    // Checking the brightness for dark mode
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Responsive dimensions
    var mediaSize = MediaQuery.of(context).size;
    double profileImageSize = mediaSize.width * 0.28; // 28% of screen width

    return DefaultTabController(
      length: 2, // Two tabs for 'Your Info' and 'Your Activity'
      child: Scaffold(
        appBar: AppBar(
<<<<<<< HEAD
          automaticallyImplyLeading: false,
          backgroundColor: myColor, // Your primary color
          title: const Text(
            tProfile,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          centerTitle: true,
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(LineAwesomeIcons.bars, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer(); // Open the drawer
                },
              );
            },
          ),
          actions: [
            IconButton(
              onPressed: () {}, // Toggle functionality
=======
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
>>>>>>> main
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
<<<<<<< HEAD
        drawer: Drawer(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(30),
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: mediaSize.height * 0.27,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/arcTest2.png'),
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: mediaSize.height * 0.18,
                    left: mediaSize.width / 4.5,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white24,
                          width: 7,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: mediaSize.height * 0.07,
                        backgroundImage:
                            AssetImage('assets/images/profilePURPLE.jpg'),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: mediaSize.height * 0.09),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.account_box, color: myColor),
                title: const Text(
                  "Your Account",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: myColor,
                      letterSpacing: 1),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              ////////////////////////
              ///const Divider(),
              ListTile(
                leading: const Icon(LineAwesomeIcons.key, color: myColor),
                title: const Text(
                  "Change Password",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: myColor,
                      letterSpacing: 1),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResetPasswordPage(),
                    ),
                  );
                },
              ),
              const Divider(),

              ///
              const Spacer(),
              ListTile(
                leading: const Icon(LineAwesomeIcons.alternate_sign_out,
                    color: myColor),
                title: const Text(
                  "Logout",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: myColor,
                      letterSpacing: 1),
                ),
                onTap: () async {
                  final _auth = AuthService();
                  _auth.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  isLoggedIn = false;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You have logged out successfully.'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
=======
>>>>>>> main
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
<<<<<<< HEAD
                        color: Colors.white,
=======
                        color: Colors
                            .white, //Color.fromARGB( 255, 240, 240, 240), // Off-white background color

                        /* image: DecorationImage(
                          image: const AssetImage("images/white-teal.jpg"),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                              Color(0xff456268).withOpacity(0.9),
                              BlendMode.dstATop),
                        ),*/
>>>>>>> main
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
<<<<<<< HEAD
                                      image: AssetImage(
                                          "assets/images/profilePURPLE.jpg"),
=======
                                      image: AssetImage(tProfileImage),
>>>>>>> main
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
<<<<<<< HEAD
                            userData?['user']['firstName'] ?? 'First Name',
=======
                            userData?['user']['firstName'] ??
                                'First Name', // Display fetched first name
>>>>>>> main
                            style: const TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
<<<<<<< HEAD
                            userData?['user']['lastName'] ?? 'Last Name',
=======
                            userData?['user']['lastName'] ??
                                'Last Name', // Display fetched last name
>>>>>>> main
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
<<<<<<< HEAD
                          _spacing(),

                          // Edit Profile Button
                          SizedBox(
                            width: mediaSize.width * 0.6,
=======
                          _spacing(), // Space after the personal information card

                          // Edit Profile Button
                          SizedBox(
                            width: mediaSize.width * 0.6, // 50% of screen width
>>>>>>> main
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

<<<<<<< HEAD
                          // Payment Information Card - Only show if not an owner
                          if (isUser)
                            Column(
                              children: [
                                _buildInfoCard("Payment Information", [
                                  _buildUserInfoCard(
                                      "Credit Card",
                                      userData?['creditCard'] ?? 'No Info Yet',
                                      Icons.credit_card),
                                  _buildUserInfoCard(
                                      "Expiry Date",
                                      userData?['expiryDate'] ?? 'No Info Yet',
                                      Icons.date_range),
                                  _buildUserInfoCard(
                                      "CVV",
                                      userData?['cvv'] ?? 'No Info Yet',
                                      Icons.lock),
                                ]),
                                _spacing(),
                                SizedBox(
                                  width: mediaSize.width * 0.6,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AddCardView(),
                                        ),
                                      );
                                      if (result == true) {
                                        _fetchUserDetails(); // Refresh data if the card was updated
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: tPrimaryColor,
                                      shape: const StadiumBorder(),
                                    ),
                                    child: Text(
                                      userData?['creditCard'] != 'No Info Yet'
                                          ? 'Edit Payment Information'
                                          : 'Add Payment Information',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 20),
                          ListTile(
                            onTap: () {
=======
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
>>>>>>> main
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
<<<<<<< HEAD
                              final _auth = AuthService();
                              _auth.signOut();
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.clear();

                              isLoggedIn = false;
=======
                              // Handle logout logic here
                              // Clear any stored user data (like tokens)
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs
                                  .clear(); // Clear all stored preferences

                              // Navigate to the login screen
                              isLoggedIn = false;
                              print('');
>>>>>>> main
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
<<<<<<< HEAD
    return const SizedBox(height: 16);
=======
    return const SizedBox(height: 16); // Adjust height as needed
>>>>>>> main
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
<<<<<<< HEAD
    const Color cardBackgroundColor = myColor;
    const Color titleColor = Colors.white;

    return Card(
      elevation: 3,
      color: cardBackgroundColor,
=======
    const Color cardBackgroundColor =
        myColor; // Pastel background color of the card
    const Color titleColor = Colors.white; // Title text color

    return Card(
      elevation: 3,
      color: cardBackgroundColor, // Set the overall card background color
>>>>>>> main
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
<<<<<<< HEAD
=======
          // Header
>>>>>>> main
          Container(
            child: ListTile(
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
<<<<<<< HEAD
                  color: titleColor,
=======
                  color: titleColor, // Set the title text color
>>>>>>> main
                ),
              ),
            ),
          ),
          const Divider(),
<<<<<<< HEAD
          Column(children: children),
=======
          Column(children: children), // Child widgets
>>>>>>> main
        ],
      ),
    );
  }
}
<<<<<<< HEAD
=======

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
>>>>>>> main
