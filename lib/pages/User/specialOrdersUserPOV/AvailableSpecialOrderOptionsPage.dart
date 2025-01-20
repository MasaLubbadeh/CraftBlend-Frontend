// lib/pages/available_special_order_options_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../configuration/config.dart'; // Ensure this path is correct
import '../../../models/order_option.dart';
import 'SpecialOrderFormPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class AvailableSpecialOrderOptionsPage extends StatefulWidget {
  final String storeId; // Pass the store ID to fetch options

  const AvailableSpecialOrderOptionsPage({Key? key, required this.storeId})
      : super(key: key);

  @override
  _AvailableSpecialOrderOptionsPageState createState() =>
      _AvailableSpecialOrderOptionsPageState();
}

class _AvailableSpecialOrderOptionsPageState
    extends State<AvailableSpecialOrderOptionsPage> {
  List<OrderOption> _options = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _storeCategory = ''; // Store's category

  // Define the categories and their default options
  Map<String, List<String>> categoryDefaultOptions = {
    'Phone Accessories': ['Personalized designs', 'Large orders'],
    'Pottery': ['Custom Pottery Design', 'Bulk orders'],
    'Gift Items': ['Personalized Gift Packaging', 'Custom Gift Set Design'],
    'Crochet & Knitting': ['Personalized designs', 'Large quantities'],
    'Flowers': [
      'Event-specific bulk arrangements',
      'Personalized designs',
    ],
    'Pastry & Bakery': ['Custom-Made Cake', 'Large Orders'],
  };

  // Function to get image path for a given option and category
  String _getImageForOption(String option, String category) {
    Map<String, Map<String, String>> categoryImages = {
      'Pastry & Bakery': {
        'Custom-Made Cake': 'assets/images/cake.png',
        'Large Orders': 'assets/images/bulk-buying1.png',
      },
      'Flowers': {
        'Event-specific bulk arrangements': 'assets/images/bulk-buying1.png',
        'Personalized designs': 'assets/images/notes.png',
      },
      'Pottery': {
        'Custom Pottery Design': 'assets/images/notes.png',
        'Bulk orders': 'assets/images/bulkBuying.png',
      },
      'Gift Items': {
        'Personalized Gift Packaging': 'assets/images/notes.png',
        'Custom Gift Set Design': 'assets/images/notes.png',
      },
      'Crochet & Knitting': {
        'Personalized designs': 'assets/images/notes.png',
        'Large quantities': 'assets/images/bulkBuying.png',
      },
      'Phone Accessories': {
        'Personalized designs': 'assets/images/notes.png',
        'Large orders': 'assets/images/bulkBuying.png',
      },
    };

    return categoryImages[category]?[option] ?? 'assets/images/notes.png';
  }

  @override
  void initState() {
    super.initState();
    _fetchStoreCategoryAndOptions();
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs
        .getString('token'); // Adjust the key based on your implementation
  }

  Future<void> _fetchStoreCategoryAndOptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String? token = await _getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication token not found.';
          _isLoading = false;
        });
        return;
      }

      // Fetch Store Category

      final categoryResponse = await http.get(
        Uri.parse('$getStoreCategory/${widget.storeId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));

      if (categoryResponse.statusCode == 200) {
        final categoryData = json.decode(categoryResponse.body);
        setState(() {
          _storeCategory = categoryData['category'];
        });
      } else if (categoryResponse.statusCode == 401) {
        setState(() {
          _errorMessage = 'Unauthorized. Please log in again.';
          _isLoading = false;
        });
        // Optionally, navigate to login page
        return;
      } else {
        setState(() {
          _errorMessage =
              'Failed to load store category. Status Code: ${categoryResponse.statusCode}';
          _isLoading = false;
        });
        return;
      }

      // Fetch Special Order Options
      final String optionsUrl =
          '$getStoreSpecialOrderOptions/${widget.storeId}'; // Ensure getStoreSpecialOrderOptions is defined in config.dart

      final optionsResponse = await http.get(
        Uri.parse(optionsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));

      if (optionsResponse.statusCode == 200) {
        List<dynamic> data = json.decode(optionsResponse.body);
        List<OrderOption> fetchedOptions =
            data.map((json) => OrderOption.fromMap(json)).toList();
        setState(() {
          _options = fetchedOptions;
          _isLoading = false;
        });
      } else if (optionsResponse.statusCode == 401) {
        setState(() {
          _errorMessage = 'Unauthorized. Please log in again.';
          _isLoading = false;
        });
        // Optionally, navigate to login page
      } else {
        setState(() {
          _errorMessage =
              'Failed to load options. Status Code: ${optionsResponse.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToFormPage(OrderOption option) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpecialOrderFormPage(option: option),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'Special Order Options',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Image with Opacity
          Opacity(
            opacity: 0.2,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      'assets/images/pastryBackgroundSimple.jpg'), // Replace with your background image
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Main Content
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: myColor))
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _options.isEmpty
                      ? const Center(
                          child: Text(
                            'No special order options available.',
                            style:
                                TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchStoreCategoryAndOptions,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _options.length,
                            itemBuilder: (context, index) {
                              final OrderOption option = _options[index];
                              final String imagePath = _getImageForOption(
                                  option.name, _storeCategory);

                              return Card(
                                color: const Color.fromARGB(171, 243, 229, 245),
                                elevation: 3,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(15.0),
                                  onTap: () => _navigateToFormPage(option),
                                  child: SizedBox(
                                    height:
                                        150.0, // Fixed height for uniformity
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          // Leading Image
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: Image.asset(
                                              imagePath,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey,
                                                  size: 60,
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          // Title and Description
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                // Option Name
                                                Text(
                                                  option.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: myColor,
                                                    fontSize: 18.0,
                                                  ),
                                                ),
                                                const SizedBox(height: 8.0),
                                                // Option Description
                                                Expanded(
                                                  child: Text(
                                                    option.description,
                                                    style: const TextStyle(
                                                      color: myColor,
                                                      fontSize: 14.0,
                                                      height: 1.2,
                                                    ),
                                                    softWrap: true,
                                                    overflow: TextOverflow.fade,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Trailing Icon
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: myColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ],
      ),
    );
  }
}
