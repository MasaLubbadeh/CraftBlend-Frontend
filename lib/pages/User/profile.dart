import 'package:craft_blend_project/services/authentication/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../aboutUs_page.dart';
import 'PointsPage.dart';
import 'editProfile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart'; // Make sure to import your login screen
import 'resetPassword.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../configuration/config.dart';
import 'addCard.dart';
import '../../services/Notifications/notification_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData; // Store user data
  bool isLoading = true; // Loading state
  bool isUser = false; // Determine if the user is not  owner nor admin

  @override
  void initState() {
    super.initState();
    _fetchUserDetails(); // Fetch user data when the screen initializes
    testSendNotification();
  }

  void testSendNotification() async {
    String deviceToken =
        'dpr0kih7TvGhrI0dXDipnA:APA91bHmxGw5BL7EjTqogS7zcJch3tszK0we5E-s052wtdDoqiGZYI7h9A4ZnsGJ4bSQP4ve2coqJRJQe2H3WSSvwPpWOlgRXDnY0-ApKwXutgXWM_nHGyU';
    String title = 'SALES in pastryShop UP TO 75!';
    String body = '75% Sale for a limited time!!!';

    await NotificationService.sendNotification(deviceToken, title, body);
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
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

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
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

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
    }
  }

  void _navigateToEditProfile(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfile()),
    );

    if (result == true) {
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
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    const String tProfile = "Profile";
    const double tDefaultSize = 20.0; // Example padding size
    const Color tPrimaryColor = myColor; // Primary color

    // Checking the brightness for dark mode
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Responsive dimensions
    var mediaSize = MediaQuery.of(context).size;
    double profileImageSize = mediaSize.width * 0.28; // 28% of screen width

    return DefaultTabController(
      length: 2, // Two tabs for 'Your Info' and 'Your Activity'
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: appBarHeight,

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
        ),
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
              /* in case we need to return this
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
              */
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
              const Divider(),

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
              Divider(),
              if (isUser)
                ListTile(
                  leading: const Icon(Icons.info, color: myColor),
                  title: const Text(
                    "About us",
                    style: TextStyle(
                      color: myColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AboutUsPage()),
                    );
                  },
                ),
            ],
          ),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator()) // Show loading indicator
            : // First tab for 'Your Info'
            SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(tDefaultSize),
                  decoration: const BoxDecoration(
                    color: Colors.white,
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
                                  image: AssetImage(
                                      "assets/images/profilePURPLE.jpg"),
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
                      isUser
                          ? Text(
                              '${userData?['user']['firstName'] ?? 'First Name'} ${userData?['user']['lastName'] ?? 'Last Name'}',
                              style: const TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 1),
                            )
                          : Text(
                              '${userData?['user']['firstName'] ?? 'First Name'}',
                              style: const TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 1),
                            ),
                      const SizedBox(height: 10),
                      if (isUser)
                        Align(
                          // alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // await _updateRate(shekelPerPoint);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PointsPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.emoji_events,
                                color: Colors.white),
                            label: const Text(
                              'Check Your Points',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: myColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical:
                                    8, // Reduced vertical padding for a thinner button
                              ),
                            ),
                          ),
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
                        _buildUserInfoCard("Email",
                            userData?['user']['email'] ?? 'N/A', Icons.email),
                      ]),
                      _spacing(),

                      // Edit Profile Button
                      SizedBox(
                        width: mediaSize.width * 0.6,
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
                                      builder: (context) => const AddCardView(),
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
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),
                      /*
                          ListTile(
                            onTap: () {
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
                              final _auth = AuthService();
                              _auth.signOut();
                              final prefs =
                                  await SharedPreferences.getInstance();
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
                          */
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _spacing() {
    return const SizedBox(height: 16);
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
    const Color cardBackgroundColor = myColor;
    const Color titleColor = Colors.white;

    return Card(
      elevation: 3,
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Container(
            child: ListTile(
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: titleColor,
                ),
              ),
            ),
          ),
          const Divider(),
          Column(children: children),
        ],
      ),
    );
  }
}
