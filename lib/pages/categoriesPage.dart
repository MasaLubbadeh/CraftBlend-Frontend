import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../configuration/config.dart';
import 'Product/Pastry/pastryUser_page.dart';

class CategoriesPage extends StatefulWidget {
  final String? selectedCategoryId;

  const CategoriesPage({super.key, required this.selectedCategoryId});

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> stores = [];
  bool isLoadingStores = false;
  bool isLoadingCategories = true;
  String? selectedCategoryId;
  String? selectedCity; // To store the selected city name
  final ScrollController _categoryScrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSelectedCity(); // Load selected city from SharedPreferences
    _fetchCategories();

    if (widget.selectedCategoryId != null) {
      selectedCategoryId = widget.selectedCategoryId;
      _fetchStores(selectedCategoryId!);
      _updateLastVisitedCategory(selectedCategoryId!);
    }

    // Save scroll offset whenever it changes
    _categoryScrollController.addListener(() {
      _scrollOffset = _categoryScrollController.offset;
    });
  }

  Future<void> _loadSelectedCity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedCity = prefs.getString('selectedLocationID'); // Get saved city
    });
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  Future<void> _updateLastVisitedCategory(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userType = prefs.getString('userType');

      if (userType != 'user') {
        return; // Exit if userType is not 'user'
      }

      final response = await http.post(
        Uri.parse(updateLastVisitedCategory),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'categoryId': categoryId}),
      );

      if (response.statusCode == 200) {
        print('Last visited category updated successfully.');
      } else {
        print('Failed to update last visited category: ${response.statusCode}');
      }
    } catch (error) {
      print('Error updating last visited category: $error');
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

        // Restore scroll position
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _categoryScrollController.jumpTo(_scrollOffset);
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      setState(() {
        isLoadingCategories = false;
      });
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchStores(String categoryId) async {
    try {
      setState(() {
        isLoadingStores = true;
      });

      // Fetch all stores for the selected category
      final response =
          await http.get(Uri.parse('$getStoresByCategory/$categoryId/stores'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        print(jsonResponse);
        setState(() {
          var fetchedStores = List<Map<String, dynamic>>.from(jsonResponse);

          // Filter stores by deliveryCities or existing in the selected city
          /*if (selectedCity != null) {
            fetchedStores = fetchedStores
                .where((store) =>
                    // Check if the store delivers to the selected city
                    (store['deliveryCities'] as List<dynamic>?)!.any(
                      (deliveryCity) => deliveryCity['city'] == selectedCity,
                    ) ||
                    // OR check if the store exists in the selected city
                    store['city'] == selectedCity)
                .toList();
          }*/
          print('Filtered Stores: $fetchedStores');

          stores = fetchedStores;
          isLoadingStores = false;
        });
      } else {
        throw Exception('Failed to load stores');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingStores = false;
        });
      }
      print('Error fetching stores: $e');
    }
  }

  void _showSuggestionForm(BuildContext context) {
    // Declare controllers outside the builder to retain their state
    final TextEditingController categoryController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String? errorMessage; // Error message for category validation

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Suggest a New Category",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: myColor,
                        letterSpacing: 1),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: categoryController,
                    decoration: InputDecoration(
                      labelText: "Category Name",
                      border: const OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(10.0))),
                      errorText: errorMessage, // Show the error message
                    ),
                    onChanged: (_) {
                      setState(() {
                        errorMessage = null; // Clear error on input
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText:
                          "Why should we add this category?\n (Optional)",
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(10.0))),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the modal
                        },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: myColor),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final category = categoryController.text.trim();
                          final description = descriptionController.text.trim();

                          if (category.isEmpty) {
                            setState(() {
                              errorMessage = "Category name cannot be empty.";
                            });
                            return;
                          }

                          _submitCategorySuggestion(
                              category, description); // Submit the suggestion
                          Navigator.pop(context); // Close the modal
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: myColor, // Set the background color
                          foregroundColor: Colors.white, // Set the text color
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12), // Optional padding
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                30), // Optional rounded corners
                          ),
                        ),
                        child: const Text(
                          "Submit",
                          style: TextStyle(
                              fontWeight:
                                  FontWeight.bold), // Additional text styling
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitCategorySuggestion(
      String category, String description) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception("User not authenticated.");

      final response = await http.post(
        Uri.parse(submitNewSuggestion),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "categoryName": category, // Correct key
          "description": description,
          "userType": 'User', // Assuming UserType is 'User'
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Suggestion submitted successfully!")),
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? "Failed to submit suggestion.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
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
          'Categories',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white70,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: Colors.white70),
            tooltip: "Suggest a Category",
            onPressed: () {
              _showSuggestionForm(context); // Open suggestion form
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Categories Section
          if (isLoadingCategories)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else
            Card(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: SingleChildScrollView(
                  controller: _categoryScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categories.map((category) {
                      final isSelected = category['_id'] == selectedCategoryId;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategoryId = category['_id'];
                          });
                          _updateLastVisitedCategory(
                              category['_id']); // Pass the correct categoryId

                          _fetchStores(category['_id']);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected ? myColor : Colors.grey,
                                    width: 2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: category['image'] != null &&
                                          category['image'].isNotEmpty
                                      ? Opacity(
                                          opacity: isSelected ? 0.7 : 1,
                                          child: Image.network(
                                            category['image'],
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey,
                                          child: Center(
                                            child: Text(
                                              category['name'][0],
                                              style: const TextStyle(
                                                fontSize: 30,
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color:
                                        isSelected ? myColor : Colors.black54,
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
          // Stores Section
          Expanded(
            child: isLoadingStores
                ? const Center(child: CircularProgressIndicator())
                : stores.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Center(
                          child: Text(
                            selectedCategoryId == null
                                ? 'Select a category to view stores.'
                                : 'Sorry, No stores available for this  category in this location.',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width < 600 ? 2 : 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: stores.length,
                        itemBuilder: (context, index) {
                          final store = stores[index];
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
                            child: Card(
                              color: Colors.white,
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        store['logo'] ?? '',
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.15,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.15,
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.15,
                                            color: Colors.grey,
                                            child: const Center(
                                              child: Icon(
                                                Icons.store,
                                                size: 40,
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      store['storeName'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Text(
                                      'review:',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
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
