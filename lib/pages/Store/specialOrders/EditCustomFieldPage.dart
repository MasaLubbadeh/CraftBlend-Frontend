// lib/pages/special_orders/EditCustomFieldPage.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/custom__field.dart';
import '../../../models/field_option.dart';

class EditCustomFieldPage extends StatefulWidget {
  final CustomField? customField;
  final Function(CustomField) onSave;

  const EditCustomFieldPage({Key? key, this.customField, required this.onSave})
      : super(key: key);

  @override
  _EditCustomFieldPageState createState() => _EditCustomFieldPageState();
}

class _EditCustomFieldPageState extends State<EditCustomFieldPage> {
  final _formKey = GlobalKey<FormState>();
  late String label;
  late FieldType selectedType;
  bool isRequired = false;
  List<FieldOption> options = [];
  double? extraCost;

  // Controllers for adding/editing options
  final TextEditingController _optionValueController = TextEditingController();
  final TextEditingController _optionCostController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customField != null) {
      label = widget.customField!.label;
      selectedType = widget.customField!.type;
      isRequired = widget.customField!.isRequired;
      options = widget.customField!.options ?? [];
      extraCost = widget.customField!.extraCost;
    } else {
      label = '';
      selectedType = FieldType.text;
    }
  }

  void _saveField() {
    if (_formKey.currentState!.validate()) {
      // Additional validation for options
      if ((selectedType == FieldType.dropdown ||
              selectedType == FieldType.checkbox) &&
          options.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please add at least one option.")),
        );
        return;
      }

      // Check for unique option values
      final optionValues = options.map((e) => e.value.toLowerCase()).toList();
      if (optionValues.toSet().length != optionValues.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Option values must be unique.")),
        );
        return;
      }

      // Check for non-negative extra costs
      for (var option in options) {
        if (option.extraCost < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Extra costs cannot be negative.")),
          );
          return;
        }
      }

      CustomField updatedField = CustomField(
        id: widget.customField?.id ?? const Uuid().v4(),
        label: label,
        type: selectedType,
        isRequired: isRequired,
        options: (selectedType == FieldType.dropdown ||
                selectedType == FieldType.checkbox)
            ? options
            : null,
        extraCost: extraCost,
      );
      widget.onSave(updatedField);
      Navigator.pop(context);
    }
  }

  Widget _buildOptionsSection() {
    if (selectedType != FieldType.dropdown &&
        selectedType != FieldType.checkbox) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Options',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        ...options.map((option) {
          return ListTile(
            title: Text(option.value),
            subtitle:
                Text('Extra Cost: \$${option.extraCost.toStringAsFixed(2)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editOption(option),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteOption(option),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _addOption,
          icon: const Icon(Icons.add),
          label: const Text('Add Option'),
        ),
      ],
    );
  }

  void _addOption() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _optionValueController,
                decoration: const InputDecoration(
                  labelText: 'Option Value',
                  hintText: 'e.g., Small',
                ),
              ),
              TextField(
                controller: _optionCostController,
                decoration: const InputDecoration(
                  labelText: 'Extra Cost',
                  hintText: 'e.g., 20.00',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _optionValueController.clear();
                _optionCostController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String value = _optionValueController.text.trim();
                double? cost =
                    double.tryParse(_optionCostController.text.trim());

                if (value.isNotEmpty && cost != null) {
                  // Check for duplicate option
                  if (options.any((opt) =>
                      opt.value.toLowerCase() == value.toLowerCase())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Option already exists.")),
                    );
                    return;
                  }

                  setState(() {
                    options.add(FieldOption(value: value, extraCost: cost));
                  });
                  _optionValueController.clear();
                  _optionCostController.clear();
                  Navigator.pop(context);
                } else {
                  // Show error if inputs are invalid
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter valid values.")),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editOption(FieldOption option) {
    _optionValueController.text = option.value;
    _optionCostController.text = option.extraCost.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _optionValueController,
                decoration: const InputDecoration(
                  labelText: 'Option Value',
                  hintText: 'e.g., Medium',
                ),
              ),
              TextField(
                controller: _optionCostController,
                decoration: const InputDecoration(
                  labelText: 'Extra Cost',
                  hintText: 'e.g., 30.00',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _optionValueController.clear();
                _optionCostController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String newValue = _optionValueController.text.trim();
                double? newCost =
                    double.tryParse(_optionCostController.text.trim());

                if (newValue.isNotEmpty && newCost != null) {
                  // Check for duplicate option excluding the current one
                  if (options.any((opt) =>
                      opt.value.toLowerCase() == newValue.toLowerCase() &&
                      opt != option)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Option already exists.")),
                    );
                    return;
                  }

                  setState(() {
                    option.value = newValue;
                    option.extraCost = newCost;
                  });
                  _optionValueController.clear();
                  _optionCostController.clear();
                  Navigator.pop(context);
                } else {
                  // Show error if inputs are invalid
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter valid values.")),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteOption(FieldOption option) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Option'),
        content: const Text('Are you sure you want to delete this option?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                options.remove(option);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraCostField() {
    return TextFormField(
      initialValue: extraCost != null ? extraCost.toString() : '',
      decoration: const InputDecoration(
        labelText: 'Extra Cost for Entire Field',
        hintText: 'Enter extra cost if applicable',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        setState(() {
          extraCost = double.tryParse(value);
        });
      },
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          double? cost = double.tryParse(value);
          if (cost == null || cost < 0) {
            return 'Please enter a valid non-negative number';
          }
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showOptions = selectedType == FieldType.dropdown ||
        selectedType == FieldType.checkbox;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customField == null
            ? 'Add Custom Field'
            : 'Edit Custom Field'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveField,
            tooltip: 'Save Field',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Field Label
              TextFormField(
                initialValue: label,
                decoration: const InputDecoration(
                  labelText: 'Field Label',
                  hintText: 'e.g., Choose Size',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a label';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    label = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              // Field Type
              DropdownButtonFormField<FieldType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Field Type',
                ),
                items: FieldType.values.map((FieldType type) {
                  return DropdownMenuItem<FieldType>(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (FieldType? newType) {
                  if (newType != null) {
                    setState(() {
                      selectedType = newType;
                      if (selectedType != FieldType.dropdown &&
                          selectedType != FieldType.checkbox) {
                        options = [];
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              // Options Section
              _buildOptionsSection(),
              const SizedBox(height: 20),
              // Is Required
              SwitchListTile(
                title: const Text('Is Required'),
                value: isRequired,
                onChanged: (value) {
                  setState(() {
                    isRequired = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              // Extra Cost for Entire Field (Optional)
              _buildExtraCostField(),
            ],
          ),
        ),
      ),
    );
  }
}
