import 'package:craft_blend_project/pages/Store/ManageAdvertisement_Page.dart';
import 'package:craft_blend_project/pages/Store/specialOrders/specialOrder_page.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../User/login_page.dart'; // Import your login screen
import '../../User/resetPassword.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../configuration/config.dart';
import '../manageDeliveryLocations_page.dart';

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
        print(response.body);

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
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    const String tStoreProfile = "Your Account";
    const double tDefaultSize = 20.0;
    const Color tPrimaryColor = myColor;

    // Responsive dimensions
    var mediaSize = MediaQuery.of(context).size;
    double profileImageSize = mediaSize.width * 0.28; // 28% of screen width

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        toolbarHeight: appBarHeight,
        title: const Text(
          tStoreProfile,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
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
              leading: const Icon(Icons.delivery_dining, color: myColor),
              title: const Text(
                "Manage your delivery locations",
                style: TextStyle(
                  color: myColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const ManageDeliveryLocationsPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(LineAwesomeIcons.ad, color: myColor),
              title: const Text(
                "Home Page Ad Management",
                style: TextStyle(
                  color: myColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ManageAdvertisementPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: myColor),
              title: const Text(
                "Manage special orders",
                style: TextStyle(
                  color: myColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onTap: () {
                final category = storeData?['category'];
                if (category != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SpecialOrdersPage(category: category),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Category not found for this store.')),
                  );
                }
              },
            ),
            const Divider(),
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
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(tDefaultSize),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: profileImageSize + 5,
                          height: profileImageSize + 5,
                          decoration: BoxDecoration(
                            color: myColor.withOpacity(.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: SizedBox(
                            width: profileImageSize,
                            height: profileImageSize,
                            child: storeData?['logo'] != null
                                ? Image.network(
                                    storeData!['logo'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Image(
                                        image: AssetImage(
                                            "assets/images/logo.png"),
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  )
                                : const Image(
                                    image: AssetImage("assets/images/logo.png"),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      storeData?['storeName'] ?? 'Store Name',
                      style: const TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      storeData?['category'] ?? storeData?['rating'] ?? 'N/A',
                      style:
                          const TextStyle(fontSize: 16.0, color: Colors.grey),
                    ),
                    const SizedBox(height: 15),
                    _buildInfoCard("Store Information", [
                      _buildStoreInfoCard("Email",
                          storeData?['contactEmail'] ?? 'N/A', Icons.email),
                      _buildStoreInfoCard("Phone Number",
                          storeData?['phoneNumber'] ?? 'N/A', Icons.phone),
                      _buildStoreInfoCard("City", storeData?['city'] ?? 'N/A',
                          Icons.location_city),
                    ]),
                    const SizedBox(height: 20),
                  ],
                ),
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
