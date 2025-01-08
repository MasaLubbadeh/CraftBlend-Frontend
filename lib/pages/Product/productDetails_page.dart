<<<<<<< HEAD
import 'package:craft_blend_project/components/badge.dart';

import '../../configuration/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
=======
import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';
>>>>>>> main

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const DetailPage({super.key, required this.product});

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int _quantity = 1;
  final Map<String, Map<String, dynamic>?> _selectedOptions = {};
<<<<<<< HEAD
  bool isInWishlist = false;
=======
>>>>>>> main

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _checkIfInWishlist();
    _trackProductVisit(); // Track the visit for this product

=======
>>>>>>> main
    // Initialize selected options with null for optional options or first value for required options
    widget.product['availableOptions']?.forEach((key, values) {
      if (values.isNotEmpty) {
        bool isOptional =
            widget.product['availableOptionStatus']?[key] ?? false;
        _selectedOptions[key] = isOptional ? null : values.first;
      }
    });
  }

<<<<<<< HEAD
  Future<String?> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _trackProductVisit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userType = prefs.getString('userType');

      if (userType != 'user') {
        return; // Exit if userType is not 'user'
      }

      final productId = widget.product['_id'];

      final response = await http.post(
        Uri.parse(addProductVisit), // Configured in your backend
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'productId': productId}),
      );

      if (response.statusCode == 200) {
        print('Product visit tracked successfully.');
      } else {
        print(
            'Failed to track product visit: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      print('Error tracking product visit: $error');
    }
  }

  Future<void> _checkIfInWishlist() async {
    try {
      final token = await _fetchToken();
      if (token == null) {
        throw Exception("Token is missing.");
      }

      final response = await http.get(
        Uri.parse('$checkIfInWishlist/${widget.product['_id']}'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          isInWishlist = jsonResponse['isInWishlist'] ?? false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } else {
        // Optionally log the error if the widget is unmounted
        print(
            'Error occurred but the widget is no longer mounted: ${e.toString()}');
      }
    }
  }

  Future<void> _toggleWishlist() async {
    try {
      final token = await _fetchToken();
      if (token == null) {
        throw Exception("Token is missing.");
      }

      final Uri url = Uri.parse(isInWishlist
          ? '$removeFromWishlist/${widget.product['_id']}'
          : '$addToWishlist/${widget.product['_id']}');

      final response = await (isInWishlist
          ? http.delete(
              url,
              headers: {
                "Authorization": "Bearer $token",
                "Content-Type": "application/json",
              },
            )
          : http.post(
              url,
              headers: {
                "Authorization": "Bearer $token",
                "Content-Type": "application/json",
              },
            ));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          setState(() {
            isInWishlist = !isInWishlist;
          });

          final message = isInWishlist
              ? '${widget.product['name']} added to wishlist!'
              : '${widget.product['name']} removed from wishlist!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        } else {
          throw Exception(jsonResponse['message'] ?? 'Action failed.');
        }
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _confirmToggleWishlist() {
    if (!isInWishlist) {
      _toggleWishlist(); // Directly add to wishlist without confirmation.
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Wishlist'),
        content: const Text(
            'Are you sure you want to remove this product from your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleWishlist();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
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

=======
>>>>>>> main
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product['name'] ?? 'Product Details',
          style: TextStyle(
<<<<<<< HEAD
              fontWeight: FontWeight.w900, fontSize: screenWidth * .06),
=======
              fontWeight: FontWeight.w900, fontSize: screenWidth * .08),
>>>>>>> main
        ),
        foregroundColor: Colors.white70,
        backgroundColor: myColor,
        elevation: 5,
        toolbarHeight: appBarHeight,
<<<<<<< HEAD
        centerTitle: true,
=======
>>>>>>> main
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
<<<<<<< HEAD
=======
          Opacity(
            opacity: 0.1,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/pastriesBackgroundBorder.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
>>>>>>> main
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(screenWidth),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildProductTitle(screenWidth),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: screenWidth * 0.05),
                        child: _buildProductPrice(screenWidth),
                      ),
                    ],
                  ),
<<<<<<< HEAD
                  const SizedBox(height: 10),
=======
                  const SizedBox(height: 8),
>>>>>>> main
                  _buildProductSpecialNote(),
                  const SizedBox(height: 16),
                  _buildProductDescription(),
                  const SizedBox(height: 20),
                  Card(
                    color: myColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuantitySelector(screenWidth),
                          const SizedBox(height: 16),
                          _buildDynamicOptionSelectors(screenWidth),
                        ],
                      ),
                    ),
                  ),
<<<<<<< HEAD
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 9.0, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      isInWishlist ? Icons.favorite : Icons.favorite_border,
                      color: myColor,
                      size: 26,
                    ),
                    onPressed: _confirmToggleWishlist,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: _buildAddToCartButton(),
