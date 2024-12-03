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
  bool isLoading = true;

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
          Uri.parse(
              getStoreDetails), // Your backend endpoint for fetching store details
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
      print('STORE token :');
      print(token);

      final response = await http.get(
        Uri.parse(
            getStoreProducts), // Make sure the backend is setup to handle this endpoint
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Opacity(
                  opacity: 0.2,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/pastry.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                ListView.builder(
                  itemCount: 1 + pastries.length,
                  padding: const EdgeInsets.all(8.0),
                  itemBuilder: (context, index) {
                    if (index == 0) {
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
                            fetchPastries(); // Refresh after adding a product
                          },
                        ),
                      );
                    }

                    final productIndex = index - 1;
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
                                        image: AssetImage(
                                            'assets/images/pastry.jpg'),
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
                                          pastries[productIndex] =
                                              updatedProduct;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
