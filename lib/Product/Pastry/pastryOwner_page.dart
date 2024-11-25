import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'addPastryProduct.dart';
import '../../config.dart';
import '../EditPastryProduct.dart';

class PastryOwnerPage extends StatefulWidget {
  const PastryOwnerPage({super.key});

  @override
  _PastryOwnerPageState createState() => _PastryOwnerPageState();
}

class _PastryOwnerPageState extends State<PastryOwnerPage> {
  final String businessName = 'Pastry Delights';

  List<Map<String, dynamic>> pastries =
      []; // List to hold pastries fetched from the backend
  bool isLoading = true; // For showing a loading indicator while fetching data

  @override
  void initState() {
    super.initState();
    fetchPastries(); // Fetch the pastries when the page loads
  }

  Future<void> fetchPastries() async {
    try {
      // Replace with your backend endpoint
      final response = await http.get(
        Uri.parse('http://192.168.1.17:3000/product/getAllProducts'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          pastries =
              List<Map<String, dynamic>>.from(data); // Store fetched pastries
          isLoading = false; // Stop the loader
        });
      } else {
        throw Exception('Failed to load pastries');
      }
    } catch (e) {
      print('Error fetching pastries: $e');
      setState(() {
        isLoading = false; // Stop the loader even on failure
      });
    }
  }

  Future<void> _addNewProduct(Map<String, dynamic> newProduct) async {
    try {
      // Add the new product to the backend
      final response = await http.post(
        Uri.parse('http://192.168.1.17:3000/product/addNewPastryProduct'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(newProduct),
      );

      if (response.statusCode == 201) {
        setState(() {
          pastries.add(newProduct); // Update the local list
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!')),
        );
      } else {
        throw Exception('Failed to add product');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white70,
          onPressed: () => Navigator.pop(context),
        ),
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
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$businessName added to favorites')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.2,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/pastry.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator()) // Show loader if data is being fetched
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.add, color: myColor),
                          title: const Text(
                            'Add New Product',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddPastryProduct(
                                    // onAddProduct: _addNewProduct,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: pastries.length,
                          itemBuilder: (context, index) {
                            final pastry = pastries[index];
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 8),
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
                                              'images/pastry.jpg'), // Static image for now
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
                                          // Update the local product list with the edited product data
                                          setState(() {
                                            pastries[index] = updatedProduct;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