=======
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: _buildAddToCartButton(),
                      ),
                    ),
>>>>>>> main
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(double screenWidth) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
<<<<<<< HEAD
        child: widget.product['image'] != null &&
                widget.product['image'].isNotEmpty
            ? Image.network(
                widget.product['image'],
                width: screenWidth * 0.8,
                height: screenWidth * 0.8,
                fit: BoxFit.cover,
              )
            : Image.asset(
                'assets/images/donut.jpg',
                width: screenWidth * 0.8,
                height: screenWidth * 0.8,
                fit: BoxFit.cover,
              ),
=======
        child: Image.asset(
          'images/donut.jpg',
          width: screenWidth * 0.8,
          height: screenWidth * 0.8,
          fit: BoxFit.cover,
        ),
>>>>>>> main
      ),
    );
  }

  Widget _buildProductTitle(double screenWidth) {
<<<<<<< HEAD
    final double productRating =
        (widget.product['rating']?['average'] ?? 0.0).toDouble();
    final int totalRatings = widget.product['rating']?['count'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product['name'] ?? 'Product Name',
          style: TextStyle(
            fontSize: screenWidth * 0.09,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        // const SizedBox(height: 2), // Space between the title and rating
        if (productRating > 0) _buildStarRating(productRating, totalRatings),
      ],
=======
    return Text(
      widget.product['name'] ?? 'Product Name',
      style: TextStyle(
        fontSize: screenWidth * 0.09,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
      ),
>>>>>>> main
    );
  }

  Widget _buildProductSpecialNote() {
<<<<<<< HEAD
    if (widget.product['isUponOrder'] == true) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Row(
          children: [
            const badge(
              text: 'Upon Order',
              color: Colors.orangeAccent,
            ),
            const SizedBox(width: 8),
            if (widget.product['timeRequired'] != null)
              badge(
                text:
                    "You should order it before: ${formatTimeRequired(widget.product['timeRequired'])}",
                color: myColor.withOpacity(.6),
                icon: Icons.timer, // Optional icon
              ),
          ],
        ),
      );
    } else if (widget.product['inStock'] == false) {
      return const badge(
        text: 'Out of Stock',
        color: Colors.redAccent,
      );
    } else {
      return const badge(
        text: 'Available',
        color: Colors.green,
      );
    }
=======
    return Text(
      widget.product['specialNote'] ?? 'New Product',
      style: const TextStyle(
        fontSize: 18,
        color: myColor,
        fontStyle: FontStyle.italic,
      ),
    );
>>>>>>> main
  }

  Widget _buildProductPrice(double screenWidth) {
    return Text(
<<<<<<< HEAD
      '${calculatePriceWithExtra().toStringAsFixed(2)} ₪',
=======
      '${widget.product['price']?.toStringAsFixed(2) ?? '0.00'} ₪',
>>>>>>> main
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
      ),
    );
  }

