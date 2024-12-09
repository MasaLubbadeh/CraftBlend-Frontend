import 'package:craft_blend_project/configuration/config.dart';
import 'package:craft_blend_project/pages/categoriesPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CartPage extends StatefulWidget {
  final Function(int)
      onTabChange; // Callback to change the tab in the BottomNavigationBar

  const CartPage({required this.onTabChange});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartData = [];
  bool isLoading = true;
  String? token; // To store the token globally within this state

  @override
  void initState() {
    super.initState();
    _initializeData(); // Fetch token and cart data
  }

  Future<void> _initializeData() async {
    await _fetchToken(); // Fetch token
    await fetchCartData(); // Fetch cart data using the token
  }

  Future<void> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    if (token == null) {
      print('Token not found. User might not be logged in.');
      // Handle token missing scenario, e.g., redirect to login
    }
  }

  Future<void> fetchCartData() async {
    if (token == null) return; // Ensure token is available
    try {
      final response = await http.get(Uri.parse(getCartData), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cartData = List<Map<String, dynamic>>.from(data['cart']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch cart data');
      }
    } catch (e) {
      print('Error fetching cart data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  double calculateTotalForStore(List<dynamic> items) {
    return items.fold(
        0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  double calculateCartTotal() {
    return cartData.fold(
        0, (sum, store) => sum + calculateTotalForStore(store['items']));
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
        title: const Text(
          'Your Cart',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Padding(
              padding: EdgeInsets.only(right: 5.0, top: 2),
              child: Icon(
                Icons.history,
                size: 30,
              ),
            ),
            color: Colors.white70,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CategoriesPage()),
              );
            },
            tooltip: 'Manage Orders',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Your cart is empty!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          widget.onTabChange(0); // Navigate to the first tab
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: myColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Start Shopping',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10.0),
                  itemCount: cartData.length,
                  itemBuilder: (context, index) {
                    final store = cartData[index];
                    final totalForStore =
                        calculateTotalForStore(store['items']);
                    return Card(
                      elevation: 15,
                      margin: const EdgeInsets.only(bottom: 10.0, top: 5),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.store),
                                const SizedBox(width: 5),
                                Text(
                                  store['storeName'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            Column(
                              children: store['items'].map<Widget>((item) {
                                return Card(
                                  elevation: 3,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            image: const DecorationImage(
                                              image: AssetImage(
                                                  'assets/images/pastry.jpg'),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['name'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${item['price'].toStringAsFixed(2)}₪',
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${(item['price'] * item['quantity']).toStringAsFixed(2)}₪',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Store Total:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text(
                                  '${totalForStore.toStringAsFixed(2)}₪',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: cartData.isEmpty
          ? null
          : Container(
              color: myColor.withOpacity(.8),
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${calculateCartTotal().toStringAsFixed(2)}₪',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white70),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Handle checkout
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: const Color.fromARGB(205, 255, 255, 255),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text(
                      'Checkout',
                      style: TextStyle(
                          color: myColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
