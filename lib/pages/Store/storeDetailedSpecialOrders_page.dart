import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../services/Notifications/notification_helper.dart';

class DetailedSpecialOrderPage extends StatefulWidget {
  final Map<String, dynamic> specialOrder;

  const DetailedSpecialOrderPage({Key? key, required this.specialOrder})
      : super(key: key);

  @override
  _DetailedSpecialOrderPageState createState() =>
      _DetailedSpecialOrderPageState();
}

class _DetailedSpecialOrderPageState extends State<DetailedSpecialOrderPage> {
  bool _isLoading = false;

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs
        .getString('token'); // Adjust the key based on your implementation
  }

  Future<void> sendSpecialOrderStatusNotification(
      Map<String, dynamic> specialOrder, String newStatus) async {
    try {
      // Step 1: Fetch the token from SharedPreferences
      final token = await _getToken();
      if (token == null) {
        print('Authentication token not found');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final storeName = prefs.getString('storeName');

      if (storeName == null) {
        print('Store Name not found');
        return;
      }

      // Step 2: Extract user ID and store ID
      final userId = specialOrder['customerId']?['_id'];
      final storeId =
          specialOrder['storeId']; // Adjust based on your data structure

      print('User of special orders: $userId');

      if (userId == null || storeId == null) {
        print('User ID or Store ID not found');
        return;
      }

      // Step 3: Fetch the user's FCM token from the backend
      final fcmTokenUrl =
          '$getFMCToken?userId=$userId'; // Ensure your API expects userId as a path parameter
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

      // Step 4: Send notification to the user's device using Firebase
      final title = "Your special order from '$storeName' has been confirmed!";
      final body =
          "Your special request from '$storeName' was confirmed and the total price is now set. You can proceed to checkout from your 'scheduled orders' section in your cart.";
      await NotificationService.sendNotification(userDeviceToken, title, body);

      // Step 5: Add notification to the database
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
          'metadata': {'orderId': specialOrder['_id'], 'status': newStatus},
        }),
      );

      if (notificationResponse.statusCode >= 200 &&
          notificationResponse.statusCode < 300) {
        print('Notification added to database successfully');
      } else {
        print(
            'Failed to save notification to database: ${notificationResponse.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Widget _buildStatusButton() {
    String currentStatus = widget.specialOrder['status'] ?? 'Unknown';

    String buttonLabel;
    VoidCallback? onPressed;

    switch (currentStatus) {
      case 'Pending':
        buttonLabel = "Confirm Order & Set Price";
        onPressed = _confirmOrder;
        break;
      case 'Confirmed':
        buttonLabel = "Mark as Shipped";
        onPressed = _confirmOrder;
        break;
      case 'Shipped':
        buttonLabel = "Mark as Delivered";
        onPressed = _confirmOrder;
        break;
      case 'Delivered':
        return SizedBox.shrink(); // No button needed
      default:
        return SizedBox.shrink(); // Handle unknown statuses
    }

    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: _isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.0,
              ),
            )
          : Icon(Icons.check_circle, color: Colors.white),
      label: _isLoading
          ? SizedBox.shrink()
          : Text(
              buttonLabel,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
      style: ElevatedButton.styleFrom(
        backgroundColor: myColor,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    );
  }

  Future<void> _confirmOrder() async {
    String? realPrice = await _showRealPriceDialog();

    if (realPrice == null || realPrice.isEmpty) {
      return; // User canceled or didn't enter a price
    }

    double? parsedPrice = double.tryParse(realPrice);
    if (parsedPrice == null || parsedPrice <= 0) {
      _showErrorDialog("Please enter a valid price.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? token = await _getToken();
      // Replace with actual token logic
      final response = await http.put(
        Uri.parse('${updateSpecialOrderStatus}/${widget.specialOrder['_id']}'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "status": "Confirmed",
          "realPrice": parsedPrice,
        }),
      );

      if (response.statusCode == 200) {
        //  final responseData = json.decode(response.body);
        // final updatedSpecialOrder =
        //   responseData['specialOrder']; // Adjust based on your API response

        // Send notification
        await sendSpecialOrderStatusNotification(
            widget.specialOrder, 'Confirmed');

        // Update the local special order
        setState(() {
          widget.specialOrder['status'] = 'Confirmed';
          widget.specialOrder['realPrice'] = parsedPrice;
        });

        // Show success dialog
        _showSuccessDialog(
            "Order confirmed successfully! and user has notified!");

        // Navigate back and signal the previous page to refresh
        Navigator.pop(context, true);
      } else {
        _showErrorDialog('Failed to confirm order.');
      }
    } catch (error) {
      _showErrorDialog('An error occurred: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _showRealPriceDialog() async {
    TextEditingController _priceController = TextEditingController();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true, // 1. Enable scroll control
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(context).viewInsets.bottom, // 2. Adjust padding
            left: 16.0,
            right: 16.0,
            top: 16.0,
          ),
          child: SingleChildScrollView(
            // 3. Wrap with SingleChildScrollView
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set Real Price',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'Enter the real price',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: myColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: myColor, width: 2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(_priceController.text.trim());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: myColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 24.0),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 24.0),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 50, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: myColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 24.0),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(String isoDateTime) {
    try {
      // print('speciaaal');
      // print(widget.specialOrder);
      final dateTime = DateTime.parse(isoDateTime); // Parse the ISO date string
      return "${dateTime.toLocal()}"
          .split('.')[0]; // Format as local time without milliseconds
    } catch (e) {
      return "Invalid date"; // Fallback if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    final customer = widget.specialOrder['customerId'] ?? {};
    final firstName = customer['firstName'] ?? 'N/A';
    final lastName = customer['lastName'] ?? 'N/A';
    final userName = "$firstName $lastName";

    final orderItems =
        widget.specialOrder['orderItems'] as List<dynamic>? ?? [];
    final totalPrice = widget.specialOrder['estimatedPrice'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: Text(
          "Order for $userName",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Opacity(
            opacity: 0.1,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/searchBackground.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Info
                      Card(
                        elevation: 4,
                        child: ListTile(
                          leading: const Icon(
                            Icons.account_circle,
                            size: 40,
                            color: myColor,
                          ),
                          title: Text(
                            userName, // Assuming userName is available in scope
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(),
                              Text("Estimated Price: $totalPrice ₪"),
                              const SizedBox(height: 5),
                              Text(
                                "Delivery Details:",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "City: ${widget.specialOrder['deliveryDetails']?['city'] ?? 'Not yet'}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                "Street: ${widget.specialOrder['deliveryDetails']?['street'] ?? 'Not yet'}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                "Contact: ${widget.specialOrder['deliveryDetails']?['contactNumber'] ?? 'Not yet'}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Payment Details:",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Method: ${widget.specialOrder['paymentDetails']?['method'] ?? 'Not yet'}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (widget.specialOrder['createdAt'] != null)
                                Text(
                                  "Ordered at: ${_formatDateTime(widget.specialOrder['createdAt'])}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Order Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      // Order Items
                      ...orderItems.map((item) {
                        final name = item['optionName'] ?? 'N/A';
                        final selectedFields =
                            item['selectedCustomFields'] as List<dynamic>? ??
                                [];
                        final photoUrl = item['photoUrl'];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Option Name
                                Row(
                                  children: [
                                    const Icon(Icons.shopping_bag,
                                        size: 20, color: myColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                // Selected Fields
                                ...selectedFields.map((field) {
                                  final label = field['label'] ?? 'N/A';
                                  final value = field['value'] ?? 'N/A';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_box_outlined,
                                            size: 16, color: Colors.black54),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "$label: $value",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                // Photo
                                if (photoUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        photoUrl,
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildStatusButton(),
/* ElevatedButton.icon(
          onPressed: _confirmOrder,
          icon: const Icon(Icons.check_circle, color: Colors.white70),
          label: const Text(
            "Confirm Order & Set Price",
            style: TextStyle(color: Colors.white70),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: myColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      */
      ),
    );
  }
}
