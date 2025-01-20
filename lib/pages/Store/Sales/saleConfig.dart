import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../configuration/config.dart';

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

    await saveSaleToDatabase(
      productIds: widget.selectedProductIds,
      saleAmount: amountController.text,
      startDate: startDateController.text,
      endDate: endDateController.text,
      sendPushNotification: sendPushNotification,
      notificationContent: notificationContentController.text,
    );

    Navigator.pop(context);
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
      ),
    );
  }
}
