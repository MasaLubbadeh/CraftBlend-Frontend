import '../../configuration/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const DetailPage({super.key, required this.product});

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int _quantity = 1;
  final Map<String, Map<String, dynamic>?> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    // Initialize selected options with null for optional options or first value for required options
    widget.product['availableOptions']?.forEach((key, values) {
      if (values.isNotEmpty) {
        bool isOptional =
            widget.product['availableOptionStatus']?[key] ?? false;
        _selectedOptions[key] = isOptional ? null : values.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product['name'] ?? 'Product Details',
          style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: screenWidth * .08),
        ),
        foregroundColor: Colors.white70,
        backgroundColor: myColor,
        elevation: 5,
        toolbarHeight: appBarHeight,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.1,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image:
                      AssetImage('assets/images/pastriesBackgroundBorder.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
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
                  const SizedBox(height: 8),
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
      ),
    );
  }

  Widget _buildProductTitle(double screenWidth) {
    return Text(
      widget.product['name'] ?? 'Product Name',
      style: TextStyle(
        fontSize: screenWidth * 0.09,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
      ),
    );
  }

  Widget _buildProductSpecialNote() {
    return Text(
      widget.product['specialNote'] ?? 'New Product',
      style: const TextStyle(
        fontSize: 18,
        color: myColor,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildProductPrice(double screenWidth) {
    return Text(
      '${widget.product['price']?.toStringAsFixed(2) ?? '0.00'} ₪',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
      ),
    );
  }

  Widget _buildProductDescription() {
    return Text(
      widget.product['description'] ?? 'No description available.',
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black54,
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
                }).toList(),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return ElevatedButton(
      onPressed: () async {
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

        // Prepare data to send to the backend
        final Map<String, dynamic> cartItem = {
          'productId': widget.product['id'], // Assuming 'id' is the product ID
          'quantity': _quantity,
          'selectedOptions': _selectedOptions.map((key, value) => MapEntry(
              key, value != null ? value['name'] : null)), // Map options
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
                  content: Text('${widget.product['name']} added to cart!')),
            );
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
        backgroundColor: myColor,
        foregroundColor: Colors.white,
      ),
      child: const Text('Add to Cart'),
    );
  }
}
