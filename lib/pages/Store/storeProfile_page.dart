import 'package:craft_blend_project/pages/Store/ManageAdvertisement_Page.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../User/login_page.dart'; // Import your login screen
import '../User/resetPassword.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../configuration/config.dart';
import 'manageDeliveryLocations_page.dart';

class StoreProfileScreen extends StatefulWidget {
  const StoreProfileScreen({super.key});

  @override
  _StoreProfileScreenState createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  Map<String, dynamic>? storeData; // Store data
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _fetchStoreDetails(); // Fetch store data when the screen initializes
  }

  Future<void> _fetchStoreDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token'); // Retrieve the stored token

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse(getStoreDetails), // Use the store details API endpoint
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            storeData = json.decode(response.body); // Decode the response
            isLoading = false; // Stop loading
          });
        } else {
          print('Error fetching store data: ${response.statusCode}');
          setState(() {
            isLoading = false; // Stop loading
          });
        }
      } catch (e) {
        print('Exception while fetching store data: $e');
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

  @override
  Widget build(BuildContext context) {
    const String tStoreProfile = "Store Profile";
    const double tDefaultSize = 20.0;
    const Color tPrimaryColor = myColor;

    // Responsive dimensions
    var mediaSize = MediaQuery.of(context).size;
    double profileImageSize = mediaSize.width * 0.28; // 28% of screen width

    return DefaultTabController(
      length: 2, // Two tabs for 'Your Info' and 'Your Activity'
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: myColor,
          title: const Text(
            tStoreProfile,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          centerTitle: true,
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
            ? const Center(child: CircularProgressIndicator())
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
                            alignment: Alignment
                                .center, // Center the image in the container
                            children: [
                              // Outer frame with `myColor`
                              Container(
                                width: profileImageSize +
                                    5, // Slightly larger than the image
                                height: profileImageSize + 5,
                                decoration: BoxDecoration(
                                  color: myColor.withOpacity(.5), // Frame color
                                  shape: BoxShape.circle, // Circular frame
                                ),
                              ),
                              // Inner circular image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    100), // Ensure circular clipping
                                child: SizedBox(
                                  width: profileImageSize, // Exact image size
                                  height: profileImageSize,
                                  child: storeData?['logo'] != null
                                      ? Image.network(
                                          storeData![
                                              'logo'], // Fetch logo URL dynamically
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            // Fallback to a default image if the logo fails to load
                                            return const Image(
                                              image: AssetImage(
                                                  "assets/images/storeLogo.png"),
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        )
                                      : const Image(
                                          image: AssetImage(
                                              "assets/images/storeLogo.png"), // Default logo
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Store Name and Category/Rating
                          Text(
                            storeData?['storeName'] ?? 'Store Name',
                            style: const TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            storeData?['category'] ??
                                storeData?['rating'] ??
                                'N/A', // Show category or rating
                            style: const TextStyle(
                                fontSize: 16.0, color: Colors.grey),
                          ),
                          const SizedBox(height: 15),

                          // Store Info Card
                          _buildInfoCard("Store Information", [
                            _buildStoreInfoCard(
                                "Email",
                                storeData?['contactEmail'] ?? 'N/A',
                                Icons.email),
                            _buildStoreInfoCard(
                                "Phone Number",
                                storeData?['phoneNumber'] ?? 'N/A',
                                Icons.phone),
                            _buildStoreInfoCard(
                                "City",
                                storeData?['city'] ?? 'N/A',
                                Icons.location_city),
                          ]),
                          const SizedBox(height: 20),

                          ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ManageDeliveryLocationsPage()),
                              );
                            },
                            leading: const Icon(Icons.delivery_dining,
                                color: myColor),
                            title: const Text(
                              "Manage your delivery locations",
                              style: TextStyle(
                                color: myColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            trailing: const Icon(LineAwesomeIcons.angle_right,
                                color: myColor),
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ManageAdvertisementPage()),
                              );
                            },
                            leading:
                                const Icon(LineAwesomeIcons.ad, color: myColor),
                            title: const Text(
                              "Home Page Ad Management",
                              style: TextStyle(
                                color: myColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            trailing: const Icon(LineAwesomeIcons.angle_right,
                                color: myColor),
                          ),

                          // Change Password Button
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

                          // Logout Button
                          ListTile(
                            onTap: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.clear();

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

  static Widget _buildStoreInfoCard(String title, String value, IconData icon) {
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
    return Card(
      elevation: 3,
      color: myColor,
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
                  color: Colors.white,
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
