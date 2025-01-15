// lib/pages/special_orders/manage_special_order_options_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../configuration/config.dart';
import '../../../models/custom__field.dart';
import '../../../models/order_option.dart';
import 'EditOrderOptionPage.dart';
import '../../../models/field_option.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageSpecialOrderOptionsPage extends StatefulWidget {
  const ManageSpecialOrderOptionsPage({Key? key}) : super(key: key);

  @override
  _ManageSpecialOrderOptionsPageState createState() =>
      _ManageSpecialOrderOptionsPageState();
}

class _ManageSpecialOrderOptionsPageState
    extends State<ManageSpecialOrderOptionsPage> {
  List<OrderOption> orderOptions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrderOptions();
  }

  // Fetch existing order options from the backend
  Future<void> _fetchOrderOptions() async {
    try {
      final token = await _getToken();
      if (token == null) {
        _showSnackBar("Authentication token not found.");
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(getStoreSpecialOrderOptions),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          orderOptions = data.map((item) => OrderOption.fromMap(item)).toList();
          isLoading = false;
        });
      } else {
        // Handle server error
        _showSnackBar("Failed to fetch order options.");
        setState(() {
          isLoading = false;
        });
      }
    } on http.ClientException catch (e) {
      _showSnackBar("Client error: ${e.message}");
      setState(() {
        isLoading = false;
      });
    } on TimeoutException {
      _showSnackBar("Request timed out. Please try again.");
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      _showSnackBar("An unexpected error occurred: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Retrieve the authentication token
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Navigate to the Edit Order Option Page for adding a new option
  void _addNewOrderOption() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditOrderOptionPage(
          onSave: (newOption) {
            setState(() {
              orderOptions.add(newOption);
            });
          },
        ),
      ),
    );
  }

  // Navigate to the Edit Order Option Page for editing an existing option
  void _editOrderOption(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditOrderOptionPage(
          orderOption: orderOptions[index],
          onSave: (updatedOption) {
            setState(() {
              orderOptions[index] = updatedOption;
            });
          },
        ),
      ),
    );
  }

  // Confirm and delete an order option
  void _deleteOrderOption(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Option'),
        content: const Text(
            'Are you sure you want to delete this special order option?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close the confirmation dialog
              await _confirmDeletion(index);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Handle the deletion process with backend integration
  Future<void> _confirmDeletion(int index) async {
    try {
      final token = await _getToken();
      if (token == null) {
        _showSnackBar("Authentication token not found.");
        return;
      }

      // Show a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await http.delete(
        Uri.parse(
            '{Config.apiBaseUrl}/deleteSpecialOrderOption/${orderOptions[index]}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      // Dismiss the loading indicator
      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200) {
        setState(() {
          orderOptions.removeAt(index);
        });
        _showSnackBar("Order option deleted successfully.");
      } else {
        _showSnackBar("Failed to delete the order option.");
      }
    } on http.ClientException catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
      _showSnackBar("Client error: ${e.message}");
    } on TimeoutException {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
      _showSnackBar("Request timed out. Please try again.");
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
      _showSnackBar("An unexpected error occurred: $e");
    }
  }

  // Save all configurations to the backend
  Future<void> _saveAllConfigurations() async {
    try {
      final token = await _getToken();
      if (token == null) {
        _showSnackBar("Authentication token not found.");
        return;
      }

      // Show a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Serialize the orderOptions and send to backend
      List<Map<String, dynamic>> configurations =
          orderOptions.map((option) => option.toMap()).toList();

      // Prepare the payload
      Map<String, dynamic> payload = {
        'specialOrderOptions': configurations,
      };

      // Send the payload to the backend (replace with your API endpoint)
      final response = await http
          .post(
            Uri.parse(createStoreSpecialOrderOption),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 10));

      // Dismiss the loading indicator
      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200) {
        _showSnackBar("Configurations saved successfully!");
      } else {
        _showSnackBar("Failed to save configurations.");
      }
    } on http.ClientException catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
      _showSnackBar("Client error: ${e.message}");
    } on TimeoutException {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
      _showSnackBar("Request timed out. Please try again.");
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
      _showSnackBar("An unexpected error occurred: $e");
    }
  }

  // Helper method to show SnackBars
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtain screen dimensions for responsive design
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Determine padding based on screen size
    final double horizontalPadding = screenWidth * 0.05; // 5% of screen width
    final double verticalPadding = screenHeight * 0.02; // 2% of screen height

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        title: const Text(
          'Manage Special Order Options',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveAllConfigurations,
            tooltip: 'Save All Configurations',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: orderOptions.isEmpty
                  ? Center(
                      child: Text(
                        'No special order options available.',
                        style: TextStyle(
                          fontSize: screenWidth * 0.05, // 5% of screen width
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: orderOptions.length,
                      itemBuilder: (context, index) {
                        final option = orderOptions[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            title: Text(
                              option.name,
                              style: TextStyle(
                                fontSize:
                                    screenWidth * 0.05, // 5% of screen width
                                fontWeight: FontWeight.bold,
                                color: myColor,
                              ),
                            ),
                            subtitle: option.customFields.isNotEmpty
                                ? Text(
                                    option.customFields
                                        .map((e) => e.label)
                                        .join(', '),
                                    style: TextStyle(
                                      fontSize: screenWidth *
                                          0.04, // 4% of screen width
                                      color: Colors.black54,
                                    ),
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () => _editOrderOption(index),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteOrderOption(index),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewOrderOption,
        backgroundColor: myColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add New Order Option',
      ),
    );
  }
}
