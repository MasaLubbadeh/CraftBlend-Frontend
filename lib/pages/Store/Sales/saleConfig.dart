import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../configuration/config.dart';
import '../../../services/Notifications/notification_helper.dart';

class SaleConfigurationPage extends StatefulWidget {
  final List<String> selectedProductIds;

  SaleConfigurationPage({required this.selectedProductIds});

  @override
  _SaleConfigurationPageState createState() => _SaleConfigurationPageState();
}

class _SaleConfigurationPageState extends State<SaleConfigurationPage> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController notificationContentController =
      TextEditingController();
  bool sendPushNotification = false;

  Future<void> saveSaleToDatabase({
    required List<String> productIds,
    required String saleAmount,
    required String startDate,
    required String endDate,
    required bool sendPushNotification,
    required String notificationContent,
  }) async {
    const String apiUrl = createSale;

    final saleData = {
      'productIds': productIds,
      'saleAmount': saleAmount,
      'startDate': startDate,
      'endDate': endDate,
      'sendPushNotification': sendPushNotification,
      'notificationContent': notificationContent,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(saleData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sale created successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create sale: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void submitSale() async {
    if (amountController.text.isEmpty ||
        startDateController.text.isEmpty ||
        endDateController.text.isEmpty ||
        (sendPushNotification && notificationContentController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // Save sale details to the database
      await saveSaleToDatabase(
        productIds: widget.selectedProductIds,
        saleAmount: amountController.text,
        startDate: startDateController.text,
        endDate: endDateController.text,
        sendPushNotification: sendPushNotification,
        notificationContent: notificationContentController.text,
      );

      // Send push notifications if enabled
      /* if (sendPushNotification) {
        // Replace with your API endpoint to get device tokens
        const String apiUrl = getAllFMCTokens;
        final prefs = await SharedPreferences.getInstance();
        final String? token =
            prefs.getString('token'); // Retrieve the stored token

        final response = await http.get(Uri.parse(apiUrl), headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Replace with actual token
        });
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print('jsonResponse:$jsonResponse');
        if (response.statusCode == 200) {
          print(response.body);
          List<String> deviceTokens = List<String>.from(jsonResponse['tokens']);

          //List<String> tokens = jsonDecode(response.body);
          print('tokens retrieved:$deviceTokens');
          await NotificationService.sendNotificationToAllUsers(
            deviceTokens,
            'New Sale Available!',
            notificationContentController.text,
          );
        } else {
          throw Exception('Failed to fetch device tokens: ${response.body}');
        }
      }*/

      Navigator.pop(context); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sale created and notifications sent!')),
      );
    } catch (e) {
      print('Error: $e');

      Navigator.pop(context); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> selectDate(
      BuildContext context, TextEditingController controller) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        controller.text = pickedDate.toIso8601String().split('T').first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'S A L E S',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: const Color.fromARGB(255, 233, 227, 236),
              child: const Text(
                'Enter your Sale details,Sale amount is in % (if you entered 25 a 25% is applied to products),also choose the the duration of your sale.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Create a New Sale',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: myColor,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: amountController,
                        decoration: InputDecoration(
                          labelText: 'Sale Amount',
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: myColor),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: startDateController,
                        decoration: InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: myColor),
                          ),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => selectDate(context, startDateController),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: endDateController,
                        decoration: InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: myColor),
                          ),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => selectDate(context, endDateController),
                      ),
                      SizedBox(height: 15),
                      SwitchListTile(
                        title: Text(
                          'Send Push Notification',
                          style: TextStyle(fontSize: 15),
                        ),
                        value: sendPushNotification,
                        onChanged: (value) =>
                            setState(() => sendPushNotification = value),
                      ),
                      Text(
                        'Note: The notification will be sent to all users',
                        style: TextStyle(fontSize: 15),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      if (sendPushNotification) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Notification Content:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        TextField(
                          controller: notificationContentController,
                          decoration: InputDecoration(
                            hintText: 'Enter notification content here...',
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: myColor),
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submitSale,
                          child: Text('Submit'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: myColor,
                            textStyle: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
