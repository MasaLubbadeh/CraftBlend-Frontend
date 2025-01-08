import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';
=======
>>>>>>> main
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
<<<<<<< HEAD
  String businessName = 'Pastry Delights';
  List<Map<String, dynamic>> pastries = [];
  List<Map<String, dynamic>> filteredPastries = [];
  bool isLoading = true;
  bool _isAddingProduct = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
=======
  final String businessName = 'Pastry Delights';

  List<Map<String, dynamic>> pastries = [];
  bool isLoading = true;

  // Define a count for header items
  static const int headerCount = 1;
>>>>>>> main

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
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
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
          // Check if `data` is a list or a map
          if (jsonResponse['data'] is List) {
            setState(() {
              pastries = List<Map<String, dynamic>>.from(jsonResponse['data']);
              filteredPastries = pastries; // Initialize filtered list
              isLoading = false;
            });
          } else if (jsonResponse['data'] is Map &&
              jsonResponse['data']['products'] != null) {
            setState(() {
              pastries = List<Map<String, dynamic>>.from(
                  jsonResponse['data']['products']);
              filteredPastries = pastries; // Initialize filtered list
              isLoading = false;
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
=======
    fetchPastries();
  }

  Future<void> fetchPastries() async {
    try {
      final response = await http.get(
        Uri.parse(getAllProducts),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          pastries = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load pastries');
      }
    } catch (e) {
      print('Error fetching pastries: $e');
      setState(() {
        isLoading = false;
>>>>>>> main
      });
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
<<<<<<< HEAD
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Authentication token not found. Please log in again.')),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse('$deleteProductByID/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
=======
      final response = await http.delete(
        Uri.parse('${deleteProductByID}/$productId'),
>>>>>>> main
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully!')),
        );
        setState(() {
          pastries.removeWhere((product) => product['_id'] == productId);
        });
      } else {
<<<<<<< HEAD
        throw Exception('Failed to delete product: ${response.body}');
=======
        throw Exception('Failed to delete product');
>>>>>>> main
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
<<<<<<< HEAD
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
=======
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
>>>>>>> main
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
<<<<<<< HEAD
            child: const Text(
              'Cancel',
              style: TextStyle(color: myColor),
            ),
=======
            child: const Text('Cancel'),
>>>>>>> main
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
<<<<<<< HEAD
        automaticallyImplyLeading: false,
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
=======
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white70,
          onPressed: () => Navigator.pop(context),
        ),
>>>>>>> main
        title: Text(
          businessName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
<<<<<<< HEAD
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
              color: const Color.fromARGB(171, 243, 229, 245),
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
=======
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
>>>>>>> main
              children: [
                Opacity(
                  opacity: 0.2,
                  child: Container(
                    decoration: const BoxDecoration(
<<<<<<< HEAD
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
                                    builder: (context) =>
                                        const AddPastryProduct(),
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
=======
                      image: DecorationImage(
                        image: AssetImage('images/pastry.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                ListView.builder(
                  itemCount: headerCount + pastries.length,
                  padding: const EdgeInsets.all(8.0),
                  itemBuilder: (context, index) {
                    // Handle header items first
                    if (index < headerCount) {
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.add, color: myColor),
                          title: const Text(
                            'Add New Product',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddPastryProduct(),
                              ),
                            );
                            // Fetch the updated list of pastries after adding a new product
                            fetchPastries();
                          },
>>>>>>> main
                        ),
                      );
                    }

<<<<<<< HEAD
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
=======
                    // Handle product items
                    final productIndex = index - headerCount;
                    final pastry = pastries[productIndex];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6.0, horizontal: 10.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Slidable(
                          key: ValueKey(pastry['_id']),
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            extentRatio: 0.26,
                            children: [
                              SlidableAction(
                                onPressed: (context) {
                                  _showDeleteConfirmationDialog(
                                      pastry['_id'], pastry['name']);
                                },
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          child: Card(
                            color: const Color.fromARGB(171, 243, 229, 245),
                            elevation: 5,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      image: const DecorationImage(
                                        image: AssetImage('images/pastry.jpg'),
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pastry['name'] ?? 'No Name',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${pastry['price']?.toStringAsFixed(2) ?? '0.00'}₪',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      final updatedProduct =
                                          await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditPastryProduct(
                                                  product: pastry),
                                        ),
                                      );

                                      if (updatedProduct != null) {
                                        setState(() {
                                          pastries[index - 1] = updatedProduct;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
>>>>>>> main
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
<<<<<<< HEAD
          ),
        ],
      ),
=======
>>>>>>> main
    );
  }
}
