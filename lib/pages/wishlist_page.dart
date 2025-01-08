import 'package:craft_blend_project/components/badge.dart';
import 'package:craft_blend_project/pages/Product/productDetails_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../configuration/config.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({Key? key}) : super(key: key);

  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<Map<String, dynamic>> wishlistProducts = [];
  List<Map<String, dynamic>> filteredWishlist = [];
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;
  bool isLoadingCategories = true;
  String selectedSortOrder = 'Recently Added'; // Default title for sorting
  String selectedCategory = 'All'; // Default title for categories
  String activeFilter = ''; // Tracks the active dropdown
  late double appBarHeight;

  @override
  void initState() {
    super.initState();
    _fetchWishlistProducts();
    _fetchCategories();
  }

  Future<String?> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchWishlistProducts() async {
    try {
      final token = await _fetchToken();
      if (token == null) {
        throw Exception("Token is missing.");
      }

      final response = await http.get(
        Uri.parse(getWishlistProducts),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        setState(() {
          wishlistProducts =
              List<Map<String, dynamic>>.from(jsonResponse['products']);
          filteredWishlist = wishlistProducts;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load wishlist products.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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
          categories.insert(0, {'name': 'All'}); // Add 'All' category
          isLoadingCategories = false;
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

  void _applyFilters() {
    List<Map<String, dynamic>> results = wishlistProducts;

    if (selectedCategory != 'All') {
      // Map the selected category name to its ID
      final selectedCategoryId = categories.firstWhere(
          (category) => category['name'] == selectedCategory)['_id'];

      // Filter products based on category ID
      results = results
          .where((product) => product['category'] == selectedCategoryId)
          .toList();
    }

    if (selectedSortOrder == 'Price Low to High') {
      results.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
    } else if (selectedSortOrder == 'Price High to Low') {
      results.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
    } else if (selectedSortOrder == 'Recently Added') {
      results = List.from(results); // No explicit sort; just preserve order
    }

    setState(() {
      filteredWishlist = results;
    });
  }

  Widget _buildDropdownMenu(String filterType, List<String> options) {
    return Positioned(
      top: appBarHeight * .6, // Dropdown starts below the filter row
      left: 0,
      right: 0,
      child: Material(
        elevation: 4,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: options.map((option) {
            return ListTile(
              title: Text(
                option,
                style: TextStyle(
                  color:
                      (filterType == 'Sort' && option == selectedSortOrder) ||
                              (filterType == 'Category' &&
                                  option == selectedCategory)
                          ? myColor
                          : Colors.black,
                  fontWeight:
                      (filterType == 'Sort' && option == selectedSortOrder) ||
                              (filterType == 'Category' &&
                                  option == selectedCategory)
                          ? FontWeight.bold
                          : FontWeight.normal,
                ),
              ),
              trailing: (filterType == 'Sort' && option == selectedSortOrder) ||
                      (filterType == 'Category' && option == selectedCategory)
                  ? const Icon(Icons.check, color: myColor)
                  : null,
              onTap: () {
                setState(() {
                  if (filterType == 'Sort') selectedSortOrder = option;
                  if (filterType == 'Category') selectedCategory = option;
                  activeFilter = ''; // Close the menu
                  _applyFilters();
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String formatTimeRequired(int? timeRequired) {
    if (timeRequired == null) return "No time specified";
    if (timeRequired < 24) {
      return "$timeRequired hours";
    } else {
      final days = (timeRequired / 24).ceil();
      return "$days day${days > 1 ? 's' : ''}";
    }
  }

  @override
  Widget build(BuildContext context) {
    appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight * 0.8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white70,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Wishlist',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Filter Row
              Container(
                color: myColor,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Sort Filter
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          activeFilter =
                              activeFilter == 'Sort' ? '' : 'Sort'; // Toggle
                        });
                      },
                      child: FilterButton(
                        text: selectedSortOrder == 'Recently Added'
                            ? 'Sort'
                            : selectedSortOrder,
                        isActive: activeFilter == 'Sort',
                      ),
                    ),
                    // Category Filter
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          activeFilter =
                              activeFilter == 'Category' ? '' : 'Category';
                        });
                      },
                      child: FilterButton(
                        text: selectedCategory == 'All'
                            ? 'Category'
                            : selectedCategory,
                        isActive: activeFilter == 'Category',
                      ),
                    ),
                  ],
                ),
              ),
              // Content Placeholder
              Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: myColor),
                        )
                      : filteredWishlist.isEmpty
                          ? const Center(
                              child: Text(
                                'No products found.',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(10.0),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.7,
                              ),
                              itemCount: filteredWishlist.length,
                              itemBuilder: (context, index) {
                                final product = filteredWishlist[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetailPage(product: product),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    color: const Color.fromARGB(
                                        171, 243, 229, 245),
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 110,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              image: DecorationImage(
                                                image: product['image'] !=
                                                            null &&
                                                        product['image']
                                                            .isNotEmpty
                                                    ? NetworkImage(
                                                            product['image'])
                                                        as ImageProvider
                                                    : const AssetImage(
                                                        'assets/images/pastry.jpg'),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Product Title
                                              Expanded(
                                                child: Text(
                                                  product['name'] ?? 'No Name',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow
                                                      .ellipsis, // Prevent overflow
                                                ),
                                              ),
                                              const SizedBox(
                                                  width:
                                                      5), // Add spacing between title and badge
                                              // Badge for Out of Stock or Special Note
                                              /*if ((pastry['inStock'] == false) &&
                                            (pastry['isUponOrder'] ==
                                                false)) // Out of Stock
                                          const badge(
                                            text: 'Out of Stock',
                                            color: Colors.redAccent,
                                          )
                                        else if (pastry['specialNote'] !=
                                            null) // Special Note
                                          badge(
                                            text: pastry['specialNote'] ?? '',
                                            color: Colors
                                                .blueAccent, // Adjust color as needed
                                          ),
                                          */
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${product['price']?.toStringAsFixed(2) ?? '0.00'}₪',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const Spacer(),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  // Display badges for Upon Order and Time Required
                                                  if (product['isUponOrder'] ==
                                                      true)
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const badge(
                                                          text: 'Upon Order',
                                                          color: Colors
                                                              .orangeAccent,
                                                        ),
                                                        SizedBox(
                                                          height: 2,
                                                        ),
                                                        if (product[
                                                                'timeRequired'] !=
                                                            null) // Time Required Badge
                                                          badge(
                                                            text: formatTimeRequired(
                                                                product[
                                                                    'timeRequired']),
                                                            color: myColor
                                                                .withOpacity(
                                                                    .6),
                                                            icon: Icons
                                                                .timer, // Add a time icon
                                                          ),
                                                      ],
                                                    ),

                                                  // Display Out of Stock Badge
                                                  if ((product['inStock'] ==
                                                          false) &&
                                                      (product['isUponOrder'] ==
                                                          false))
                                                    const badge(
                                                      text: 'Out of Stock',
                                                      color: Colors.redAccent,
                                                    ),
                                                ],
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.arrow_forward,
                                                  color: myColor,
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          DetailPage(
                                                              product: product),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )),
            ],
          ),
          // Dropdown Menus
          if (activeFilter == 'Sort')
            _buildDropdownMenu('Sort',
                ['Recently Added', 'Price Low to High', 'Price High to Low']),
          if (activeFilter == 'Category')
            _buildDropdownMenu('Category',
                categories.map((e) => e['name'] as String).toList()),
        ],
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  final String text;
  final bool isActive;

  const FilterButton({Key? key, required this.text, required this.isActive})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine if the text is a non-default value
    final bool isNonDefaultValue = text != 'Sort' && text != 'Category';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : myColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color: isActive ? myColor : Colors.white,
              fontWeight: isActive || isNonDefaultValue
                  ? FontWeight.bold
                  : FontWeight.normal, // Make bold for non-default values
              fontSize: 14,
            ),
          ),
          Icon(
            isActive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: isActive ? myColor : Colors.white,
            size: 18,
          ),
        ],
      ),
    );
  }
}
