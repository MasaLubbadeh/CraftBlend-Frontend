// lib/pages/special_orders/special_orders_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../components/datePicker.dart';
import '../../../configuration/config.dart';
import '../../../models/custom__field.dart';
import '../../../models/order_option.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'EditCustomFieldPage.dart';
import 'ManageSpecialOrderOptionsPage.dart';

// Define the color variable

class SpecialOrdersPage extends StatefulWidget {
  final String category;

  const SpecialOrdersPage({super.key, required this.category});

  @override
  _SpecialOrdersPageState createState() => _SpecialOrdersPageState();
}

class _SpecialOrdersPageState extends State<SpecialOrdersPage> {
  //late TextEditingController _photoUploadPromptController;
  Map<String, TextEditingController> _photoUploadPromptControllers = {};

  Map<String, TextEditingController> _descriptionControllers = {};

  bool specialOrdersEnabled =
      true; // Indicates if the store allows special orders

  // Define the categories and their default options
  Map<String, List<String>> categoryDefaultOptions = {
    'Phone Accessories': ['Personalized designs', 'Large orders'],
    'Pottery': ['Custom Pottery Design', 'Bulk orders'],
    'Gift Items': [
      'Personalized Gift Packaging',
      'Custom Gift Set Design',
    ],
    'Crochet & Knitting': [
      'Personalized designs',
      'Large quantities',
    ],
    'Flowers': [
      'Personalized designs',
      'Event-specific bulk arrangements',
    ],
    'Pastry & Bakery': [
      'Custom-Made Cake',
      'Large Orders',
    ],
  };

  // Function to get image path for a given option and category
  String _getImageForOption(String option, String category) {
    Map<String, Map<String, String>> categoryImages = {
      'Pastry & Bakery': {
        'Custom-Made Cake': 'assets/images/cake.png',
        'Large Orders': 'assets/images/bulk-buying1.png',
      },
      'Flowers': {
        'Event-specific bulk arrangements': 'assets/images/bulk-buying1.png',
        'Personalized designs': 'assets/images/notes.png',
      },
      'Pottery': {
        'Custom Pottery Design': 'assets/images/notes.png',
        'Bulk orders': 'assets/images/bulkBuying.png',
      },
      'Gift Items': {
        'Personalized Gift Packaging': 'assets/images/notes.png',
        'Custom Gift Set Design': 'assets/images/notes.png',
      },
      'Crochet & Knitting': {
        'Personalized designs': 'assets/images/notes.png',
        'Large quantities': 'assets/images/bulkBuying.png',
      },
      'Phone Accessories': {
        'Personalized designs': 'assets/images/notes.png',
        'Large orders': 'assets/images/bulkBuying.png',
      },
    };

    return categoryImages[category]?[option] ?? 'assets/images/notes.png';
  }

