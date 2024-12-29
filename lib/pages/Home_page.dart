import 'package:craft_blend_project/components/addressWidget.dart';
import 'package:craft_blend_project/configuration/config.dart';
import 'package:craft_blend_project/pages/googleMapsPage.dart';
import 'package:craft_blend_project/pages/wishlist_page.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:carousel_slider/carousel_controller.dart';

import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'CategoriesPage.dart';
import 'Search_Page.dart'; // Import SearchPage for navigation

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> adImages = [
    'https://via.placeholder.com/800x300?text=Ad+1',
    'https://via.placeholder.com/800x300?text=Ad+2',
    'https://via.placeholder.com/800x300?text=Ad+3',
    'https://invalid-url.com/invalid.jpg', // Intentional invalid URL for testing
  ];

  final CarouselSliderController buttonCarouselController =
      CarouselSliderController();

  List<Map<String, dynamic>> categories = [];
  bool isLoadingCategories = true;
  String selectedCity = "Choose city"; // Default value if no city is chosen

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _loadSelectedCity();
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? location = prefs.getString('selectedLocation');
    if (location == null || location.isEmpty) {
      Navigator.pushReplacementNamed(context, '/map');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse(getAllCategories));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          categories =
              List<Map<String, dynamic>>.from(jsonResponse['categories']);
          isLoadingCategories = false;
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingCategories = false;
        });
      }
      print('Error fetching categories: $e');
    }
  }

  Future<bool> _requestLocationPermission() async {
    PermissionStatus status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      return true;
    } else if (status.isDenied || status.isPermanentlyDenied) {
      _showLocationPermissionDialog();
      return false;
    }
    return false;
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog Image
                Image.asset(
                  'assets/images/location_icon.png', // Replace with your image path
                  height: 100,
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Allow location permission',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: myColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Message
                const Text(
                  'Please enable your location permission to use the current location.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Go to Settings Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: myColor, // Use your theme color
                      ),
                      onPressed: () async {
                        await openAppSettings();
                        Navigator.pop(context); // Close dialog
                      },
                      child: const Text(
                        'Go to settings',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    // Cancel Button
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLocationOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose your location",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.my_location, color: myColor),
                title: const Text("Current location"),
                subtitle: const Text(
                  "We will use your current location",
                ),
                onTap: () async {
                  // Request location permission
                  bool permissionGranted = await _requestLocationPermission();

                  if (permissionGranted) {
                    // Fetch current location
                    /*
                    Position position = await _getCurrentLocation();

                    // Handle the location data
                    print(
                        "Current location: ${position.latitude}, ${position.longitude}");

                    // Save to shared preferences (optional)
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    prefs.setString('currentLocation',
                        '${position.latitude}, ${position.longitude}');

                    // Close the bottom sheet or navigate elsewhere
                    Navigator.pop(context);
                    */
                  } else {
                    // Permission denied message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text("Location permission is required to proceed."),
                      ),
                    );
                  }
                },
              ),
              const Divider(),
              ListTile(
                  leading: const Icon(Icons.location_city, color: myColor),
                  title: const Text("Explore our service areas"),
                  subtitle: const Text("See where we're operating"),
                  onTap: () {
                    Navigator.pop(context); // Close the bottom sheet first
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapPage()),
                    ).then((_) {
                      _loadSelectedCity(); // Reload the selected city when returning
                    });
                  }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadSelectedCity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedCity = prefs.getString('selectedLocation') ?? "Choose city";
    });
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      backgroundColor: const Color.fromARGB(171, 230, 215, 232),
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        automaticallyImplyLeading: false,
        backgroundColor: myColor,
        elevation: 0,
        title: AddressWidget(
          firstLineText: 'Palestine,',
          secondLineText: selectedCity,
          onTap: _showLocationOptions, // Pass the method to handle tap
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.menu,
            color: Colors.white70,
          ), // Menu icon
          onPressed: () {
            // Handle menu actions
          },
        ),
        actions: [
          // Heart Icon for Wishlist
          IconButton(
            icon: const Icon(
              Icons.favorite_border, // Outlined heart icon
              color: Colors.white70,
            ),
            onPressed: () {
              // Navigate to the Wishlist page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WishlistPage()),
              );
            },
          ),
          // Search Icon
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Colors.white70,
            ), // Search icon
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const SearchPage(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin =
                        Offset(1.0, 0.0); // Swipe starts from the right
                    const end = Offset.zero; // Ends at the current position
                    const curve = Curves.easeInOut;

                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);

                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Carousel Slider
          SizedBox(
            width: MediaQuery.of(context).size.width, // Force full width
            child: CarouselSlider(
              items: adImages.map((ad) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          ad,
                          width: MediaQuery.of(context)
                              .size
                              .width, // Image full width
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Placeholder for error case
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Text(
                                  'Image failed to load',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
              carouselController: buttonCarouselController,
              options: CarouselOptions(
                height: 250.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 3),
                enlargeCenterPage: false, // Disable enlarge to fill the width
                viewportFraction: 1.0, // Make each item take the full width
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Fancy Heading
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6.0),
            child: Text(
              "What's on your mind?",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: myColor,
                  letterSpacing: 2),
              textAlign: TextAlign.center,
            ),
          ),

          // Categories Section
          isLoadingCategories
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )
              : categories.isEmpty
                  ? const Center(
                      child: Text(
                        'No categories available.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : Card(
                      elevation: 5,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      color: const Color.fromARGB(171, 243, 229, 245)
                          .withOpacity(.9),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: categories.map((category) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CategoriesPage(
                                          selectedCategoryId: category['_id']),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 65,
                                        height: 65,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                            width: 2,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: ClipOval(
                                          child: category['image'] != null &&
                                                  category['image'].isNotEmpty
                                              ? Image.network(
                                                  category['image'],
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: Colors.grey,
                                                  child: Center(
                                                    child: Text(
                                                      category['name'][0],
                                                      style: const TextStyle(
                                                        fontSize: 25,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          category['name'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.black54,
                                          ),
                                          textAlign: TextAlign.center,
                                          softWrap: true,
                                          maxLines: 2,
                                          overflow: TextOverflow.clip,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
