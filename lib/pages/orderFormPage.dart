// lib/pages/order_form_page.dart
/*
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../configuration/config.dart';
import '../../../models/order_option.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/datePicker.dart';
import '../models/custom__field.dart';
import '../models/field_option.dart';
import 'Store/specialOrders/EditCustomFieldPage.dart';

class OrderFormPage extends StatefulWidget {
  final String category;

  const OrderFormPage({Key? key, required this.category}) : super(key: key);

  @override
  _OrderFormPageState createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  List<OrderOption> orderOptions = [];
  bool isLoading = true;

  // Map to hold selected options and their values
  Map<String, dynamic> selectedOptions = {};

  @override
  void initState() {
    super.initState();
    _fetchSpecialOrderConfigurations();
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchSpecialOrderConfigurations() async {
    try {
      final token = await _getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication token not found.")),
        );
        return;
      }

      final response = await http.get(
        Uri.parse(
            '{Config.apiBaseUrl}/getSpecialOrderOptions?category=${Uri.encodeComponent(widget.category)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          orderOptions = data.map((item) => OrderOption.fromMap(item)).toList();
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Failed to fetch configurations: ${response.reasonPhrase}")),
        );
      }
    } on http.ClientException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Client error: ${e.message}")),
      );
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request timed out. Please try again.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred: $e")),
      );
    }
  }

  // Function to calculate total price
  double _calculateTotalPrice() {
    double basePrice = 100.0; // Example base price
    double totalExtraCost = 0.0;

    for (var option in orderOptions) {
      if (option.isSelected) {
        for (var field in option.customFields) {
          switch (field.type) {
            case FieldType.dropdown:
              String? selectedValue = selectedOptions[field.id];
              if (selectedValue != null) {
                FieldOption? selectedOption = field.options?.firstWhere(
                  (opt) => opt.value == selectedValue,
                  orElse: () =>
                      FieldOption(value: selectedValue, extraCost: 0.0),
                );
                if (selectedOption != null) {
                  totalExtraCost += selectedOption.extraCost;
                }
              }
              break;
            case FieldType.checkbox:
              List<String>? selectedValues = selectedOptions[field.id];
              if (selectedValues != null) {
                for (var val in selectedValues) {
                  FieldOption? selectedOption = field.options?.firstWhere(
                    (opt) => opt.value == val,
                    orElse: () => FieldOption(value: val, extraCost: 0.0),
                  );
                  if (selectedOption != null) {
                    totalExtraCost += selectedOption.extraCost;
                  }
                }
              }
              break;
            case FieldType.text:
            case FieldType.number:
            case FieldType.imageUpload:
            case FieldType.date:
              // Handle other field types if they affect pricing
              break;
          }
        }

        // Add field-level extra cost if applicable
        if (option.requiresPhotoUpload && option.photoUploadPrompt.isNotEmpty) {
          // Example: Add a fixed cost for photo uploads
          totalExtraCost += 10.0; // Example cost
        }
      }
    }

    return basePrice + totalExtraCost;
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue, // Replace with your desired color
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'Order Form',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: orderOptions.length,
                      itemBuilder: (context, index) {
                        final option = orderOptions[index];
                        return Column(
                          children: [
                            // Option Card with Checkbox
                            Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 15),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.asset(
                                      'assets/images/${option.name.toLowerCase().replaceAll(' ', '_')}.png',
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (BuildContext context,
                                          Object exception,
                                          StackTrace? stackTrace) {
                                        // Log the error if needed
                                        print(
                                            'Error loading image: ${option.name}');
                                        // Return a placeholder image or an icon
                                        return const Icon(Icons.broken_image,
                                            size: 50, color: Colors.red);
                                      },
                                    ),
                                  ),
                                  title: Text(
                                    option.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  trailing: Checkbox(
                                    value: option.isSelected,
                                    activeColor: Colors.blue,
                                    onChanged: (value) {
                                      setState(() {
                                        option.isSelected = value ?? false;
                                      });
                                    },
                                  ),
                                  onTap: () {
                                    setState(() {
                                      option.isSelected = !option.isSelected;
                                    });
                                  },
                                ),
                              ),
                            ),
                            // Configuration Card (visible only when selected)
                            if (option.isSelected)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 15),
                                  child: ExpansionTile(
                                    title: const Text('Configure Option'),
                                    initiallyExpanded: true,
                                    children: [
                                      // Switch to require photo upload
                                      SwitchListTile(
                                        title:
                                            const Text('Require Photo Upload'),
                                        value: option.requiresPhotoUpload,
                                        onChanged: (value) {
                                          setState(() {
                                            option.requiresPhotoUpload = value;
                                            if (!value) {
                                              option.photoUploadPrompt = '';
                                            }
                                          });
                                        },
                                      ),
                                      // TextField for photo upload prompt (visible only if photo upload is required)
                                      if (option.requiresPhotoUpload)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                          child: TextFormField(
                                            decoration: const InputDecoration(
                                              labelText: 'Photo Upload Prompt',
                                              hintText:
                                                  'e.g., Upload a similar design / your photo on the product',
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                option.photoUploadPrompt =
                                                    value;
                                              });
                                            },
                                            controller: TextEditingController(
                                                text: option.photoUploadPrompt),
                                          ),
                                        ),
                                      // Dynamic Custom Fields
                                      ...option.customFields.map((field) {
                                        switch (field.type) {
                                          case FieldType.text:
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: TextFormField(
                                                decoration: InputDecoration(
                                                  labelText: field.label,
                                                  hintText: field.isRequired
                                                      ? 'Required'
                                                      : 'Optional',
                                                ),
                                                onChanged: (value) {
                                                  // Handle changes to the text field
                                                  // Example: Save value in selectedOptions map
                                                  selectedOptions[field.id] =
                                                      value;
                                                },
                                              ),
                                            );
                                          case FieldType.number:
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: TextFormField(
                                                decoration: InputDecoration(
                                                  labelText: field.label,
                                                  hintText: field.isRequired
                                                      ? 'Required'
                                                      : 'Optional',
                                                ),
                                                keyboardType:
                                                    const TextInputType
                                                        .numberWithOptions(
                                                        decimal: true),
                                                onChanged: (value) {
                                                  // Handle changes to the number field
                                                  selectedOptions[field.id] =
                                                      double.tryParse(value);
                                                },
                                              ),
                                            );
                                          case FieldType.dropdown:
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: DropdownButtonFormField<
                                                  String>(
                                                decoration: InputDecoration(
                                                  labelText: field.label,
                                                  hintText: field.isRequired
                                                      ? 'Please select'
                                                      : 'Optional',
                                                ),
                                                items: field.options!
                                                    .map((option) =>
                                                        DropdownMenuItem(
                                                          value: option.value,
                                                          child: Text(
                                                              '${option.value} (+\$${option.extraCost.toStringAsFixed(2)})'),
                                                        ))
                                                    .toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    selectedOptions[field.id] =
                                                        value;
                                                  });
                                                },
                                                validator: (value) {
                                                  if (field.isRequired &&
                                                      value == null) {
                                                    return 'Please select an option';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            );
                                          case FieldType.checkbox:
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                children: field.options!
                                                    .map((option) {
                                                  return CheckboxListTile(
                                                    title: Text(
                                                        '${option.value} (+\$${option.extraCost.toStringAsFixed(2)})'),
                                                    value: selectedOptions[
                                                                    field.id] !=
                                                                null &&
                                                            (selectedOptions[
                                                                        field
                                                                            .id]
                                                                    as List<
                                                                        String>)
                                                                .contains(option
                                                                    .value)
                                                        ? true
                                                        : false,
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        if (value == true) {
                                                          if (selectedOptions[
                                                                  field.id] ==
                                                              null) {
                                                            selectedOptions[
                                                                    field.id] =
                                                                <String>[];
                                                          }
                                                          (selectedOptions[
                                                                      field.id]
                                                                  as List<
                                                                      String>)
                                                              .add(
                                                                  option.value);
                                                        } else {
                                                          (selectedOptions[
                                                                      field.id]
                                                                  as List<
                                                                      String>)
                                                              .remove(
                                                                  option.value);
                                                        }
                                                      });
                                                    },
                                                  );
                                                }).toList(),
                                              ),
                                            );
                                          case FieldType.imageUpload:
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    field.label,
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  ElevatedButton.icon(
                                                    onPressed: () {
                                                      // Implement image upload functionality
                                                    },
                                                    icon: const Icon(
                                                        Icons.upload),
                                                    label: const Text(
                                                        'Upload Image'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          case FieldType.date:
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: DatePickerField(
                                                label: field.label,
                                                isRequired: field.isRequired,
                                                /*  onDateSelected: (selectedDate) {
                                                  setState(() {
                                                    selectedOptions[field.id] = selectedDate;
                                                  });
                                                },*/
                                              ),
                                            );
                                          default:
                                            return const SizedBox.shrink();
                                        }
                                      }).toList(),
                                      // Adding a new custom field dynamically
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            // Navigate to management page or open a dialog to add a new custom field
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditCustomFieldPage(
                                                  onSave: (newField) {
                                                    setState(() {
                                                      option.customFields
                                                          .add(newField);
                                                    });
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add Custom Field'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  // Save Configurations Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _saveSpecialOrderConfigurations, // Ensure this method exists and handles saving
                        icon: const Icon(Icons.save, color: Colors.white70),
                        label: const Text(
                          'Save Configurations',
                          style: TextStyle(color: Colors.white70),
                        ),
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.blue), // Replace with your desired color
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Method to save configurations to backend
  Future<void> _saveSpecialOrderConfigurations() async {
    try {
      // Convert the selectedOrderOptions to a list of maps
      List<Map<String, dynamic>> configurations = orderOptions.map((option) {
        return option.toMap();
      }).toList();

      // Prepare the payload
      Map<String, dynamic> payload = {
        'category': widget.category,
        'specialOrderOptions': configurations,
      };

      // Send the payload to the backend (replace with your API endpoint)
      final token = await _getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication token not found.")),
        );
        return;
      }

      final response = await http
          .post(
            Uri.parse('{Config.apiBaseUrl}/saveSpecialOrderConfigurations'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 10)); // Add a timeout

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Configurations saved successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Failed to save configurations: ${response.reasonPhrase}")),
        );
      }
    } on http.ClientException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Client error: ${e.message}")),
      );
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request timed out. Please try again.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred: $e")),
      );
    }
  }
}
*/