<<<<<<< HEAD
  double calculatePriceWithExtra() {
    double basePrice = (widget.product['price'] ?? 0.0)
        .toDouble(); // Ensure basePrice is a double
    double extraCost = 0.0;

    _selectedOptions.forEach((key, value) {
      if (value != null && value['extraCost'] != null) {
        extraCost += (value['extraCost'] as num)
            .toDouble(); // Safely cast extraCost to double
      }
    });

    return (basePrice + extraCost);
  }

  Widget _buildProductDescription() {
    return Container(
      alignment: Alignment.center,
      child: Text(
        widget.product['description'] ?? 'No description available.',
        style: const TextStyle(
            fontSize: 16, color: Colors.black54, letterSpacing: 1.5),
        textAlign: TextAlign.center,
=======
  Widget _buildProductDescription() {
    return Text(
      widget.product['description'] ?? 'No description available.',
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black54,
>>>>>>> main
      ),
    );
  }

  Widget _buildQuantitySelector(double screenWidth) {
    final padding = screenWidth * 0.06;
    return Row(
      children: [
        Padding(
          padding: EdgeInsets.only(right: padding),
          child: const Text('Quantity: ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              )),
        ),
        _buildCircleButton(Icons.remove, () {
          setState(() {
            if (_quantity > 1) {
              _quantity--;
            }
          });
        }),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Text('$_quantity', style: const TextStyle(fontSize: 18)),
        ),
        _buildCircleButton(Icons.add, () {
          setState(() {
            _quantity++;
          });
        }),
      ],
    );
  }

  Widget _buildCircleButton(IconData icon, Function onPressed) {
    return GestureDetector(
      onTap: () => onPressed(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white70,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: myColor, size: 18),
      ),
    );
  }

  Widget _buildDynamicOptionSelectors(double screenWidth) {
    final validOptions = widget.product['availableOptions']?.entries
        ?.where((entry) => entry.value != null && entry.value.isNotEmpty)
        ?.toList();

    if (validOptions == null || validOptions.isEmpty) {
      return Text(
        'No customization options available for this product.',
        style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.black54),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: validOptions.map<Widget>((entry) {
        return _buildOptionSelector(entry.key, entry.value, screenWidth,
            isOptional:
                widget.product['availableOptionStatus']?[entry.key] ?? false);
      }).toList(),
    );
  }

  Widget _buildOptionSelector(
      String optionKey, List<dynamic> optionValues, double screenWidth,
      {required bool isOptional}) {
    return Card(
      color: const Color.fromARGB(202, 255, 255, 255),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$optionKey:',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButton<Map<String, dynamic>?>(
              value: _selectedOptions[optionKey],
              onChanged: (Map<String, dynamic>? newValue) {
                setState(() {
                  _selectedOptions[optionKey] = newValue;
                });
              },
              isExpanded: true,
              dropdownColor: Colors.grey[200],
              underline: Container(
                height: 2,
                color: myColor,
              ),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: myColor,
              ),
              items: [
                if (isOptional)
                  const DropdownMenuItem<Map<String, dynamic>?>(
                    value: null,
                    child: Text(
                      'Choose',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ...optionValues.map<DropdownMenuItem<Map<String, dynamic>>>(
                    (dynamic value) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: value,
                    child: Text(
                      '${value['name']} (${value['extraCost'] > 0 ? '+${value['extraCost']} ₪' : '+0 ₪'})',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  );
<<<<<<< HEAD
                }),
=======
                }).toList(),
>>>>>>> main
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAddToCartButton() {
<<<<<<< HEAD
    final int availableStock =
        widget.product['stock'] ?? 0; // Available stock from the product

    return ElevatedButton(
      onPressed: (availableStock == 0) && (!widget.product['isUponOrder'])
          ? null // Disable button if out of stock
          : () async {
              if (_quantity > availableStock) {
                // Show alert if requested quantity exceeds available stock
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Only $availableStock items are available in stock. Please adjust your quantity.',
                    ),
                  ),
                );
                return;
              }

              // Validate required options
              for (final key in _selectedOptions.keys) {
                bool isOptional =
                    widget.product['availableOptionStatus']?[key] ?? false;
                if (!isOptional && _selectedOptions[key] == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Please select an option for $key.')),
                  );
                  return;
                }
              }

              // Prepare data to send to the backend
              final Map<String, dynamic> cartItem = {
                'productId': widget.product['_id'],
                'storeId': widget.product['store'],
                'quantity': _quantity,
                'selectedOptions': _selectedOptions.map((key, value) =>
                    MapEntry(key, value != null ? value['name'] : null)),
                'pricePerUnitWithOptionsCost': calculatePriceWithExtra(),
              };

              try {
                // Fetch the token from SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                final String? token = prefs.getString('token');
                if (token == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You are not logged in.')),
                  );
                  return;
                }

                // Make the POST request to add to the cart
                final response = await http.post(
                  Uri.parse(addNewCartItem),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Content-Type': 'application/json',
                  },
                  body: json.encode(cartItem),
                );

                // Handle the response
                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.product['name']} added to cart!'),
                    ),
                  );
                  // Pop to the previous page
                  Navigator.pop(context);
                } else {
                  final error =
                      json.decode(response.body)['message'] ?? 'Unknown error';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add to cart: $error')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('An error occurred: $e')),
                );
              }
            },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        backgroundColor:
            (availableStock == 0 && (!widget.product['isUponOrder']))
                ? Colors.grey
                : myColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(availableStock == 0 ? 'Out of Stock' : 'Add to Cart'),
    );
  }

  Widget _buildStarRating(double rating, int totalRatings, {int maxStars = 5}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Display the stars
          Row(
            children: List.generate(maxStars, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: myColor,
                size: 20, // Adjust the size of the stars as needed
              );
            }),
          ),
          const SizedBox(width: 8), // Space between stars and count
          // Display the total ratings
          Text(
            '($totalRatings)',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
=======
    return ElevatedButton(
      onPressed: () {
        // Validate required options
        for (final key in _selectedOptions.keys) {
          bool isOptional =
              widget.product['availableOptionStatus']?[key] ?? false;
          if (!isOptional && _selectedOptions[key] == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please select an option for $key.')),
            );
            return;
          }
        }
        print('Adding to cart:');
        print('Product: ${widget.product['name']}');
        print('Quantity: $_quantity');
        print('Selected Options: $_selectedOptions');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.product['name']} added to cart!')),
        );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        backgroundColor: myColor,
        foregroundColor: Colors.white,
      ),
      child: const Text('Add to Cart'),
>>>>>>> main
    );
  }
}
