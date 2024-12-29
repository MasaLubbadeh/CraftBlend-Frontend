import 'package:flutter/material.dart';
import 'package:craft_blend_project/configuration/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderDetailsPage extends StatefulWidget {
  final dynamic order;

  const OrderDetailsPage({Key? key, required this.order}) : super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late dynamic order;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    order = widget.order;
    print("Received order id: ${order['orderId']}"); // Debug print
  }

  Future<String?> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    final items = order['items'] ?? [];
    print('items');

    print(items);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        toolbarHeight: appBarHeight,
        title: Text(
          "Order Details: #${order['userOrderNumber']}",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(),
            const SizedBox(height: 20),
            const Text(
              "Products:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildProductCard(item);
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildStatusButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    // Group items by store to calculate totals
    Map<String, Map<String, dynamic>> storeTotals = {};

    for (var item in order['items'] ?? []) {
      final storeId = item['storeId']?.toString(); // Ensure storeId is a String

      if (storeId == null) continue;

      if (!storeTotals.containsKey(storeId)) {
        storeTotals[storeId] = {
          'storeTotal': 0.0,
          'storeDeliveryCost': 0.0,
        };
      }

      storeTotals[storeId]!['storeTotal'] =
          storeTotals[storeId]!['storeTotal'] ??
              0.0 + (item['storeTotal'] ?? 0.0);
      storeTotals[storeId]!['storeDeliveryCost'] =
          (item['storeDeliveryCost'] ?? 0.0);
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_basket, color: myColor),
                const SizedBox(width: 10),
                Text(
                  "Order #: ${order['userOrderNumber'] ?? 'N/A'}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              "Status: ${order['status'] ?? 'Unknown'}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Delivery Details:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text("City: ${order['deliveryDetails']['city']}"),
            Text("Street: ${order['deliveryDetails']['street']}"),
            Text("Contact: ${order['deliveryDetails']['contactNumber']}"),
            const SizedBox(height: 10),
            Text(
              "Total Price: \$${order['totalPrice']?.toStringAsFixed(2) ?? '0.00'}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              "Store Totals:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            ...storeTotals.entries.map((entry) {
              // Parse `entry.key` directly if it is a string
              Map<String, dynamic> storeKey;
              if (entry.key is String) {
                try {
                  storeKey = jsonDecode(entry.key) as Map<String, dynamic>;
                } catch (e) {
                  // Handle invalid format gracefully
                  print("Error decoding key: $e");
                  return SizedBox(); // Return an empty widget if parsing fails
                }
              } else {
                storeKey = entry.key as Map<String, dynamic>;
              }

              final storeId = storeKey['_id'] ?? 'Unknown ID';
              final storeName = storeKey['storeName'] ?? 'Unknown Store';
              final storeLogo = storeKey['logo'] ?? '';

              final totals = entry.value;
              final storeTotal = totals['storeTotal'] ?? 0.0;
              final deliveryCost = totals['storeDeliveryCost'] ?? 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store Logo
                    if (storeLogo.isNotEmpty)
                      CircleAvatar(
                        backgroundImage: NetworkImage(storeLogo),
                        radius: 20,
                      )
                    else
                      const CircleAvatar(
                        child: Icon(Icons.store, color: myColor),
                        radius: 20,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Total: \$${storeTotal.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            "Delivery Cost: \$${deliveryCost.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic item) {
    final product = item['productId'];

    // Check for valid product structure
    final productName = (product is Map && product.containsKey('name'))
        ? product['name']
        : 'No Name';
    final productImage = (product is Map && product.containsKey('image'))
        ? product['image']
        : '';

    final unitPrice = item['pricePerUnitWithOptionsCost'] ?? 0;
    final itemTotalPrice = item['totalPriceWithQuantity'] ?? 0;
    final selectedOptions = item['selectedOptions'] ?? {};

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: myColor.withOpacity(0.2),
                image: productImage.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(productImage),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: productImage.isEmpty
                  ? const Icon(
                      Icons.shopping_basket,
                      size: 40,
                      color: myColor,
                    )
                  : null,
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Quantity: ${item['quantity']}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    "Price: \$${unitPrice.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    "Total: \$${itemTotalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton() {
    // Determine the button label and action based on the order's current status
    String buttonLabel;
    String nextStatus;

    if (order['status'] == "Pending") {
      buttonLabel = "Mark as Shipped";
      nextStatus = "Shipped";
    } else if (order['status'] == "Shipped") {
      buttonLabel = "Mark as Delivered";
      nextStatus = "Delivered";
    } else {
      // If the status is Delivered, no button is needed
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      child: ElevatedButton.icon(
        onPressed: isUpdating
            ? null
            : () => _showConfirmationDialog(order['orderId'], nextStatus),
        icon: const Icon(
          Icons.local_shipping,
          color: Colors.white,
        ),
        label: isUpdating
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                buttonLabel,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: myColor,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog(String orderId, String newStatus) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Confirm $newStatus",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to mark this order as '$newStatus'?",
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                updateOrderStatus(orderId, newStatus); // Update the status
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: myColor,
              ),
              child: const Text(
                "Confirm",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      setState(() {
        isUpdating = true;
      });

      final token = await _fetchToken();
      if (token == null) return;

      final url = '$updateOrderStatusUrl/$orderId/updateStatus';
      print('Final URL: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"status": newStatus}),
      );

      if (response.statusCode == 200) {
        // Update the order status in the UI
        final updatedOrder = json.decode(response.body)['order'];
        setState(() {
          order = updatedOrder; // Refresh the current order details
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Order status updated to $newStatus")),
        );

        // Notify the previous page to refresh its data
        Navigator.pop(context, true); // Signal the previous page to refresh
      } else {
        final responseData = json.decode(response.body);
        throw Exception(
            responseData['message'] ?? 'Failed to update order status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }
}
