import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class EditPastryProduct extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditPastryProduct({super.key, required this.product});

  @override
  _EditPastryProductState createState() => _EditPastryProductState();
}

class _EditPastryProductState extends State<EditPastryProduct> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;
  late TextEditingController stockController;

  late Map<String, List<Map<String, dynamic>>> availableOptions;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing product data
    nameController = TextEditingController(text: widget.product['name']);
    priceController = TextEditingController(
        text: widget.product['price']?.toStringAsFixed(2) ?? '');
    descriptionController =
        TextEditingController(text: widget.product['description']);
    stockController =
        TextEditingController(text: widget.product['stock']?.toString() ?? '');

    // Initialize available options with the current product options and safely cast
    availableOptions = {};
    if (widget.product['availableOptions'] != null) {
      widget.product['availableOptions'].forEach((key, value) {
        availableOptions[key] = List<Map<String, dynamic>>.from(value);
      });
    }
  }

  Future<void> _updateProduct() async {
    try {
      final updatedProduct = {
        'id': widget.product['id'], // Include the product ID for update
        'name': nameController.text,
        'price': double.tryParse(priceController.text) ?? 0,
        'description': descriptionController.text,
        'stock': int.tryParse(stockController.text) ?? 0,
        'availableOptions': availableOptions,
      };

      final response = await http.put(
        Uri.parse('http://192.168.1.17:3000/product/updateProduct'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedProduct),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully!')),
        );
        Navigator.pop(context, updatedProduct); // Pass updated data back
      } else {
        throw Exception('Failed to update product');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _editOption(String optionGroup, int index) {
    final option = availableOptions[optionGroup]![index];
    final TextEditingController nameController =
        TextEditingController(text: option['name']);
    final TextEditingController priceController =
        TextEditingController(text: option['extraCost'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $optionGroup Option'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Option Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Extra Cost (ILS)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                availableOptions[optionGroup]![index] = {
                  'name': nameController.text.trim(),
                  'extraCost':
                      double.tryParse(priceController.text.trim()) ?? 0,
                };
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

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
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Extra Cost (ILS)',
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
                  availableOptions[optionGroup]?.add({
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

  void _deleteOption(String optionGroup, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this option?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                availableOptions[optionGroup]?.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
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
          'Edit Product',
          style: TextStyle(
            fontSize: 28,
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
      body: Stack(
        children: [
          // Background Image with Opacity
          Opacity(
            opacity: 0.2,
            child: Container(
              decoration: const BoxDecoration(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputField(nameController, 'Name'),
                const SizedBox(height: 16),
                _buildInputField(priceController, 'Price', isNumber: true),
                const SizedBox(height: 16),
                _buildInputField(descriptionController, 'Description'),
                const SizedBox(height: 16),
                _buildInputField(stockController, 'Stock', isNumber: true),
                const SizedBox(height: 24),
                _buildOptionsSection(),
                const SizedBox(height: 24),
                _buildSaveButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: myColor, width: 2.0),
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: availableOptions.keys.map((optionGroup) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              optionGroup,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: myColor,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(availableOptions[optionGroup]!.length, (index) {
              final option = availableOptions[optionGroup]![index];
              return Card(
                color: const Color.fromARGB(255, 149, 131, 162),
                child: ListTile(
                  title: Text(
                    '${option['name']}',
                    style: TextStyle(color: Colors.white70),
                  ),
                  subtitle: Text(
                      'Extra Cost: ${option['extraCost'].toStringAsFixed(2)} ILS',
                      style: TextStyle(color: Colors.white70)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        onPressed: () => _editOption(optionGroup, index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white),
                        onPressed: () => _deleteOption(optionGroup, index),
                      ),
                    ],
                  ),
                ),
              );
            }),
            Container(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _addNewOption(optionGroup),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add New Option',
                  style: TextStyle(color: Colors.white70),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: myColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _updateProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: myColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        ),
        child: const Text(
          'Save Changes',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
