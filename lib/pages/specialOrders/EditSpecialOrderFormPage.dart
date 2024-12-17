import 'package:flutter/material.dart';
import '../../configuration/config.dart';

class EditSpecialOrderFormPage extends StatefulWidget {
  final String orderOption;

  const EditSpecialOrderFormPage({super.key, required this.orderOption});

  @override
  _EditSpecialOrderFormPageState createState() =>
      _EditSpecialOrderFormPageState();
}

class _EditSpecialOrderFormPageState extends State<EditSpecialOrderFormPage> {
  // Example form fields that can be edited for the special order
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
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: Text(
          'Edit ${widget.orderOption} Form',
          style: const TextStyle(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: myColor,
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 24.0),
              ),
              child: const Text('Add New Field'),
            ),
          ],
        ),
      ),
    );
  }
}
