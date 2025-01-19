import 'package:flutter/material.dart';
import 'package:craft_blend_project/configuration/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/Notifications/notification_helper.dart';

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
            // Order Summary
            _buildOrderSummary(),
            const SizedBox(height: 20),

            // Products Title
            const Text(
              "Products:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Products List
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    // Grid view for larger screens
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Number of columns
                        mainAxisSpacing: 16.0, // Vertical spacing
                        crossAxisSpacing: 16.0, // Horizontal spacing
                        childAspectRatio: 3 / 2, // Adjust card aspect ratio
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildProductCard(item);
                      },
                    );
                  } else {
                    // List view for smaller screens
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildProductCard(item);
                      },
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),

            // Status Button
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: MediaQuery.of(context).size.width *
                    0.8, // Responsive button
                child: _buildStatusButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String isoDateTime) {
    try {
      final dateTime = DateTime.parse(isoDateTime); // Parse the ISO date string
      return "${dateTime.toLocal()}"
          .split('.')[0]; // Format as local time without milliseconds
    } catch (e) {
      return "Invalid date"; // Fallback if parsing fails
    }
  }

  Widget _buildOrderSummary() {
    // Group items by store to calculate totals
    Map<String, Map<String, dynamic>> storeTotals = {};
    // Extract customer's first and last name
    final firstName = order['userId']['firstName'] ?? '';
    final lastName = order['userId']['lastName'] ?? '';
    final customerName = "$firstName $lastName".trim();

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
          (storeTotals[storeId]!['storeTotal'] ?? 0.0) +
              (item['storeTotal'] ?? 0.0);
      storeTotals[storeId]!['storeDeliveryCost'] =
          (item['storeDeliveryCost'] ?? 0.0);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Info Card
          Card(
            color: myColor2,
            elevation: 4,
            child: ListTile(
              leading: const Icon(
                Icons.account_circle,
                size: 40,
                color: myColor,
              ),
              title: Text(
                customerName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Text(
                    "Delivery Details:",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "City: ${order['deliveryDetails']['city'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Street: ${order['deliveryDetails']['street'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Contact: ${order['deliveryDetails']['contactNumber'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Payment Details:",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Method: ${order['paymentDetails']['method']}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (order['createdAt'] != null) const SizedBox(height: 5),
                  if (order['createdAt'] != null)
                    Text(
                      "Ordered at: ${_formatDateTime(order['createdAt'])}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  Divider(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Store Totals Section
          // Store Totals Section
          Card(
            color: myColor2,
            elevation: 4,
            child: ListTile(
              leading: const Icon(
                Icons.store,
                size: 40,
                color: myColor,
              ),
              title: const Text(
                "",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  ...storeTotals.entries.map((entry) {
                    final storeId = entry.key;
                    final totals = entry.value;
                    final storeTotal = totals['storeTotal'] ?? 0.0;
                    final deliveryCost = totals['storeDeliveryCost'] ?? 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total: ${storeTotal.toStringAsFixed(2)} ₪",
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Delivery Cost: ${deliveryCost.toStringAsFixed(2)} ₪",
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Status: ${order['status'] ?? 'Unknown'}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Divider(),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
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
      color: myColor2,
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
                    "Price: ${unitPrice.toStringAsFixed(2)} ₪",
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    "Total: ${itemTotalPrice.toStringAsFixed(2)} ₪",
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
    // Determine the button label and action based on the store's current status
    String buttonLabel = "Unknown";
    String nextStatus = "";
    String storeStatus = "Unknown";

    if (order['items'] != null && order['items'].isNotEmpty) {
      storeStatus = order['items'][0]['storeStatus'] ?? "Unknown";
      print('storeStatus in _buildStatusButton');
      print(storeStatus);
    }

    if (storeStatus == "Pending") {
      buttonLabel = "Mark as Shipped";
      nextStatus = "Shipped";
    } else if (storeStatus == "Shipped") {
      buttonLabel = "Mark as Delivered";
      nextStatus = "Delivered";
    } else {
      return const SizedBox.shrink(); // No button needed for other statuses
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

  Future<void> sendOrderStatusNotification(
      dynamic updatedOrder, String newStatus) async {
    try {
      print('updatedOrder in sendOrderStatusNotification $updatedOrder');

      // Step 1: Fetch the token from SharedPreferences
      final token = await _fetchToken();
      if (token == null) return;

      final prefs = await SharedPreferences.getInstance();
      final storeName = prefs.getString('storeName');

      // Step 2: Fetch the user's FCM token from the backend
      final userId = updatedOrder['userId'];
      final storeId =
          updatedOrder['items']?[0]['storeId']; // Access from items array
      print('Extracted User ID: $userId, Store ID: $storeId');

      if (userId == null || storeId == null || storeName == null) {
        print('User ID, Store ID, or Store Name not found');
        return;
      }

      final fcmTokenUrl =
          '$getFMCToken?userId=$userId'; // API to fetch FCM token
      final fcmTokenResponse = await http.get(
        Uri.parse(fcmTokenUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (fcmTokenResponse.statusCode != 200) {
        print('Failed to fetch FCM token: ${fcmTokenResponse.body}');
        return;
      }

      final fcmTokenData = json.decode(fcmTokenResponse.body);
      if (fcmTokenData['tokens'] == null || fcmTokenData['tokens'].isEmpty) {
        print('No FCM token found for the user');
        return;
      }

      final userDeviceToken = fcmTokenData['tokens'][0]['fcmToken'];
      print('User Device Token: $userDeviceToken');

      // Step 3: Send notification to the user's device using Firebase
      final title = "Your order from '$storeName' is now $newStatus";
      final body =
          "Thank you for shopping with us! Your order status has been updated to $newStatus.";
      await NotificationService.sendNotification(userDeviceToken, title, body);

      // Step 4: Add notification to the database
      final notificationResponse = await http.post(
        Uri.parse(addNotification),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'senderId': storeId, // Store ID as required by backend
          'senderType': 'store',
          'recipientId': userId,
          'recipientType': 'user',
          'title': title,
          'message': body,
          'metadata': {'orderId': updatedOrder['_id'], 'status': newStatus},
        }),
      );

      if (notificationResponse.statusCode == 200) {
        print('Notification added to database successfully');
      } else {
        print(
            'Failed to save notification to database: ${notificationResponse.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      setState(() {
        isUpdating = true;
      });

      final token = await _fetchToken();
      if (token == null) return;

      final url = '$updateOrderItemsStatusUrl/$orderId';
      print('Final URL: $url');

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"newStatus": newStatus}),
      );

      if (response.statusCode == 200) {
        // Update the order status in the UI
        final updatedOrder = json.decode(response.body)['order'];
        setState(() {
          order = updatedOrder; // Refresh the current order details
        });
        // Send a notification to the user
        await sendOrderStatusNotification(updatedOrder, newStatus);

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
