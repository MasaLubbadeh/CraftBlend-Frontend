import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../configuration/config.dart';

class SpecialOrdersPage extends StatefulWidget {
  const SpecialOrdersPage({super.key});

  @override
  _SpecialOrdersPageState createState() => _SpecialOrdersPageState();
}

class _SpecialOrdersPageState extends State<SpecialOrdersPage> {
  bool specialOrdersEnabled =
      true; // Indicates if the store allows special orders
  Map<String, bool> selectedOrderOptions = {
    'Custom-Made Cake': false,
    'Large Orders': false,
  }; // Tracks the selection state of each option

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'Special Orders',
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
                _buildSpecialOrdersSwitchCard(),
                const SizedBox(height: 16),
                if (specialOrdersEnabled) _buildOrderOptionsSelectionCard(),
                const SizedBox(height: 24),
                if (specialOrdersEnabled) _buildManageFormsButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialOrdersSwitchCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Allow Special Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: myColor,
              ),
            ),
            Switch(
              activeColor: myColor,
              value: specialOrdersEnabled,
              onChanged: (value) {
                setState(() {
                  specialOrdersEnabled = value;
                  // Here you can also make an API call to save this setting in the backend.
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderOptionsSelectionCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Special Order Options:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: myColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildOrderOptionTile(
                  'Custom-Made Cake',
                  'images/custom_cake.jpg',
                  selectedOrderOptions['Custom-Made Cake'] ?? false,
                  (value) {
                    setState(() {
                      selectedOrderOptions['Custom-Made Cake'] = value ?? false;
                    });
                  },
                ),
                const SizedBox(width: 16),
                _buildOrderOptionTile(
                  'Large Orders',
                  'images/large_order.jpg',
                  selectedOrderOptions['Large Orders'] ?? false,
                  (value) {
                    setState(() {
                      selectedOrderOptions['Large Orders'] = value ?? false;
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

  Widget _buildOrderOptionTile(
      String title, String imagePath, bool value, Function(bool?) onChanged) {
    return Expanded(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Image.asset(
              imagePath,
              height: 100,
              width: double.infinity,
              fit:
                  BoxFit.contain, // Changed from BoxFit.cover to BoxFit.contain
            ),
          ),
          CheckboxListTile(
            title: Text(
              title,
              style: const TextStyle(color: myColor),
            ),
            value: value,
            onChanged: onChanged,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildManageFormsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: specialOrdersEnabled ? _navigateToSetupFormPage : null,
        icon: const Icon(Icons.settings, color: Colors.white70),
        label: const Text(
          'Manage Special Order Forms',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: myColor,
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
        ),
      ),
    );
  }

  void _navigateToSetupFormPage() {
    // Navigate to the page where the owner can set up their special orders form.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SetupSpecialOrderFormPage()),
    );
  }
}

// Placeholder for the SetupSpecialOrderFormPage
class SetupSpecialOrderFormPage extends StatefulWidget {
  @override
  _SetupSpecialOrderFormPageState createState() =>
      _SetupSpecialOrderFormPageState();
}

class _SetupSpecialOrderFormPageState extends State<SetupSpecialOrderFormPage> {
  final List<Map<String, dynamic>> formFields = [
    {'label': 'Customer Name', 'type': 'text', 'required': true},
    {'label': 'Order Details', 'type': 'text', 'required': true},
    {'label': 'Preferred Delivery Date', 'type': 'date', 'required': false},
  ];

  void _addNewField() {
    setState(() {
      formFields.add({'label': 'New Field', 'type': 'text', 'required': false});
    });
  }

  void _removeField(int index) {
    setState(() {
      formFields.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        title: const Text(
          'Setup Special Orders Form',
          style: TextStyle(color: Colors.white70),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: formFields.length,
                itemBuilder: (context, index) {
                  final field = formFields[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(field['label']),
                      subtitle: Text('Type: ${field['type']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeField(index),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addNewField,
              child: const Text('Add New Field'),
              style: ElevatedButton.styleFrom(
                backgroundColor: myColor,
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 24.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
