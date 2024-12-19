import 'package:flutter/material.dart';
import 'package:craft_blend_project/configuration/config.dart';
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
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      setState(() {
        isUpdating = true;
      });

      final response = await http.put(
        Uri.parse('/orders/$orderId/updateStatus'),
        headers: {
          "Authorization": "Bearer yourToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"status": newStatus}),
      );

      if (response.statusCode == 200) {
        setState(() {
          order['status'] = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Order status updated to $newStatus")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update order status.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred.")),
      );
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    final items = order['items'] ?? [];
    print('this.order');

    //  print(this.order);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        toolbarHeight: appBarHeight,
        title: Text(
          "Order Details: #${order['orderNumber']}",
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
      final storeId = item['storeId'];

      // Handle case where storeId is just a String
      final storeName = storeId is Map
          ? storeId['storeName'] ?? 'Unknown Store'
          : 'Unknown Store';

      if (storeId == null) continue;

      if (!storeTotals.containsKey(storeId)) {
        storeTotals[storeId] = {
          'storeName': storeName,
          'storeTotal': 0.0,
          'storeDeliveryCost': 0.0,
        };
      }

      storeTotals[storeId]!['storeTotal'] += (item['storeTotal'] ?? 0.0);
      storeTotals[storeId]!['storeDeliveryCost'] +=
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
                  "Order #: ${order['orderNumber']}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 3),
            Text(
              "Status: ${order['status']}",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text("Total Price: \$${order['totalPrice']}"),
            const SizedBox(height: 5),
            const Divider(),
            const SizedBox(height: 5),
            const Text(
              "Delivery Information:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text("City: ${order['deliveryDetails']['city']}"),
            const SizedBox(height: 3),
            Text("Street: ${order['deliveryDetails']['street']}"),
            const SizedBox(height: 3),
            Text(
                "Contact Number: ${order['deliveryDetails']['contactNumber']}"),
            const SizedBox(height: 10),
            const Text(
              "Store Totals:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...storeTotals.entries.map((entry) {
              final storeName = entry.value['storeName'];
              final storeTotal = entry.value['storeTotal'] ?? 0.0;
              final storeDeliveryCost = entry.value['storeDeliveryCost'] ?? 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  "$storeName: Total \$${storeTotal.toStringAsFixed(2)}, Delivery Cost \$${storeDeliveryCost.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 14),
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
    final productName = product?['name'] ?? 'No Name';
    final productImage = product?['image'] ?? '';

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
    return Container(
      alignment: Alignment.center,
      child: ElevatedButton.icon(
        onPressed: isUpdating
            ? null
            : () => _showConfirmationDialog(order['orderId'], "Shipped"),
        icon: const Icon(
          Icons.local_shipping,
          color: Colors.white,
        ),
        label: isUpdating
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Mark as Shipped",
                style: TextStyle(color: Colors.white, fontSize: 16),
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

  /// Show confirmation dialog
  void _showConfirmationDialog(String orderId, String newStatus) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Confirm Shipment",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to mark this order as 'Shipped'?",
            style: TextStyle(fontSize: 16),
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
}
