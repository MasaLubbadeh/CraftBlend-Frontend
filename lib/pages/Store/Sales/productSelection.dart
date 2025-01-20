import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../configuration/config.dart';
import 'saleConfig.dart';

class ProductSelectionPage extends StatefulWidget {
  const ProductSelectionPage({Key? key}) : super(key: key);

  @override
  _ProductSelectionPageState createState() => _ProductSelectionPageState();
}

class _ProductSelectionPageState extends State<ProductSelectionPage> {
  List<Map<String, dynamic>> pastries = [];
  List<Map<String, dynamic>> filteredPastries = [];
  bool isLoading = true;
  bool isSelectAll = false;

  @override
  void initState() {
    super.initState();
    fetchPastries();
  }

  Future<void> fetchPastries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(getStoreProducts),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
          if (jsonResponse['data'] is List) {
            setState(() {
              pastries = List<Map<String, dynamic>>.from(jsonResponse['data']);
              filteredPastries = pastries;
              isLoading = false;
            });
          } else if (jsonResponse['data'] is Map &&
              jsonResponse['data']['products'] != null) {
            setState(() {
              pastries = List<Map<String, dynamic>>.from(
                  jsonResponse['data']['products']);
              filteredPastries = pastries;
              isLoading = false;

              for (var product in pastries) {
                print('these sre the products:$product');
              }
            });
          } else {
            throw Exception('Unexpected data structure in response.');
          }
        } else {
          throw Exception(
              'Failed to load pastries: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching pastries: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void toggleSelectAll(bool? value) {
    setState(() {
      isSelectAll = value ?? false;
      for (var product in pastries) {
        product['selected'] = isSelectAll;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'S A L E S',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: const Color.fromARGB(255, 233, 227, 236),
                  child: const Text(
                    'Select products you wish to include in the sale. You can select individual products or use the "Select All" option.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                if (filteredPastries.isNotEmpty)
                  CheckboxListTile(
                    title: const Text('Select All'),
                    value: isSelectAll,
                    onChanged: toggleSelectAll,
                  ),
                if (filteredPastries.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No products available.'),
                    ),
                  )
                else
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: filteredPastries.length,
                        itemBuilder: (context, index) {
                          final product = filteredPastries[index];
                          return ProductCard(
                            product: product,
                            onToggleSelection: (isSelected) {
                              setState(() {
                                product['selected'] = isSelected;
                              });

                              // Update "Select All" state
                              isSelectAll = filteredPastries
                                  .every((p) => p['selected'] == true);
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Collecting the IDs of selected products
          final selectedProductIds = pastries
              .where((product) => product['selected'] == true)
              .map((product) =>
                  product['_id'] as String) // Change from 'name' to 'id'
              .toList();

          if (selectedProductIds.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Please select at least one product')),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SaleConfigurationPage(
                selectedProductIds:
                    selectedProductIds, // Pass the IDs to the next page
              ),
            ),
          );
        },
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final Function(bool isSelected) onToggleSelection;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onToggleSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggleSelection(!(product['selected'] ?? false)),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: product['image'] != null
                    ? Image.network(
                        product['image'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : const Placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Unnamed Product',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Price: \$${product['price'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select',
                        style: TextStyle(fontSize: 14),
                      ),
                      Checkbox(
                        value: product['selected'] ?? false,
                        onChanged: (value) => onToggleSelection(value!),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
