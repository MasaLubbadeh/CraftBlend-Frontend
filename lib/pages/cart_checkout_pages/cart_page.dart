import 'package:craft_blend_project/configuration/config.dart';
import 'package:craft_blend_project/pages/Home_page.dart';
import 'package:craft_blend_project/pages/User/UserOrders_page.dart';
import 'package:craft_blend_project/pages/categoriesPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Product/productDetails_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'DeliveryTime_Page.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  final Function(int) onTabChange;

  const CartPage({required this.onTabChange});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> cartData = [];
  List<Map<String, dynamic>> specialOrders = []; // New list for special orders

  bool isLoading = true;
  String? token;
  late TabController _tabController;

  List<Map<String, dynamic>> getInstantItems() {
    return cartData
        .where((item) => item['productId']?['deliveryType'] == 'instant')
        .toList();
  }

  List<Map<String, dynamic>> getScheduledItems() {
    return cartData
        .where((item) =>
            item['productId']?['deliveryType'] == 'scheduled' ||
            (item['isSpecialOrder'] ?? false))
        .toList();
  }

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchToken();
    await Future.wait([
      fetchCartData(),
      fetchSpecialOrders()
    ]); // Fetch both cart and special orders
    _mergeSpecialOrdersIntoCart();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    if (token == null) {
      print('Token not found. User might not be logged in.');
      // Optionally, navigate to the login page or show an alert
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
          });
        } else {
          setState(() {
            cartData = [];
          });
        }
      } else {
        throw Exception('Failed to fetch cart data');
      }
    } catch (e) {
      print('Error fetching cart data: $e');
      if (mounted) {
        setState(() {
          cartData = [];
        });
      }
      // Optionally, display a snackbar or alert to inform the user
    }
  }

  Future<void> fetchSpecialOrders() async {
    if (token == null) return;
    try {
      final response =
          await http.get(Uri.parse(getUserSpecialOrders), headers: {
        'Authorization': 'Bearer $token',
      });
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['orders'] != null) {
          setState(() {
            specialOrders = List<Map<String, dynamic>>.from(data['orders']);
          });
        } else {
          setState(() {
            specialOrders = [];
          });
        }
      } else {
        throw Exception('Failed to fetch special orders');
      }
    } catch (e) {
      print('Error fetching special orders: $e');
      setState(() {
        specialOrders = [];
      });
      // Optionally, display a snackbar or alert to inform the user
    }
  }

  void _mergeSpecialOrdersIntoCart() {
    for (var order in specialOrders) {
      String specialName = '';

      // Extract names from all orderItems
      if (order['orderItems'] != null && order['orderItems'] is List) {
        List<dynamic> orderItems = order['orderItems'];
        specialName = orderItems
            .map((item) => item['optionId']?['name'] ?? 'Unknown')
            .join(', '); // Combine names if there are multiple
      }
      // Create a cart-like map for consistency
      Map<String, dynamic> specialOrderItem = {
        'isSpecialOrder': true, // Flag to identify special orders
        'orderId': order['_id'],
        'storeId':
            order['storeId'], // Already populated with storeName and icon
        'productId': null, // Not applicable for special orders
        'specialName': specialName, // Identifier
        'image': order['photoUrl'] ??
            'assets/images/specialicon.png', // Placeholder image
        'pricePerUnitWithOptionsCost': (order['status'] == 'Confirmed'
                ? (order['totalPrice'] ?? 0)
                : (order['estimatedPrice'] ?? 0))
            .toDouble(),
        'totalPriceWithQuantity': (order['status'] == 'Confirmed'
                ? (order['totalPrice'] ?? 0)
                : (order['estimatedPrice'] ?? 0))
            .toDouble(),

        'quantity': 1, // Typically, special orders have a quantity of 1
        'selectedOptions': {}, // Or any relevant data
        'status': order['status'] ?? 'Pending', // 'Pending' or 'Confirmed'
      };
      if (specialOrderItem['status'] == 'Pending' ||
          specialOrderItem['status'] == 'Confirmed')
        cartData.add(specialOrderItem);
    }
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs
        .getString('token'); // Adjust the key based on your implementation
  }

  double calculateInstantTotal() {
    final instantItems = getInstantItems();
    return instantItems.fold(
      0.0,
      (sum, item) => sum + (item['totalPriceWithQuantity'] ?? 0.0),
    );
  }

  double calculateScheduledTotal() {
    final scheduledItems = getScheduledItems();
    return scheduledItems.fold(
      0.0,
      (sum, item) => sum + (item['totalPriceWithQuantity'] ?? 0.0),
    );
  }

  double calculateStoreSubtotal(List<Map<String, dynamic>> storeItems) {
    return storeItems.fold(
      0.0,
      (sum, item) => sum + (item['totalPriceWithQuantity'] ?? 0.0),
    );
  }

  Map<String, List<Map<String, dynamic>>> groupByStore(
      List<Map<String, dynamic>> items) {
    return items.fold({}, (grouped, item) {
      final storeId = item['storeId']?['_id'] ??
          'unknown'; // Default key if storeId is null
      final storeName = item['storeId']?['storeName'] ?? 'Unnamed Store';
      final storeIcon = item['storeId']?['icon'];

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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                  MaterialPageRoute(
                      builder: (context) => const UserOrdersPage()),
                );
              },
              tooltip: 'Manage Orders',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: "Instant Delivery"),
              Tab(text: "Scheduled Delivery"),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildInstantDeliveryTab(),
                  _buildScheduledDeliveryTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildInstantDeliveryTab() {
    final instantItems = getInstantItems();

    if (instantItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No items available for instant delivery.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.onTabChange(0); // Navigate to shopping section
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: myColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
      );
    }

    return Column(
      children: [
        Expanded(child: _buildGroupedCartListView(instantItems)),
        _buildBottomCheckoutBar('instant'), // Correct type
      ],
    );
  }

  Widget _buildScheduledDeliveryTab() {
    final scheduledItems = getScheduledItems();

    if (scheduledItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No items available for scheduled delivery.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.onTabChange(0); // Navigate to shopping section
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: myColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
      );
    }

    return Column(
      children: [
        Expanded(child: _buildGroupedCartListView(scheduledItems)),
        _buildBottomCheckoutBar('scheduled'), // Correct type
      ],
    );
  }

  Widget _buildGroupedCartListView(List<Map<String, dynamic>> items) {
    final groupedData = groupByStore(items);

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
                // Store Header
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
                // List of Items
                ...storeItems.map((item) => _buildCartItem(item)).toList(),
                const Divider(),
                Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Subtotal: ${storeSubtotal.toStringAsFixed(2)}₪',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
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
    final bool isSpecialOrder = item['isSpecialOrder'] ?? false;

    if (isSpecialOrder) {
      // Handle Special Order
      final String storeName = item['storeId']['storeName'] ?? 'Unnamed Store';
      final String? storeIcon = item['storeId']['icon'];
      final String status = item['status'] ?? 'Pending';
      final String specialName = item['specialName'] ?? 'Special Order';
      print('itemspecialName ');
      print(item['storeId']['specialName']);
      final double estimatedPrice =
          (item['pricePerUnitWithOptionsCost'] ?? 0).toDouble();

      // Determine the image provider
      ImageProvider imageProvider;
      if (item['image'] != null &&
          item['image'].toString().startsWith('http')) {
        imageProvider = NetworkImage(item['image']);
      } else {
        imageProvider = const AssetImage('assets/images/specialicon.png');
      }

      return Card(
        color: status == 'Pending'
            ? const Color.fromARGB(171, 243, 229, 245)
            : const Color.fromARGB(171, 243, 229, 245), // Dim color if pending
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Removed Store Header to avoid redundancy

              // Status Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'Pending'
                          ? Colors.orangeAccent
                          : Colors
                              .greenAccent.shade700, // Color based on status
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(),

              // Special Order Details
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Special Order Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image:
                            imageProvider, // Use the determined image provider
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Special Order Info
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          specialName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 7),
                        /*  Text(
                          'Status: $status',
                          style: TextStyle(
                            fontSize: 14,
                            color: status == 'Pending'
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),*/
                        const SizedBox(height: 15),
                        // Display Estimated Price if Pending
                        if (status == 'Pending')
                          Text(
                            'Estimated Price: ${estimatedPrice.toStringAsFixed(2)}₪',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Pricing Details (if Confirmed)
                  if (status == 'Confirmed')
                    Flexible(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item['totalPriceWithQuantity'].toStringAsFixed(2)}₪',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Disable actions if Pending
              if (status == 'Confirmed')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Quantity Selector
                      // Remove Button
                      Text(
                        'To remove this order, please contact the store owner.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      // Handle Regular Cart Item
      final String productName = item['productId']['name'] ?? 'No Name';
      final String? productImage = item['productId']['image'];
      final double unitPrice =
          (item['pricePerUnitWithOptionsCost'] ?? 0).toDouble();
      final double itemTotalPrice =
          (item['totalPriceWithQuantity'] ?? 0).toDouble();
      final int quantity = item['quantity'] ?? 0;
      final Map<String, dynamic> selectedOptions =
          item['selectedOptions'] ?? {};

      // Determine the image provider
      ImageProvider imageProvider;
      if (productImage != null && productImage.toString().startsWith('http')) {
        imageProvider = NetworkImage(productImage);
      } else {
        imageProvider = const AssetImage('assets/images/pastry.jpg');
      }

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(product: item['productId']),
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
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: imageProvider, // Use the determined image provider
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Product Details
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis, // Prevent overflow
                      maxLines: 1,
                    ),
                    const SizedBox(height: 7),
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
                            '${entry.key}: ${entry.value ?? 'None'}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 15),
                    // Quantity Selector
                    Row(
                      mainAxisSize: MainAxisSize.min,
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
                              onTap: () {
                                if (quantity > 1) {
                                  setState(() {
                                    item['quantity'] -= 1;
                                    updateCart(item);
                                  });
                                } else {
                                  // Confirm deletion before removing the item
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Remove Item"),
                                        content: const Text(
                                            "Do you want to remove this item from your cart?"),
                                        actions: [
                                          TextButton(
                                            child: const Text("Cancel"),
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                          ),
                                          TextButton(
                                            child: const Text("Remove"),
                                            onPressed: () {
                                              setState(() {
                                                cartData.remove(item);
                                                updateCart(item);
                                              });
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              },
                              child: Container(
                                width: 20,
                                height: 20,
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
                              margin: const EdgeInsets.symmetric(horizontal: 2),
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
                                width: 20,
                                height: 20,
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
              const SizedBox(width: 10),
              // Pricing Details
              Flexible(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        ' ${itemTotalPrice.toStringAsFixed(2)}₪',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis, // Handle long text
                        maxLines: 1, // Limit to 1 line
                      ),
                      const SizedBox(height: 4), // Add spacing between lines
                      Text(
                        ' ${unitPrice.toStringAsFixed(2)}₪',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis, // Handle long text
                        maxLines: 1, // Limit to 1 line
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void updateCart(Map<String, dynamic> updatedItem) async {
    setState(() {
      // Replace the updated item in the cartData list
      final index = cartData.indexWhere((item) =>
          (item['productId']?['_id'] == updatedItem['productId']?['_id']) ||
          (item['orderId'] ==
              updatedItem['orderId'])); // Adjust condition for special orders
      if (index != -1) {
        cartData[index] = updatedItem;
      }
    });

    try {
      if (token == null) return;
      // API endpoint for updating cart
      final url = Uri.parse(updateCartItem);

      // Prepare the payload
      final payload = {
        'productId': updatedItem['productId'] != null
            ? updatedItem['productId']['_id']
            : null,
        'quantity': updatedItem['quantity'],
        'selectedOptions': updatedItem['selectedOptions'],
      };

      // Make the API call
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        setState(() {
          fetchCartData();
          fetchSpecialOrders();
        });
        print('Cart updated successfully');
      } else {
        // Handle errors
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Failed to update cart';
        print('Error updating cart: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating cart: $errorMessage')),
        );
      }
    } catch (e) {
      print('An error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Widget _buildBottomCheckoutBar(String type) {
    double total =
        type == 'instant' ? calculateInstantTotal() : calculateScheduledTotal();

    // Fetch the relevant cart items
    List<Map<String, dynamic>> selectedItems =
        type == 'instant' ? getInstantItems() : getScheduledItems();

    // Filter out pending special orders
    List<Map<String, dynamic>> filteredItems = selectedItems.where((item) {
      if (item['isSpecialOrder'] == true) {
        return item['status'] == 'Confirmed';
      }
      return true; // Regular items are always included
    }).toList();

    // Calculate the total after filtering
    double filteredTotal = filteredItems.fold(
      0.0,
      (sum, item) => sum + (item['totalPriceWithQuantity'] ?? 0.0),
    );

    return Container(
      color: myColor.withOpacity(.8),
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${filteredTotal.toStringAsFixed(2)}₪',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          ElevatedButton(
            onPressed: filteredItems.isEmpty
                ? null // Disable button if no items to checkout
                : () {
                    // print('cartItems $filteredItems');
                    // Navigate to CheckoutPage with the selected cart items
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutPage(
                          type: type,
                          total: filteredTotal,
                          cartItems: filteredItems, // Pass filtered cart items
                        ),
                      ),
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
