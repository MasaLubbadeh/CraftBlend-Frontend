import 'dart:async';

import 'package:craft_blend_project/components/addressWidget.dart';
import 'package:craft_blend_project/configuration/config.dart';
import 'package:craft_blend_project/pages/Product/Pastry/pastryUser_page.dart';
import 'package:craft_blend_project/pages/Product/productDetails_page.dart';
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
import 'package:craft_blend_project/components/badge.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> adImages = []; // Initialize as empty list
  bool isLoadingAds = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isDrawerOpen = false;

  final CarouselSliderController buttonCarouselController =
      CarouselSliderController();

  List<Map<String, dynamic>> categories = [];
  bool isLoadingCategories = true;
  String selectedCity = "Choose city"; // Default value if no city is chosen
  int currentAdIndex = 0; // Add this to your state
  List<String> adStoreIds = []; // Store IDs corresponding to ads
  List<String> adStoreNames = []; // Store Names corresponding to ads
  List<Map<String, dynamic>> favoriteStoreProducts = [];
  List<Map<String, dynamic>> wishlistItems = [];
  List<Map<String, dynamic>> mostSearchedItems = [];
  List<Map<String, dynamic>> recentlyViewedProducts = [];
  List<Map<String, dynamic>> recommendedStores = [];
  List<Map<String, dynamic>> suggestedProducts = [];
  List<Map<String, dynamic>> notifications = [];

  bool isLoadingNotification = true;
  bool isLoadingRecommendedStores = true;
  bool isLoadingSuggested = true;
  bool isLoadingRecentlyViewed = true;
  bool isLoadingFavorites = true;
  bool isLoadingWishlist = true;
  bool isLoadingMostSearched = true;

  List<Map<String, dynamic>> pastries = [];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _loadSelectedCity();
    _checkLocation();
    _fetchAdvertisements(); // Fetch ads

    _fetchFavoriteStoreProducts();
    _fetchMostSearchedItems();
    _fetchRecentlyViewedProducts();
    _fetchRecommendedStores();
    _fetchSuggestedProducts();
    _fetchNotifications();
    // Set up the timer to update the remaining time for each pastry every second
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          for (var pastry in pastries) {
            if (pastry['onSale'] == true && pastry['endDate'] != null) {
              try {
                DateTime endDate = DateTime.parse(pastry['endDate']);
                pastry['remainingTime'] = _calculateRemainingTime(endDate);
              } catch (e) {
                print(
                    "Invalid endDate format for pastry: ${pastry['endDate']}");
                pastry['remainingTime'] = 'Invalid Date';
              }
            } else {
              pastry['remainingTime'] = 'Not on Sale';
            }
          }
        });
      }
    });
  }

  String _calculateRemainingTime(DateTime endDate) {
    DateTime currentDate = DateTime.now();
    Duration difference = endDate.difference(currentDate);

    if (difference.isNegative) {
      return 'Sale Ended';
    } else {
      return '${difference.inDays}d ${difference.inHours % 24}h ${difference.inMinutes % 60}m ${difference.inSeconds % 60}s';
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void _handleDrawerStateChange() {
    if (isDrawerOpen && !_scaffoldKey.currentState!.isDrawerOpen) {
      // The drawer was open and now it's closed
      _markNotificationsAsRead();
    }
    isDrawerOpen = _scaffoldKey.currentState!.isDrawerOpen;
  }

  Future<void> _fetchNotifications() async {
    try {
      // Replace with the correct token retrieval logic
      final String? token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found.');
      }
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userType = prefs.getString('userType');
      final response = await http.get(
        Uri.parse('$getNotifications?userType=$userType'), // Your API endpoint

        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          notifications =
              List<Map<String, dynamic>>.from(responseData['notifications']);
          isLoadingNotification = false;
        });
      } else {
        throw Exception(
            'Failed to fetch notifications. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      if (mounted) {
        setState(() {
          isLoadingNotification = false;
        });
      }
    }
  }

  Future<void> _fetchSuggestedProducts() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found.');
      }

      final response = await http.get(
        Uri.parse(getSuggestedProducts),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true &&
            responseData['products'] != null) {
          if (mounted) {
            setState(() {
              suggestedProducts =
                  List<Map<String, dynamic>>.from(responseData['products']);
              isLoadingSuggested = false;
            });
          }
        } else {
          throw Exception('Invalid response format or missing products key.');
        }
      } else {
        throw Exception(
            'Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching suggested products: $e');
      if (mounted) {
        setState(() {
          isLoadingSuggested = false;
        });
      }
    }
  }

  Future<void> _fetchRecommendedStores() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found.');
      }
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse(getRecommendedStoresByCategory),
        headers: headers,
      );
      print('_fetchRecommendedStores ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          recommendedStores = List<Map<String, dynamic>>.from(
              json.decode(response.body)['stores']);
          isLoadingRecommendedStores = false;
        });
      } else {
        throw Exception('Failed to fetch recommended stores.');
      }
    } catch (e) {
      print('Error fetching recommended stores: $e');
      if (mounted) {
        setState(() {
          isLoadingRecommendedStores = false;
        });
      }
    }
  }

  Future<void> _fetchFavoriteStoreProducts() async {
    try {
      // Fetch data for favorite store products
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found.');
      }
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final response = await http.get(
        Uri.parse(getFavStoresProducts),
        headers: headers,
      );
      //     print('_fetchFavoriteStoreProductss ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true &&
            responseData['products'] != null) {
          if (mounted) {
            setState(() {
              favoriteStoreProducts =
                  List<Map<String, dynamic>>.from(responseData['products']);
              isLoadingFavorites = false;
            });
          }
        } else {
          throw Exception('Invalid response format or missing products key.');
        }
      } else {
        throw Exception(
            'Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching favorite store products: $e');
      if (mounted) {
        setState(() {
          isLoadingFavorites = false;
        });
      }
    }
  }

  Future<void> _fetchWishlistItems() async {
    try {
      // Fetch data for wishlist items
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found.');
      }
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse(getWishlistProducts),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true &&
            responseData['products'] != null) {
          setState(() {
            wishlistItems =
                List<Map<String, dynamic>>.from(responseData['products']);
            isLoadingWishlist = false;
          });
        } else {
          throw Exception('Invalid response format or missing products key.');
        }
      } else {
        throw Exception(
            'Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching wishlist items: $e');
      setState(() {
        isLoadingWishlist = false;
      });
    }
  }

  Future<void> _fetchMostSearchedItems() async {
    try {
      // Fetch data for most searched items
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found.');
      }
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse(getMostSearched),
        headers: headers,
      );
      //    print('_fetchMostSearchedItems ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            mostSearchedItems = List<Map<String, dynamic>>.from(
                json.decode(response.body)['products']);
            isLoadingMostSearched = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching most searched items: $e');
      if (mounted) {
        setState(() {
          isLoadingMostSearched = false;
        });
      }
    }
  }

  Future<void> _fetchRecentlyViewedProducts() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found.');
      }

      final response = await http.get(
        Uri.parse(getRecentlyViewedProducts),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      // print('_fetchRecentlyViewedProducts');
      //print(response.body);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            recentlyViewedProducts = List<Map<String, dynamic>>.from(
                json.decode(response.body)['products']);
            isLoadingRecentlyViewed = false;
          });
        }
      } else {
        throw Exception(
            'Failed to fetch recently viewed products. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recently viewed products: $e');
      if (mounted) {
        setState(() {
          isLoadingRecentlyViewed = false;
        });
      }
    }
  }

  String formatTimeRequired(int? timeRequired) {
    if (timeRequired == null || timeRequired <= 0) return "No time specified";

    // Convert to days and round
    final days = (timeRequired / 1440).round();

    // If less than a day, show hours
    if (days == 0) {
      final hours = (timeRequired / 60).round(); // Convert to hours
      return "$hours hour${hours > 1 ? 's' : ''}";
    }

    return "$days day${days > 1 ? 's' : ''}";
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    // pastries = product as List<Map<String, dynamic>>;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(product: product),
          ),
        );
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4, // 40% of screen width
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image with badge overlay
              AspectRatio(
                aspectRatio: 1.5, // Square aspect ratio
                child: Stack(
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: product['image'] != null
                          ? Image.network(
                              product['image'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : const Image(
                              image: AssetImage(
                                  'assets/images/default_product.jpg'),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                    ),
                    // Badge overlay
                    /*  if (product['inStock'] == false)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Out of Stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),*/
                    if (product['isUponOrder'] == true)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Upon Order',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),

                    if (product['onSale'] ==
                        true) // Check if the product is on sale
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(
                                180, 255, 0, 0), // Fully transparent
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${product['saleAmount']}% SALE ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    if (product['inStock'] == true)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Available',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Product name
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  product['name'] ?? 'No Name',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Product price
              if (product['onSale'] == true) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Text(
                        '${product['oldPrice']?.toStringAsFixed(2) ?? '0.00'}₪',
                        style: const TextStyle(
                          fontSize: 14,
                          decoration:
                              TextDecoration.lineThrough, // Strike-through
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${product['salePrice']?.toStringAsFixed(2) ?? '0.00'}₪',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.red, // Highlight sale price
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '${product['price']?.toStringAsFixed(2) ?? '0.00'}₪',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              // Store information
              if (product['store'] != null && product['store'] is Map)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: product['store']['logo'] != null
                            ? NetworkImage(product['store']['logo'])
                            : const AssetImage('assets/images/logo.png')
                                as ImageProvider,
                        backgroundColor: Colors.transparent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          product['store']['storeName'] ?? 'Unknown Store',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PastryPage(
              storeId: store['_id'],
              storeName: store['storeName'],
            ),
          ),
        );
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4, // 40% of screen width
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store logo
              AspectRatio(
                aspectRatio: 1.0, // Square aspect ratio
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: store['logo'] != null
                      ? Image.network(
                          store['logo'],
                          fit: BoxFit.cover,
                        )
                      : const Image(
                          image: AssetImage('assets/images/default_store.jpg'),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              // Store name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  store['storeName'] ?? 'Unknown Store',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                ),
              ),
              const SizedBox(height: 20),
              // Category image and name
              if (store['category'] != null) // Check if category data exists
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Category image
                      if (store['category']['image'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.network(
                            store['category']['image'],
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported, size: 24),
                          ),
                        ),
                      const SizedBox(width: 8),
                      // Category name
                      Text(
                        store['category']['name'] ?? 'Unknown Category',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String title, List<Map<String, dynamic>> items,
      Widget Function(Map<String, dynamic>) itemBuilder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: myColor,
                letterSpacing: 1.5),
          ),
        ),
        SizedBox(
          height:
              MediaQuery.of(context).size.height * 0.3, // 30% of screen height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return itemBuilder(items[index]);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _checkLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? location = prefs.getString('selectedLocation');
    if (location == null || location.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MapPage()),
      );
    }
  }

  Future<void> _fetchAdvertisements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token'); // Fetch authentication token

      final response = await http.get(
        Uri.parse(getAllAdvertisements), // Replace with your API endpoint
        headers: {
          'Authorization': 'Bearer $token', // Add token for authorization
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (mounted) {
          setState(() {
            adImages = [];
            adStoreIds = [];
            adStoreNames = [];
            for (var ad in jsonResponse['advertisements']) {
              if (ad['image'] != null && ad['storeId'] != null) {
                adImages.add(ad['image']);
                adStoreIds.add(
                    ad['storeId']['_id']); // Assuming nested storeId structure
                adStoreNames.add(ad['storeId']
                    ['storeName']); // Assuming storeName is present
              }
            }
            isLoadingAds = false;
          });
        }
      } else {
        throw Exception('Failed to load advertisements');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingAds = false;
        });
      }
      print('Error fetching advertisements: $e');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse(getAllCategories));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (mounted) {
          setState(() {
            categories =
                List<Map<String, dynamic>>.from(jsonResponse['categories']);
            isLoadingCategories = false;
          });
        }
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
    if (mounted) {
      setState(() {
        selectedCity = prefs.getString('selectedLocation') ?? "Choose city";
      });
    }
  }

  Widget _buildCarousel() {
    return adImages.isEmpty
        ? const Center(
            child: Text(
              'No advertisements available.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
        : SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                CarouselSlider(
                  items: adImages.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final String adImage = entry.value;

                    return Builder(
                      builder: (BuildContext context) {
                        return GestureDetector(
                          onTap: () {
                            // Navigate to PastryPage with storeId
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PastryPage(
                                  storeId: adStoreIds[index],
                                  storeName: adStoreNames[index],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                adImage,
                                width: MediaQuery.of(context).size.width,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
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
                          ),
                        );
                      },
                    );
                  }).toList(),
                  carouselController: buttonCarouselController,
                  options: CarouselOptions(
                    height: 200.0,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 3),
                    autoPlayAnimationDuration:
                        const Duration(milliseconds: 800),
                    enlargeCenterPage: false,
                    viewportFraction: 1.0,
                    onPageChanged: (index, reason) {
                      if (mounted) {
                        setState(() {
                          currentAdIndex = index; // Update the currentAdIndex
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(
                    height: 8), // Space between carousel and indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: adImages.asMap().entries.map((entry) {
                    return GestureDetector(
                      onTap: () =>
                          buttonCarouselController.animateToPage(entry.key),
                      child: Container(
                        width: currentAdIndex == entry.key ? 10.0 : 6.0,
                        height: currentAdIndex == entry.key ? 10.0 : 6.0,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentAdIndex == entry.key
                              ? myColor
                              : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
  }

  Widget _buildCategoriesSection() {
    return Card(
      elevation: 5,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      color: const Color.fromARGB(171, 243, 229, 245).withOpacity(.9),
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
                      builder: (context) =>
                          CategoriesPage(selectedCategoryId: category['_id']),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
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
                                        fontWeight: FontWeight.bold,
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
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp); // Parse the timestamp
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 1) {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${dateTime.hour}:${dateTime.minute}';
      } else if (difference.inHours >= 1) {
        return '${difference.inHours} hour(s) ago';
      } else if (difference.inMinutes >= 1) {
        return '${difference.inMinutes} minute(s) ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      print('Error formatting timestamp: $e');
      return 'Unknown Time';
    }
  }

  Future<void> _markNotificationsAsRead() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      for (var notification in notifications) {
        if (!notification['isRead']) {
          final notificationId = notification['_id'];
          final response = await http.patch(
            Uri.parse('$markNotificationAsRead/$notificationId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            setState(() {
              notification['isRead'] = true;
            });
            print('Notification $notificationId marked as read.');
          } else {
            print(
                'Failed to mark notification $notificationId as read: ${response.body}');
          }
        }
      }
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  // Function to mark a single notification as read
  Future<void> _markSingleNotificationAsRead(String notificationId) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.patch(
        Uri.parse('$markNotificationAsRead/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          notifications
              .firstWhere((n) => n['_id'] == notificationId)['isRead'] = true;
        });
        print('Notification $notificationId marked as read.');
      } else {
        print(
            'Failed to mark notification $notificationId as read: ${response.body}');
      }
    } catch (e) {
      print('Error marking notification $notificationId as read: $e');
    }
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
        leading: Builder(
          builder: (BuildContext context) {
            // Check if there are unread notifications
            final hasUnreadNotifications = notifications
                .any((notification) => notification['isRead'] == false);

            return IconButton(
              icon: Stack(
                clipBehavior: Clip.none, // Allow overflow for the badge
                children: [
                  Icon(
                    hasUnreadNotifications
                        ? Icons.notifications_active // Active notification icon
                        : Icons.notifications, // Default notification icon
                    color: Colors.white,
                  ),
                  if (hasUnreadNotifications)
                    Positioned(
                      right: -3, // Adjust position of the badge
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '!', // A simple badge indicator
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Open the custom drawer
              },
            );
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
      ///////////////////////////////////////////////////////
      ///// Add the notification drawer here
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.86, // Set drawer width
        elevation: 10, // Add some elevation for a shadow effect
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(0),
          ),
        ),
        child: Container(
          height: MediaQuery.of(context).size.height *
              0.7, // Limit drawer height to 70% of the screen
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(30),
              bottomRight: Radius.circular(0),
            ),
          ),
          child: Column(
            children: [
              // Header for the drawer
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.135,
                decoration: const BoxDecoration(
                  color: myColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width * 0.06,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              //const Divider(),

              // Notifications list
              Expanded(
                child: isLoadingNotification
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : notifications.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No notifications available.',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 15),
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final notification = notifications[index];
                              final timestamp = notification[
                                  'createdAt']; // Ensure 'createdAt' is present
                              final formattedTime = timestamp != null
                                  ? _formatTimestamp(timestamp)
                                  : 'Unknown Time';

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 16),
                                  leading: Icon(
                                    notification['isRead']
                                        ? Icons.notifications_active
                                        : Icons.notifications_active,
                                    color: notification['isRead']
                                        ? myColor.withOpacity(.5)
                                        : myColor,
                                    size: 28,
                                  ),
                                  title: Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      notification['title'] ?? 'No Title',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: myColor,
                                      ),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notification['message'] ?? 'No Message',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _formatTimestamp(
                                            notification['createdAt']),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    final notificationId = notification['_id'];
                                    await _markSingleNotificationAsRead(
                                        notificationId);
                                  },
                                ),
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const Divider(),
                          ),
              ),

              // Clear notifications button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      notifications
                          .clear(); // Clear the notification list locally
                    });
                  },
                  icon: const Icon(Icons.clear_all, color: Colors.white70),
                  label: const Text(
                    'Clear All',
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: myColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
//////////
      onDrawerChanged: (isOpened) {
        setState(() {
          isDrawerOpen = isOpened;
        });
        if (!isOpened) {
          // Drawer closed, mark notifications as read
          _markNotificationsAsRead();
        }
      },

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            isLoadingAds
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )
                : _buildCarousel(),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
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
            isLoadingCategories
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )
                : _buildCategoriesSection(),
            const SizedBox(height: 20),

            // Recently Viewed Products Row
            if (!isLoadingRecentlyViewed && recentlyViewedProducts.isNotEmpty)
              Column(
                children: [
                  _buildRow('Recently Viewed Products', recentlyViewedProducts,
                      _buildProductCard),
                  const SizedBox(height: 20),
                ],
              ),

            if (!isLoadingSuggested && suggestedProducts.isNotEmpty)
              Column(
                children: [
                  _buildRow('Suggested for You', suggestedProducts,
                      _buildProductCard),
                  const SizedBox(height: 20),
                ],
              ),

            // From Your Favorite Stores Row
            if (!isLoadingFavorites && favoriteStoreProducts.isNotEmpty)
              Column(
                children: [
                  _buildRow('From Your Favorite Stores', favoriteStoreProducts,
                      _buildProductCard),
                  const SizedBox(height: 20),
                ],
              ),

            // Most Searched Items Row
            if (!isLoadingMostSearched && mostSearchedItems.isNotEmpty)
              Column(
                children: [
                  _buildRow('Most Searched Items', mostSearchedItems,
                      _buildProductCard),
                  const SizedBox(height: 20),
                ],
              ),

            if (!isLoadingRecommendedStores && recommendedStores.isNotEmpty)
              Column(
                children: [
                  _buildRow('Stores You Might Be Interested In',
                      recommendedStores, _buildStoreCard),
                  const SizedBox(height: 20),
                ],
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
