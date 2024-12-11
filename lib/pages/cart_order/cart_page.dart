import 'package:craft_blend_project/configuration/config.dart';
import 'package:craft_blend_project/pages/categoriesPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Product/productDetails_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartPage extends StatefulWidget {
  final Function(int) onTabChange;

  const CartPage({required this.onTabChange});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartData = [];
  bool isLoading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchToken();
    await fetchCartData();
  }

  Future<void> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    if (token == null) {
      print('Token not found. User might not be logged in.');
    }
  }

  Future<void> fetchCartData() async {
    if (token == null) return;
    try {
      final response = await http.get(Uri.parse(getCartData), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        print(response.body);
        final data = json.decode(response.body);
        if (data['cart'] != null && data['cart']['items'] != null) {
          setState(() {
            cartData = List<Map<String, dynamic>>.from(data['cart']['items']);
            isLoading = false;
          });
        } else {
          setState(() {
            cartData = [];
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to fetch cart data');
      }
    } catch (e) {
      print('Error fetching cart data: $e');
      setState(() {
        cartData = [];
        isLoading = false;
      });
    }
  }

  double calculateCartTotal() {
    if (cartData.isEmpty) return 0.0;
    return cartData.fold(
      0.0,
      (sum, item) =>
          sum + (item['productId']['price'] ?? 0) * (item['quantity'] ?? 0),
    );
  }

  double calculateStoreSubtotal(List<Map<String, dynamic>> storeItems) {
    return storeItems.fold(
      0.0,
      (sum, item) =>
          sum + (item['productId']['price'] ?? 0) * (item['quantity'] ?? 0),
    );
  }

  Map<String, List<Map<String, dynamic>>> groupByStore() {
    return cartData.fold({}, (grouped, item) {
      final storeId = item['storeId']['_id'];
      final storeName = item['storeId']['storeName'];
      final storeIcon = item['storeId']['icon'];

      if (!grouped.containsKey(storeId)) {
        grouped[storeId] = [];
      }

      grouped[storeId]!.add({
        ...item,
        'storeName': storeName,
        'storeIcon': storeIcon,
      });
      return grouped;
    });
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
                          widget.onTabChange(0);
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
              : _buildGroupedCartListView(),
      bottomNavigationBar: cartData.isEmpty ? null : _buildBottomCheckoutBar(),
    );
  }

  Widget _buildGroupedCartListView() {
    final groupedData = groupByStore();
    return ListView.builder(
      padding: const EdgeInsets.all(10.0),
      itemCount: groupedData.keys.length,
      itemBuilder: (context, index) {
        final storeId = groupedData.keys.elementAt(index);
        final storeItems = groupedData[storeId]!;
        final storeName = storeItems.first['storeName'];
        final storeIcon = storeItems.first['storeIcon'];
        final storeSubtotal = calculateStoreSubtotal(storeItems);

        return Card(
          elevation: 5,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    storeIcon != null
                        ? Image.network(
                            storeIcon,
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.store,
                            size: 30, color: Colors.black87),
                    const SizedBox(width: 10),
                    Text(
                      storeName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                ...storeItems.map((item) => _buildCartItem(item)).toList(),
                const Divider(),
                //const SizedBox(height: 2),
                Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Subtotal: ${storeSubtotal.toStringAsFixed(2)}₪',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final product = item['productId'];
    final productName = product?['name'] ?? 'No Name';
    final productImage = product?['image'];
    final productPrice = product?['price'] ?? 0;
    final quantity = item['quantity'] ?? 0;
    final selectedOptions = item['selectedOptions'] ?? {};

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(product: product),
          ),
        ).then((_) {
          // Re-fetch the cart data when returning from the detail page
          fetchCartData();
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: productImage != null
                      ? NetworkImage(productImage)
                      : const AssetImage('assets/images/pastry.jpg')
                          as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    children: selectedOptions.entries.map<Widget>((entry) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: myColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${entry.key}  :  ${entry.value}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Quantity:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: quantity > 1
                                ? () => setState(() {
                                      item['quantity'] -= 1;
                                      updateCart(item);
                                    })
                                : null,
                            child: Container(
                              width: 25,
                              height: 25,
                              decoration: BoxDecoration(
                                color: quantity > 1
                                    ? Colors.grey[300]
                                    : Colors.grey,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Icon(
                                quantity > 1 ? Icons.remove : Icons.delete,
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            width: 35,
                            height: 25,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            child: Center(
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() {
                              item['quantity'] += 1;
                              updateCart(item);
                            }),
                            child: Container(
                              width: 25,
                              height: 25,
                              decoration: BoxDecoration(
                                color: myColor.withOpacity(.7),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${(productPrice * quantity).toStringAsFixed(2)}₪',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void updateCart(Map<String, dynamic> updatedItem) {
    setState(() {
      // Replace the updated item in the cartData list
      final index = cartData.indexWhere((item) =>
          item['productId']['_id'] == updatedItem['productId']['_id']);
      if (index != -1) {
        cartData[index] = updatedItem;
      }
    });
  }

  Widget _buildBottomCheckoutBar() {
    return Container(
      color: myColor.withOpacity(.8),
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${calculateCartTotal().toStringAsFixed(2)}₪',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checkout not implemented yet')),
              );
            },
            style: ElevatedButton.styleFrom(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text(
              'Checkout',
              style: TextStyle(
                color: myColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
