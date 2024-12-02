import '../../../configuration/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddPastryProduct extends StatefulWidget {
  const AddPastryProduct({super.key});

  @override
  _AddPastryProductState createState() => _AddPastryProductState();
}

class _AddPastryProductState extends State<AddPastryProduct> {
  // Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController stockController = TextEditingController();

  // Availability States
  String? selectedAvailability = 'In Stock';
  String? selectedDay = "0";
  String? selectedHour = "0";
  String? selectedMinute = "0";

  // Predefined Options
  final Map<String, List<Map<String, dynamic>>> predefinedOptions = {
    'Topping': [
      {'name': 'White Chocolate', 'extraCost': 0},
      {'name': 'Milk Chocolate', 'extraCost': 0},
    ],
    'Filling': [
      {'name': 'Chocolate', 'extraCost': 0},
    ],
    'Flavor': [
      {'name': 'Chocolate', 'extraCost': 0},
    ],
  };

  // Available Option Status
  final Map<String, bool> availableOptionStatus = {
    'Topping': false,
    'Filling': false,
    'Flavor': false, // Example: 'Flavor' is optional by default
  };

  // Selected Options
  final Map<String, List<Map<String, dynamic>>> selectedOptions = {
    'Topping': [],
    'Filling': [],
    'Flavor': [],
  };

  // Add Product Method
  Future<void> _addProduct() async {
    try {
      // Retrieve token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Authentication token not found. Please log in again.')),
        );
        return;
      }

      final Map<String, dynamic> productData = {
        'name': titleController.text,
        'description': descriptionController.text,
        'price': double.tryParse(priceController.text) ?? 0,
        //'category': 'Pastry',
        'stock': selectedAvailability == 'In Stock'
            ? int.tryParse(stockController.text) ?? 0
            : 0,
        'timeRequired': selectedAvailability == 'Time Required'
            ? (int.parse(selectedDay!) * 1440 +
                int.parse(selectedHour!) * 60 +
                int.parse(selectedMinute!))
            : null,
        'inStock': selectedAvailability == 'In Stock',
        'availableOptions': selectedOptions.map((optionGroup, options) {
          return MapEntry(optionGroup, options);
        }),
        'availableOptionStatus': availableOptionStatus,
      };

      print("productData SENT:");
      print(jsonEncode(productData));

      final response = await http.post(
        Uri.parse(addNewPastryProduct),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token' // Include the token for authentication
        },
        body: jsonEncode(productData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

// Add New Option Method
  void _addNewOption(String optionGroup) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New $optionGroup Option'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Option Name',
                hintText: 'Enter new option name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Extra Cost (ILS)',
                hintText: 'Enter extra cost (default is 0)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  // Only add to predefinedOptions to avoid duplication
                  predefinedOptions[optionGroup]?.add({
                    'name': nameController.text.trim(),
                    'extraCost':
                        double.tryParse(priceController.text.trim()) ?? 0,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Add New Category Method
  void _addNewCategory() {
    final TextEditingController categoryController = TextEditingController();
    bool isOptional = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Option Group'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    hintText: 'Enter a new option group name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Is Optional?'),
                    Switch(
                      value: isOptional,
                      onChanged: (value) {
                        setState(() {
                          isOptional = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (categoryController.text.isNotEmpty) {
                    setState(() {
                      availableOptionStatus[categoryController.text] =
                          isOptional;
                      predefinedOptions[categoryController.text] = [];
                      selectedOptions[categoryController.text] = [];
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'Add Pastry Product',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.2,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/pastry.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInputField(titleController, 'Title'),
                const SizedBox(height: 16),
                _buildInputField(priceController, 'Price'),
                const SizedBox(height: 16),
                _buildInputField(descriptionController, 'Description'),
                const SizedBox(height: 16),
                _buildAvailabilityDropdown(),
                const SizedBox(height: 16),
                if (selectedAvailability == 'In Stock')
                  _buildInputField(stockController, 'Stock Quantity'),
                if (selectedAvailability == 'Time Required')
                  _buildTimeRequiredDropdown(),
                const SizedBox(height: 16),
                ...predefinedOptions.keys.map((optionGroup) {
                  return _buildOptionCard(optionGroup);
                }),
                const SizedBox(height: 24),
                _buildAddNewCategoryButton(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildInputField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildAvailabilityDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedAvailability,
      decoration: const InputDecoration(
        labelText: 'Availability',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'In Stock', child: Text('In Stock')),
        DropdownMenuItem(value: 'Out of Stock', child: Text('Out of Stock')),
        DropdownMenuItem(value: 'Time Required', child: Text('Time Required')),
      ],
      onChanged: (value) {
        setState(() {
          selectedAvailability = value;
        });
      },
    );
  }

  Widget _buildTimeRequiredDropdown() {
    return Row(
      children: [
        _buildDropdownField('Days', 31, selectedDay, (value) {
          setState(() {
            selectedDay = value;
          });
        }),
        const SizedBox(width: 8),
        _buildDropdownField('Hours', 24, selectedHour, (value) {
          setState(() {
            selectedHour = value;
          });
        }),
        const SizedBox(width: 8),
        _buildDropdownField('Minutes', 60, selectedMinute, (value) {
          setState(() {
            selectedMinute = value;
          });
        }),
      ],
    );
  }

  Widget _buildDropdownField(String label, int range, String? selectedValue,
      Function(String?) onChanged) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: List.generate(range, (index) => index.toString())
            .map((value) => DropdownMenuItem(
                  value: value,
                  child: Text(value),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildOptionCard(String optionGroup) {
    return Card(
      color: myColor,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select $optionGroup',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.white70),
                  onPressed: () => _addNewOption(optionGroup),
                ),
              ],
            ),
            Wrap(
              spacing: 8.0,
              children: predefinedOptions[optionGroup]!.map((option) {
                return FilterChip(
                  label: Text(
                    '${option['name']} ${option['extraCost'] > 0 ? '(+${option['extraCost']} ILS)' : ''}',
                  ),
                  selected:
                      selectedOptions[optionGroup]?.contains(option) ?? false,
                  onSelected: (isSelected) {
                    setState(() {
                      if (isSelected) {
                        selectedOptions[optionGroup]?.add(option);
                      } else {
                        selectedOptions[optionGroup]?.remove(option);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Is Optional?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    )),
                Switch(
                  activeColor: Colors.grey[300],
                  value: availableOptionStatus[optionGroup] ?? false,
                  onChanged: (value) {
                    setState(() {
                      availableOptionStatus[optionGroup] = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewCategoryButton() {
    return ElevatedButton.icon(
      onPressed: _addNewCategory,
      icon: const Icon(Icons.add_circle_rounded, color: Colors.white70),
      label: const Text(
        "Add New Option Group",
        style: TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: myColor,
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: ElevatedButton(
        onPressed: _addProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: myColor,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
        ),
        child: const Text(
          'Add Product',
          style: TextStyle(fontSize: 15, color: Colors.white),
        ),
      ),
    );
  }
}
