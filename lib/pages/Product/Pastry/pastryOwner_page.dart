import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'addPastryProduct.dart';
import '../../../configuration/config.dart';
import '../EditPastryProduct.dart';

class PastryOwnerPage extends StatefulWidget {
  const PastryOwnerPage({super.key});

  @override
  _PastryOwnerPageState createState() => _PastryOwnerPageState();
}

class _PastryOwnerPageState extends State<PastryOwnerPage> {
  String businessName = 'Pastry Delights';
  List<Map<String, dynamic>> pastries = [];
  List<Map<String, dynamic>> filteredPastries = [];
  bool isLoading = true;
  bool _isAddingProduct = false;
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStoreDetails();
    fetchPastries();
  }

  Future<void> _fetchStoreDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token != null) {
        final response = await http.get(
          Uri.parse(getStoreDetails),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          setState(() {
            businessName = jsonResponse['storeName'] ?? businessName;
          });
        } else {
          throw Exception('Failed to load store details');
        }
      }
    } catch (e) {
      print('Error fetching store details: $e');
    }
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
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];

        if (mounted) {
          setState(() {
            pastries = List<Map<String, dynamic>>.from(data);
            filteredPastries = pastries; // Initialize filtered list
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load pastries');
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

  void _filterPastries(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredPastries = pastries;
      });
    } else {
      setState(() {
        filteredPastries = pastries
            .where((pastry) =>
                pastry['name'] != null &&
                pastry['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Authentication token not found. Please log in again.')),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse('${deleteProductByID}/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully!')),
        );
        setState(() {
          pastries.removeWhere((product) => product['_id'] == productId);
        });
      } else {
        throw Exception('Failed to delete product: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showDeleteConfirmationDialog(String productId, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete "$productName"?',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: myColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(productId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: Text(
          businessName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            color: Colors.white70,
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  filteredPastries = pastries; // Reset the filtered list
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching) // Show the search box only when searching
            Container(
              color: const Color.fromARGB(
                  171, 243, 229, 245), // Same background color as the AppBar
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: _filterPastries,
                style: const TextStyle(color: myColor),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: myColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor:
                      Colors.white24, // Lighten the background of the box
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Opacity(
                  opacity: 0.2,
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Color.fromARGB(135, 209, 183, 208)
                        /*
                      image: DecorationImage(
                        image: AssetImage('assets/images/pastry.jpg'),
                        fit: BoxFit.cover,
                      ),*/
                        ),
                  ),
                ),
                GridView.builder(
                  padding: const EdgeInsets.all(10.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 items per row
                    crossAxisSpacing: 10, // Space between columns
                    mainAxisSpacing: 10, // Space between rows
                    childAspectRatio: 3 / 4, // Adjust for item shape
                  ),
                  itemCount: filteredPastries.length +
                      1, // Include "Add Product" button
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: _isAddingProduct
                            ? null
                            : () async {
                                setState(() {
                                  _isAddingProduct = true;
                                });

                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddPastryProduct(),
                                  ),
                                );
                                await fetchPastries(); // Refresh data

                                setState(() {
                                  _isAddingProduct = false;
                                });
                              },
                        child: Card(
                          elevation: 4,
                          color: const Color.fromARGB(171, 243, 229, 245),
                          child: Center(
                            child: _isAddingProduct
                                ? const CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(myColor),
                                  )
                                : const Icon(
                                    Icons.add,
                                    size: 50,
                                    color: myColor,
                                  ),
                          ),
                        ),
                      );
                    }

                    final pastry = filteredPastries[index - 1];
                    return Card(
                      color: const Color.fromARGB(171, 243, 229, 245),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 120, // Fixed height for the image
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: pastry['image'] != null &&
                                          pastry['image'].isNotEmpty
                                      ? NetworkImage(pastry['image'])
                                          as ImageProvider
                                      : const AssetImage(
                                          'assets/images/pastry.jpg'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pastry['name'] ?? 'No Name',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${pastry['price']?.toStringAsFixed(2) ?? '0.00'}₪',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(), // Pushes icons to the bottom
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final updatedProduct = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditPastryProduct(product: pastry),
                                      ),
                                    );

                                    if (updatedProduct != null) {
                                      setState(() {
                                        pastries[index - 1] = updatedProduct;
                                      });
                                    }
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.transparent,
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: const Icon(
                                      Icons.edit,
                                      color: myColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showDeleteConfirmationDialog(
                                    pastry['_id'],
                                    pastry['name'],
                                  ),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.transparent,
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: const Icon(
                                      Icons.delete,
                                      color: myColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
