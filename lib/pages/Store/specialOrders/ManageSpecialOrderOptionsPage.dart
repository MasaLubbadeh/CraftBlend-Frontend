// lib/pages/special_orders/manage_special_order_options_page.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../configuration/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/custom__field.dart';
import '../../../models/order_option.dart';
import 'EditOrderOptionPage.dart';
import '../../../models/field_option.dart';

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

  Future<void> _fetchOrderOptions() async {
    // Fetch existing order options from the backend
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('/////////{Config.apiBaseUrl}/getSpecialOrderOptions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        orderOptions = data.map((item) => OrderOption.fromMap(item)).toList();
        isLoading = false;
      });
    } else {
      // Handle error
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch order options.")),
      );
    }
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

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

  void _deleteOrderOption(int index) {
    // Optionally, confirm deletion
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
            onPressed: () {
              setState(() {
                orderOptions.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAllConfigurations() async {
    // Serialize the orderOptions and send to backend
    List<Map<String, dynamic>> configurations = orderOptions.map((option) {
      return option.toMap();
    }).toList();

    // Prepare the payload
    Map<String, dynamic> payload = {
      'specialOrderOptions': configurations,
    };

    // Send the payload to the backend (replace with your API endpoint)
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('///////{Config.apiBaseUrl}/saveSpecialOrderConfigurations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Configurations saved successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save configurations.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Special Order Options'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveAllConfigurations,
              tooltip: 'Save All Configurations',
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: orderOptions.length,
                itemBuilder: (context, index) {
                  final option = orderOptions[index];
                  return ListTile(
                    title: Text(
                      option.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: option.customFields.isNotEmpty
                        ? Text(
                            option.customFields.map((e) => e.label).join(', '),
                            style: const TextStyle(fontSize: 14),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editOrderOption(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteOrderOption(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNewOrderOption,
          child: const Icon(Icons.add),
          tooltip: 'Add New Order Option',
        ));
  }
}
