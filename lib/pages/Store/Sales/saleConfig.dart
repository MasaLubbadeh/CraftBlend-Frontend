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
  String? selectedSaleType;
  final saleTypes = ['Percentage Discount', 'BOGO', 'Flat Discount'];
  final TextEditingController amountController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  bool sendPushNotification = false;

  Future<void> saveSaleToDatabase({
    required List<String> productIds,
    required String saleType,
    required String saleAmount,
    required String startDate,
    required String endDate,
    required bool sendPushNotification,
  }) async {
    const String apiUrl = createSale;

    final Map<String, dynamic> saleData = {
      'productIds': productIds,
      'saleType': saleType,
      'saleAmount': saleAmount,
      'startDate': startDate,
      'endDate': endDate,
      'sendPushNotification': sendPushNotification,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(saleData),
      );

      if (response.statusCode == 201) {
        print('Sale saved successfully: ${response.body}');
        // If sale is saved successfully, update the products
        /*   await updateProductsBatch(
          productIds
              .map((id) => {
                    'id': id,
                    'onSale': true,
                    'salePrice':
                        saleAmount, // Assuming saleAmount is the sale price
                  })
              .toList(),
        );*/
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sale created successfully!')),
        );
        Navigator.pop(context);
      } else {
        print('Failed to save sale: ${response.statusCode} ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create sale: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error saving sale: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void submitSale() async {
    if (selectedSaleType == null ||
        amountController.text.isEmpty ||
        startDateController.text.isEmpty ||
        endDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // Show loading indicator while saving the sale
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    await saveSaleToDatabase(
      productIds: widget.selectedProductIds,
      saleType: selectedSaleType!,
      saleAmount: amountController.text,
      startDate: startDateController.text,
      endDate: endDateController.text,
      sendPushNotification: sendPushNotification,
    );

    Navigator.pop(context); // Dismiss loading dialog
  }

//Function to send the batch update request
  Future<Map<String, dynamic>> updateProductsBatch(
      List<Map<String, dynamic>> productUpdates) async {
    try {
      // Make the HTTP POST request
      final response = await http.post(
        Uri.parse(saleUpdate), // Replace with your sale update URL
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'productUpdates': productUpdates}),
      );

      // Check if the response status is OK
      if (response.statusCode == 200) {
        return json.decode(response.body); // Return the response body
      } else {
        throw Exception(
            'Failed to update products: ${response.statusCode}${response.body}');
      }
    } catch (error) {
      throw Exception('Error updating products: $error');
    }
  }

  Future<void> selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create a New Sale',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Sale Type',
                  border: OutlineInputBorder(),
                ),
                items: saleTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedSaleType = value),
                value: selectedSaleType,
              ),
              SizedBox(height: 15),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Sale Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 15),
              TextField(
                controller: startDateController,
                decoration: InputDecoration(
                  labelText: 'Start Date',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => selectDate(context, startDateController),
                  ),
                ),
                readOnly: true,
              ),
              SizedBox(height: 15),
              TextField(
                controller: endDateController,
                decoration: InputDecoration(
                  labelText: 'End Date',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => selectDate(context, endDateController),
                  ),
                ),
                readOnly: true,
              ),
              SizedBox(height: 15),
              SwitchListTile(
                title: Text('Send Push Notification'),
                value: sendPushNotification,
                onChanged: (value) =>
                    setState(() => sendPushNotification = value),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: submitSale,
                icon: Icon(Icons.check),
                label: Text('Submit Sale'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
