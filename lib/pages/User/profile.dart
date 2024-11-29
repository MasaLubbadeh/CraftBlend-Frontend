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
    _fetchUserDetails(); // Fetch user data and credit card info when the screen initializes
  }

  Future<void> _fetchUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token'); // Retrieve the stored token

    if (token != null) {
      try {
        // Fetch User Information
        final userResponse = await http.get(
          Uri.parse(getPersonalInfo), // Replace with your API endpoint
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        // Fetch Credit Card Information
        final cardResponse = await http.get(
          Uri.parse(getCreditCardData), // Replace with your API endpoint
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (userResponse.statusCode == 200 && cardResponse.statusCode == 200) {
          setState(() {
            userData =
                json.decode(userResponse.body); // Decode the user response

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
          print(
              'Error fetching data: ${userResponse.statusCode} / ${cardResponse.statusCode}');
          setState(() {
            isLoading = false; // Stop loading
          });
        }
      } catch (e) {
        print('Exception while fetching data: $e');
        setState(() {
          isLoading = false; // Stop loading
        });
      }
    } else {
      print('Token not found. Cannot fetch data.');
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
      _fetchUserDetails(); // Refresh user data after edit
    }
  }

  @override
  Widget build(BuildContext context) {
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
          backgroundColor: myColor, // Change to your desired color
          /*leading: IconButton(
            onPressed: () {}, // Removed function call for now
            icon: const Icon(
              LineAwesomeIcons.angle_left,
              color: Colors.white,
            ),
          ),*/
          title: Text(tProfile,
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center
              //  Theme.of(context).textTheme.headlineMedium?.copyWith( color: Colors.white,     ),
              ),
          centerTitle: true,
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
                          Text(
                            userData?['user']['firstName'] ?? 'First Name',
                            style: const TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            userData?['user']['lastName'] ?? 'Last Name',
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
                          const SizedBox(height: 20),
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
