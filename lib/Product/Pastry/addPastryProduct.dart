import 'package:craft_blend_project/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddPastryProduct extends StatefulWidget {
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

  // Selected Options
  final Map<String, List<Map<String, dynamic>>> selectedOptions = {
    'Topping': [],
    'Filling': [],
    'Flavor': [],
  };

  // Add Product Method
  Future<void> _addProduct() async {
    try {
      final Map<String, dynamic> productData = {
        'name': titleController.text,
        'description': descriptionController.text,
        'price': double.tryParse(priceController.text) ?? 0,
        'category': 'Pastry',
        'stock': selectedAvailability == 'In Stock'
            ? int.tryParse(stockController.text) ?? 0
            : 0,
        'timeRequired': selectedAvailability == 'Time Required'
            ? (int.parse(selectedDay!) * 1440 +
                int.parse(selectedHour!) * 60 +
                int.parse(selectedMinute!))
            : null,
        'inStock': selectedAvailability == 'In Stock',
        'availableOptions': {
          'Topping': selectedOptions['Topping']!,
          'Filling': selectedOptions['Filling']!,
          'Flavor': selectedOptions['Flavor']!,
        },
      };

      print("productData SENT:");
      print(jsonEncode(productData));

      final response = await http.post(
        Uri.parse(addNewPastryProduct),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product added successfully!')),
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
  void _addNewOption(String category) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New $category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Enter new $category',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Extra Cost (ILS)',
                hintText: 'Enter extra cost (e.g., 5)',
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
                  predefinedOptions[category]?.add({
                    'name': nameController.text,
                    'extraCost': double.tryParse(priceController.text) ?? 0,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Add New Category Method
  void _addNewCategory() {
    final TextEditingController categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Category'),
        content: TextField(
          controller: categoryController,
          decoration: InputDecoration(
            labelText: 'Category Name',
            hintText: 'Enter a new category name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (categoryController.text.isNotEmpty) {
                setState(() {
                  predefinedOptions[categoryController.text] = [];
                  selectedOptions[categoryController.text] = [];
                });
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Build Method
  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: Text('Add Pastry Product'),
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.2,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/pastry.jpg'),
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
                SizedBox(height: 16),
                _buildInputField(priceController, 'Price'),
                SizedBox(height: 16),
                _buildInputField(descriptionController, 'Description'),
                SizedBox(height: 16),
                _buildAvailabilityDropdown(),
                SizedBox(height: 16),
                if (selectedAvailability == 'In Stock')
                  _buildInputField(stockController, 'Stock Quantity'),
                if (selectedAvailability == 'Time Required')
                  _buildTimeRequiredDropdown(),
                SizedBox(height: 16),
                ...predefinedOptions.keys.map((category) {
                  return _buildOptionCard(category);
                }).toList(),
                SizedBox(height: 24),
                _buildAddNewCategoryButton(),
                SizedBox(height: 24),
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
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildAvailabilityDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedAvailability,
      decoration: InputDecoration(
        labelText: 'Availability',
        border: OutlineInputBorder(),
      ),
      items: [
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
        SizedBox(width: 8),
        _buildDropdownField('Hours', 24, selectedHour, (value) {
          setState(() {
            selectedHour = value;
          });
        }),
        SizedBox(width: 8),
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
          border: OutlineInputBorder(),
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

  Widget _buildOptionCard(String category) {
    return Card(
      color: myColor,
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select $category',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.white70),
                  onPressed: () => _addNewOption(category),
                ),
              ],
            ),
            Wrap(
              spacing: 8.0,
              children: predefinedOptions[category]!.map((option) {
                return FilterChip(
                  label: Text(
                    '${option['name']} ${option['extraCost'] > 0 ? '(+${option['extraCost']} ILS)' : ''}',
                  ),
                  selected:
                      selectedOptions[category]?.contains(option) ?? false,
                  onSelected: (isSelected) {
                    setState(() {
                      if (isSelected) {
                        selectedOptions[category]?.add(option);
                      } else {
                        selectedOptions[category]?.remove(option);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewCategoryButton() {
    return ElevatedButton.icon(
      onPressed: _addNewCategory,
      icon: Icon(Icons.add_circle_rounded, color: Colors.white70),
      label: Text(
        "Add New Category",
        style: TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: myColor,
        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      child: ElevatedButton(
        onPressed: _addProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: myColor,
          shape: const StadiumBorder(),
          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
        ),
        child: Text(
          'Add Product',
          style: TextStyle(fontSize: 15, color: Colors.white),
        ),
      ),
    );
  }
}