  // Example function to retrieve the token
  Future<String?> getToken() async {
    // Use SharedPreferences or secure storage to retrieve the token
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Navigate to the Review Special Orders Page
  void _navigateToReviewSpecialOrdersPage() {
    /*  Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReviewSpecialOrdersPage()),
    );*/
  }

  // Define the selectedOrderOptions map
  Map<String, OrderOption> selectedOrderOptions = {};

  @override
  void initState() {
    super.initState();
    _initializeOrderOptions(); // Initialize options based on category
//    _photoUploadPromptController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    // Dispose of all photo upload prompt controllers
    _photoUploadPromptControllers.forEach((key, controller) {
      controller.dispose();
    });

    // Dispose of all description controllers
    _descriptionControllers.forEach((key, controller) {
      controller.dispose();
    });
    // Dispose of the controller when the widget is disposed
    //  _photoUploadPromptController.dispose();
    super.dispose();
  }

  void _initializeOrderOptions() {
    final defaultOptions = categoryDefaultOptions[widget.category] ?? [];
    setState(() {
      selectedOrderOptions = {
        for (var option in defaultOptions) option: OrderOption(name: option),
      };
      // Initialize controllers for each option
      selectedOrderOptions.forEach((key, option) {
        _photoUploadPromptControllers[key] =
            TextEditingController(text: option.photoUploadPrompt);
        _descriptionControllers[key] =
            TextEditingController(text: option.description);
      });
    });
  }

  // Build the list of special order options with expandable configuration cards
  // Build the list of special order options with expandable configuration cards
  Widget _buildSpecialOrderOptions() {
    if (selectedOrderOptions.isEmpty) {
      return const Center(child: Text('No special order options available.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Prevent nested scrolling
      itemCount: selectedOrderOptions.length,
      itemBuilder: (context, index) {
        final optionTitle = selectedOrderOptions.keys.elementAt(index);
        final orderOption = selectedOrderOptions[optionTitle]!;
        final isSelected = orderOption.isSelected;
        final imagePath = _getImageForOption(optionTitle, widget.category);

        return Column(
          children: [
            // Option Card with Checkbox
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 15),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.asset(
                      imagePath,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (BuildContext context, Object exception,
                          StackTrace? stackTrace) {
                        // Log the error if needed
                        print('Error loading image: $imagePath');
                        // Return a placeholder image or an icon
                        return Image.asset(
                          'assets/images/placeholder.png', // Ensure you have a placeholder image
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  title: Text(
                    optionTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: myColor),
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    activeColor: myColor, // Replace with your desired color
                    onChanged: (value) {
                      setState(() {
                        orderOption.isSelected = value ?? false;
                        if (!orderOption.isSelected) {
                          // Optionally clear description and photo prompt when deselected
                          _descriptionControllers[optionTitle]?.text = '';
                          _photoUploadPromptControllers[optionTitle]?.text = '';
                        }
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      orderOption.isSelected = !orderOption.isSelected;
                      if (!orderOption.isSelected) {
                        // Optionally clear description and photo prompt when deselected
                        _descriptionControllers[optionTitle]?.text = '';
                        _photoUploadPromptControllers[optionTitle]?.text = '';
                      }
                    });
                  },
                ),
              ),
            ),
            // Configuration Card (visible only when selected)
            if (isSelected)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0),
                child: Card(
                  color: myColor, // Ensure `myColor` is defined in your code
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 15),
                  child: ExpansionTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    iconColor: Colors.white70,
                    collapsedIconColor: Colors.white70,
                    backgroundColor: myColor,
                    title: const Text(
                      'Configure Option',
                      style: TextStyle(color: Colors.white70, letterSpacing: 2),
                    ),
                    initiallyExpanded: true,
                    children: [
                      Divider(),
                      // Description Field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextFormField(
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(color: Colors.white70),
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'Enter a description for this option',
                            labelStyle: const TextStyle(color: Colors.white70),
                            hintStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.white70, width: 2.0),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              orderOption.description = value;
                            });
                          },
                          controller: _descriptionControllers[optionTitle],
                        ),
                      ),
                      // Switch to require photo upload
                      SwitchListTile(
                        activeColor: Colors.white70,
                        title: const Text(
                          'Allow Photo Upload',
                          style: TextStyle(color: Colors.white70),
                        ),
                        value: orderOption.requiresPhotoUpload,
                        onChanged: (value) {
                          setState(() {
                            orderOption.requiresPhotoUpload = value;
                            if (!value) {
                              orderOption.photoUploadPrompt = '';
                              _photoUploadPromptControllers[optionTitle]?.text =
                                  '';
                            }
                          });
                        },
                      ),
                      // TextField for photo upload prompt (visible only if photo upload is required)
                      if (orderOption.requiresPhotoUpload)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextFormField(
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(color: Colors.white70),
                            decoration: InputDecoration(
                              labelText: 'Photo Upload Prompt',
                              hintText:
                                  'e.g., Upload a similar design / your photo on the product',
                              labelStyle:
                                  const TextStyle(color: Colors.white70),
                              hintStyle: const TextStyle(color: Colors.white70),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white70),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white70, width: 2.0),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                orderOption.photoUploadPrompt = value;
                              });
                            },
                            controller:
                                _photoUploadPromptControllers[optionTitle],
                          ),
                        ),
                      // Dynamic Custom Fields
                      ...orderOption.customFields.map((field) {
                        switch (field.type) {
                          case FieldType.text:
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: TextField(
                                textDirection: TextDirection.ltr,
                                decoration: InputDecoration(
                                  labelText: field.label,
                                  hintText: field.isRequired
                                      ? 'Required'
                                      : 'Optional',
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                  hintStyle:
                                      const TextStyle(color: Colors.white70),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white70),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.white70, width: 2.0),
                                  ),
                                ),
                                onChanged: (value) {
                                  // Handle changes to the text field
                                },
                                style: const TextStyle(color: Colors.white70),
                              ),
                            );
                          case FieldType.number:
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: field.label,
                                  hintText: field.isRequired
                                      ? 'Required'
                                      : 'Optional',
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                  hintStyle:
                                      const TextStyle(color: Colors.white70),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white70),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.white70, width: 2.0),
                                  ),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: (value) {
                                  // Handle changes to the number field
                                },
                                style: const TextStyle(color: Colors.white70),
                              ),
                            );
                          case FieldType.dropdown:
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: field.label,
                                  hintText: field.isRequired
                                      ? 'Please select'
                                      : 'Optional',
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                  hintStyle:
                                      const TextStyle(color: Colors.white70),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white70),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.white70, width: 2.0),
                                  ),
                                ),
                                dropdownColor: Colors.grey[800],
                                style: const TextStyle(color: Colors.white70),
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white70,
                                ),
                                items: field.options!
                                    .map((option) => DropdownMenuItem(
                                          value: option.value,
                                          child: Text(
                                            '${option.value} (+\$${option.extraCost.toStringAsFixed(2)})',
                                            style: const TextStyle(
                                                color: Colors.white70),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  // Handle dropdown selection
                                },
                                validator: (value) {
                                  if (field.isRequired && value == null) {
                                    return 'Please select an option';
                                  }
                                  return null;
                                },
                              ),
                            );
                          case FieldType.checkbox:
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: field.options!.map((option) {
                                  return CheckboxListTile(
                                    title: Text(
                                      '${option.value} (+\$${option.extraCost.toStringAsFixed(2)})',
                                      style: const TextStyle(
                                          color: Colors.white70),
                                    ),
                                    value: false, // Handle state accordingly
                                    onChanged: (bool? value) {
                                      // Handle checkbox changes
                                    },
                                    activeColor: Colors.white70,
                                    checkColor:
                                        Colors.black, // For better visibility
                                  );
                                }).toList(),
                              ),
                            );
                          case FieldType.imageUpload:
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    field.label,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // Implement image upload functionality
                                    },
                                    icon: const Icon(
                                      Icons.upload,
                                      color: Colors.white70,
                                    ),
                                    label: const Text(
                                      'Upload Image',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          myColor, // Ensure `myColor` is defined
                                      side: BorderSide(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  /*
                                // Optionally display the uploaded image
                                if (orderOption.imageUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: Image.network(
                                      orderOption.imageUrl!,
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.red,
                                        );
                                      },
                                    ),
                                  ),
                                 */
                                ],
                              ),
                            );
                          case FieldType.date:
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: DatePickerField(
                                label: field.label,
                                isRequired: field.isRequired,
                                // Implement onDateSelected if needed
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
                                builder: (context) => EditCustomFieldPage(
                                  onSave: (newField) {
                                    setState(() {
                                      orderOption.customFields.add(newField);
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, color: Colors.white70),
                          label: const Text(
                            'Add Custom Field',
                            style: TextStyle(color: Colors.white70),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                myColor, // Ensure `myColor` is defined
                            side: const BorderSide(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAddOptionButton() {
    final TextEditingController _newOptionController = TextEditingController();

    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add Special Order Option'),
              content: TextField(
                controller: _newOptionController,
                decoration: const InputDecoration(hintText: 'Enter new option'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final newOption = _newOptionController.text.trim();
                    if (newOption.isNotEmpty) {
                      setState(() {
                        selectedOrderOptions[newOption] =
                            OrderOption(name: newOption);
                        // Optionally, add the new option to categoryDefaultOptions
                        categoryDefaultOptions[widget.category]?.add(newOption);
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white70),
        label: const Text(
          'Add Option',
          style: TextStyle(color: Colors.white70),
        ),
        style: ElevatedButton.styleFrom(backgroundColor: myColor),
      ),
    );
  }

  // Method to save configurations to backend
  // Method to save configurations to backend
  Future<void> _saveSpecialOrderConfigurations() async {
    try {
      final token = await getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication token not found.")),
        );
        return;
      }

      // Show a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Iterate through each selected order option
      for (var entry in selectedOrderOptions.entries) {
        final optionTitle = entry.key;
        final orderOption = entry.value;

        if (!orderOption.isSelected) continue;

        // Prepare the payload based on the StoreSpecialOrderOption schema
        Map<String, dynamic> payload = {
          'name': orderOption.name,
          'description': _descriptionControllers[optionTitle]?.text ?? '',
          'customFields': orderOption.customFields.map((field) {
            return {
              'id': field
                  .id, // Ensure that 'id' is required or handled in the backend
              'label': field.label,
              'type': field.type
                  .toString()
                  .split('.')
                  .last
                  .toLowerCase(), // e.g., 'text', 'dropdown'
              'isRequired': field.isRequired,
              'options': field.options?.map((option) {
                return {
                  'value': option.value,
                  'extraCost': option.extraCost,
                };
              }).toList(),
              'extraCost': field.extraCost,
            };
          }).toList(),
          'requiresPhotoUpload': orderOption.requiresPhotoUpload,
          'photoUploadPrompt':
              _photoUploadPromptControllers[optionTitle]?.text ?? '',
        };
        print('payload $payload');

        // Send POST request for each special order option
        final response = await http
            .post(
              Uri.parse(createStoreSpecialOrderOption),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode(payload),
            )
            .timeout(const Duration(seconds: 10));
        print('response ${response.body}');
        if (response.statusCode == 201) {
          // Option created successfully
          final createdOption = json.decode(response.body);
          print('Created Option: $createdOption');
        } else {
          // Handle failure
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Failed to save option '$optionTitle': ${response.reasonPhrase}",
              ),
            ),
          );
          print('Failed to save option $optionTitle: ${response.body}');
        }
      }

      // Dismiss the loading indicator
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Configurations saved successfully!")),
      );
    } on http.ClientException catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Client error: ${e.message}")),
      );
    } on TimeoutException {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request timed out. Please try again.")),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred: $e")),
      );
    }
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
          'Special Orders Management',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageSpecialOrderOptionsPage(),
                ),
              );
            },
            tooltip: 'Manage Special Order Options',
          ),
          IconButton(
            icon: const Icon(Icons.receipt, color: Colors.white),
            onPressed: _navigateToReviewSpecialOrdersPage,
            tooltip: 'Review Special Orders',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Image with Opacity
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Special Order Options',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildSpecialOrderOptions(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildAddOptionButton(),
                ),
                // Save Configurations Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveSpecialOrderConfigurations,
                      icon: const Icon(Icons.save, color: Colors.white70),
                      label: const Text(
                        'Save Configurations',
                        style: TextStyle(color: Colors.white70),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: myColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
