// lib/pages/special_orders/EditCustomFieldPage.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../configuration/config.dart';
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

  @override
  void dispose() {
    _optionValueController.dispose();
    _optionCostController.dispose();
    super.dispose();
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
        // Section Title
        const Text(
          'Options',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: myColor),
        ),
        const SizedBox(height: 5),
        // Section Description
        const Text(
          "Add options relevant to the selected field type. Each option can have an additional cost.",
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 10),
        // List of Options
        ...options.map((option) {
          return Column(
            children: [
              ListTile(
                title: Text(option.value),
                subtitle: Text(
                    'Extra Cost: \$${option.extraCost.toStringAsFixed(2)}'),
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
              ),
              // Divider after each option
              const Divider(
                color: Colors.grey,
                thickness: 1,
                height: 20,
              ),
            ],
          );
        }).toList(),
        const SizedBox(height: 10),
        // Add Option Button
        ElevatedButton.icon(
          onPressed: _addOption,
          icon: const Icon(Icons.add, color: Colors.white70),
          label: const Text(
            'Add Option',
            style: TextStyle(color: Colors.white70),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: myColor, // Preserved style
            side: const BorderSide(color: Colors.white70),
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
            textStyle: const TextStyle(fontSize: 16),
          ),
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _optionValueController,
                  decoration: const InputDecoration(
                    labelText: 'Option Value',
                    hintText: 'e.g., Small',
                  ),
                ),
                const SizedBox(height: 10),
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _optionValueController,
                  decoration: const InputDecoration(
                    labelText: 'Option Value',
                    hintText: 'e.g., Medium',
                  ),
                ),
                const SizedBox(height: 10),
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
    // Show this field only if the field type is not dropdown or checkbox
    if (selectedType == FieldType.dropdown ||
        selectedType == FieldType.checkbox) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: TextFormField(
        initialValue: extraCost != null ? extraCost.toString() : '',
        decoration: const InputDecoration(
          labelText: 'Extra Cost for Entire Field',
          hintText: 'Enter extra cost if applicable',
          border: OutlineInputBorder(),
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
      ),
    );
  }

  Widget _buildFieldTypeDescription() {
    String description = '';
    switch (selectedType) {
      case FieldType.text:
        description =
            "A single-line text input where customers can enter any information.";
        break;
      case FieldType.number:
        description =
            "A numerical input allowing customers to enter numeric values.";
        break;
      case FieldType.dropdown:
        description =
            "A dropdown menu where customers can select one option from a list.";
        break;
      case FieldType.checkbox:
        description =
            "A list of checkboxes allowing customers to select multiple options.";
        break;
      case FieldType.date:
        description =
            "A date picker enabling customers to select a specific date.";
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        description,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }

  // Helper method to build explanations with visuals (optional)
  Widget _buildFieldTypeExplanation({
    required String imagePath,
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imagePath.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                imagePath,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image,
                      size: 50, color: Colors.red);
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        const Divider(
          color: Colors.grey,
          thickness: 1,
          height: 20,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtain screen width and height for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Determine padding based on screen size
    final horizontalPadding = screenWidth * 0.05; // 5% of screen width
    final verticalPadding = screenHeight * 0.02; // 2% of screen height

    // Adjust image sizes based on screen width
    final explanationImageSize = screenWidth * 0.12; // 12% of screen width

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: screenHeight * 0.08, // 8% of screen height
        title: Text(
          widget.customField == null ? 'Add Custom Field' : 'Edit Custom Field',
          style: TextStyle(
            fontSize: screenWidth * 0.05, // Responsive font size
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white70),
            onPressed: _saveField,
            tooltip: 'Save Field',
          ),
        ],
        backgroundColor: myColor,
      ),
      body: Stack(
        children: [
          // Background Image with Opacity
          Opacity(
            opacity: 0.1,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/pastry.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Note Above the Form
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "** These fields represent the questions and choices that customers will interact with when placing an order. The setup is fully flexible! **",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Field Label
                  TextFormField(
                    initialValue: label,
                    decoration: const InputDecoration(
                      labelText: 'Field Label',
                      hintText: 'e.g., Choose Size',
                      border: OutlineInputBorder(),
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
                      border: OutlineInputBorder(),
                    ),
                    items: FieldType.values.map((FieldType type) {
                      String typeName = '';
                      switch (type) {
                        case FieldType.text:
                          typeName = 'Text';
                          break;
                        case FieldType.number:
                          typeName = 'Number';
                          break;
                        case FieldType.dropdown:
                          typeName = 'Dropdown';
                          break;
                        case FieldType.checkbox:
                          typeName = 'Checkbox';
                          break;
                        case FieldType.date:
                          typeName = 'Date';
                          break;
                      }
                      return DropdownMenuItem<FieldType>(
                        value: type,
                        child: Text(typeName),
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
                  const SizedBox(height: 8),

                  // Field Type Description
                  _buildFieldTypeDescription(),
                  const SizedBox(height: 20),

                  // Options Section
                  _buildOptionsSection(),
                  // "Is Required" Switch
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Column(
                      children: [
                        Divider(),
                        SwitchListTile(
                          //tileColor: myColor,
                          activeColor: myColor,
                          title: const Text(
                            'Is Required',
                            style: TextStyle(color: myColor),
                          ),
                          value: isRequired,
                          onChanged: (value) {
                            setState(() {
                              isRequired = value;
                            });
                          },
                        ),
                        Divider(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Extra Cost for Entire Field (Optional)
                  _buildExtraCostField(),
                  const SizedBox(height: 20),

                  // Divider before Explanations
                  const Divider(thickness: 1.0),
                  const SizedBox(height: 10),

                  // Field Type Explanations
                  const Text(
                    'Field Type Explanations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dropdown Explanation with Image
                      _buildFieldTypeExplanation(
                        imagePath: 'assets/images/dropdown.png',
                        title: 'Dropdown',
                        description:
                            'A dropdown menu where customers can select one option from a list.',
                      ),
                      const SizedBox(height: 10),

                      // Checkbox Explanation with Image
                      _buildFieldTypeExplanation(
                        imagePath: 'assets/images/checkboxes.png',
                        title: 'Checkbox',
                        description:
                            'A list of checkboxes allowing customers to select multiple options.',
                      ),
                      const SizedBox(height: 10),

                      // Text Explanation without Image
                      _buildFieldTypeExplanation(
                        imagePath:
                            'assets/images/textInput.png', // Ensure this path is correct
                        title: 'Text',
                        description:
                            'A single-line text input where customers can enter any information.',
                      ),
                      const SizedBox(height: 10),

                      // Number Explanation with Image
                      _buildFieldTypeExplanation(
                        imagePath: 'assets/images/number-blocks.png',
                        title: 'Number',
                        description:
                            'A numerical input allowing customers to enter numeric values.',
                      ),
                      const SizedBox(height: 10),

                      // Date Explanation with Image
                      _buildFieldTypeExplanation(
                        imagePath: 'assets/images/calendar.png',
                        title: 'Date',
                        description:
                            'A date picker enabling customers to select a specific date.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
