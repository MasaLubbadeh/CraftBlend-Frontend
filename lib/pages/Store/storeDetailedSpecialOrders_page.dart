import 'package:flutter/material.dart';
import 'package:craft_blend_project/configuration/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      final String token = await _getToken();

      final response = await http.put(
        Uri.parse('apiBaseUrl/updateStatus/${widget.specialOrder['_id']}'),
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
        final jsonData = json.decode(response.body);
        if (jsonData['success']) {
          _showSuccessDialog("Order confirmed successfully!");
        } else {
          _showErrorDialog(jsonData['message'] ?? 'Failed to confirm order.');
        }
      } else {
        _showErrorDialog('Failed to confirm order. Please try again.');
      }
    } catch (error) {
      _showErrorDialog('An error occurred: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getToken() async {
    return 'your_auth_token'; // Replace with actual token logic
  }

  Future<String?> _showRealPriceDialog() {
    TextEditingController _priceController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Set Real Price',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _priceController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Enter the real price',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(_priceController.text.trim());
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Error',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Success',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(true); // Return to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.specialOrder['customerId'] ?? {};
    final firstName = customer['firstName'] ?? 'N/A';
    final lastName = customer['lastName'] ?? 'N/A';
    final userName = "$firstName $lastName";

    final orderItems =
        widget.specialOrder['orderItems'] as List<dynamic>? ?? [];
    final totalPrice = widget.specialOrder['totalPrice'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Order for $userName",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: myColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              // Navigate to chat page if implemented
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    subtitle: Text("Total Price: $totalPrice ₪"),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "User Responses:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: orderItems.length,
                      itemBuilder: (context, index) {
                        final item = orderItems[index];
                        final option = item['optionId'] ?? {};
                        final name = option['name'] ?? 'N/A';
                        final selectedFields =
                            item['selectedCustomFields'] as List<dynamic>? ??
                                [];
                        final photoUrl = item['photoUrl'];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...selectedFields.map((field) {
                                  final fieldName = field['fieldId'];
                                  final value = field['customValue'] ??
                                      (field['selectedOptions'] ?? [])
                                          .join(', ');
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      "$fieldName: $value",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                /*  if (photoUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Image.network(
                                      photoUrl,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                              */
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _confirmOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: myColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text(
            "Confirm Order & Set Price",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
