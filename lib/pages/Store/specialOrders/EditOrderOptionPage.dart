// lib/pages/special_orders/edit_order_option_page.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/custom__field.dart';
import '../../../models/order_option.dart';
import 'EditCustomFieldPage.dart';
import 'ManageSpecialOrderOptionsPage.dart';

class EditOrderOptionPage extends StatefulWidget {
  final OrderOption? orderOption;
  final Function(OrderOption) onSave;

  const EditOrderOptionPage({Key? key, this.orderOption, required this.onSave})
      : super(key: key);

  @override
  _EditOrderOptionPageState createState() => _EditOrderOptionPageState();
}

class _EditOrderOptionPageState extends State<EditOrderOptionPage> {
  final _formKey = GlobalKey<FormState>();
  late String optionName;
  bool isSelected = false;
  bool requiresPhotoUpload = false;
  String photoUploadPrompt = '';
  late List<CustomField> customFields;

  @override
  void initState() {
    super.initState();
    optionName = widget.orderOption?.name ?? '';
    isSelected = widget.orderOption?.isSelected ?? false;
    requiresPhotoUpload = widget.orderOption?.requiresPhotoUpload ?? false;
    photoUploadPrompt = widget.orderOption?.photoUploadPrompt ?? '';
    customFields = widget.orderOption?.customFields ?? [];
  }

  void _addCustomField() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCustomFieldPage(
          onSave: (newField) {
            setState(() {
              customFields.add(newField);
            });
          },
        ),
      ),
    );
  }

  void _editCustomField(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCustomFieldPage(
          customField: customFields[index],
          onSave: (updatedField) {
            setState(() {
              customFields[index] = updatedField;
            });
          },
        ),
      ),
    );
  }

  void _deleteCustomField(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Field'),
        content: const Text('Are you sure you want to delete this field?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                customFields.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _saveOption() {
    if (_formKey.currentState!.validate()) {
      OrderOption updatedOption = OrderOption(
        name: optionName,
        isSelected: isSelected,
        requiresPhotoUpload: requiresPhotoUpload,
        photoUploadPrompt: photoUploadPrompt,
        customFields: customFields,
      );
      widget.onSave(updatedOption);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.orderOption == null
              ? 'Add New Order Option'
              : 'Edit Order Option'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveOption,
              tooltip: 'Save Option',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: optionName,
                    decoration: const InputDecoration(
                      labelText: 'Option Name',
                      hintText: 'e.g., Custom-Made Cake',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an option name';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        optionName = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Is Selected'),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        isSelected = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Require Photo Upload'),
                    value: requiresPhotoUpload,
                    onChanged: (value) {
                      setState(() {
                        requiresPhotoUpload = value;
                      });
                    },
                  ),
                  if (requiresPhotoUpload)
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Photo Upload Prompt',
                        hintText:
                            'e.g., Upload a similar design / your photo on the product',
                      ),
                      onChanged: (value) {
                        setState(() {
                          photoUploadPrompt = value;
                        });
                      },
                      controller:
                          TextEditingController(text: photoUploadPrompt),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Custom Fields',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addCustomField,
                        tooltip: 'Add Custom Field',
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: customFields.length,
                      itemBuilder: (context, index) {
                        final field = customFields[index];
                        return ListTile(
                          title: Text(field.label),
                          subtitle: Text(field.type.toString().split('.').last),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editCustomField(index),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteCustomField(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )),
        ));
  }
}
