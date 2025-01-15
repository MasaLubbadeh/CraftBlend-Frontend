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

class SpecialOrdersPage extends StatefulWidget {
  final String category;

  const SpecialOrdersPage({super.key, required this.category});

  @override
  _SpecialOrdersPageState createState() => _SpecialOrdersPageState();
}

class _SpecialOrdersPageState extends State<SpecialOrdersPage> {
  Map<String, TextEditingController> _photoUploadPromptControllers = {};
  Map<String, TextEditingController> _descriptionControllers = {};
  bool specialOrdersEnabled =
      true; // Indicates if the store allows special orders

  // Define the categories and their default options
  Map<String, List<String>> categoryDefaultOptions = {
    'Phone Accessories': ['Personalized designs', 'Large orders'],
    'Pottery': ['Custom Pottery Design', 'Bulk orders'],
    'Gift Items': ['Personalized Gift Packaging', 'Custom Gift Set Design'],
    'Crochet & Knitting': ['Personalized designs', 'Large quantities'],
    'Flowers': [
      'Event-specific bulk arrangements',
      'Personalized designs',
    ],
    'Pastry & Bakery': ['Custom-Made Cake', 'Large Orders'],
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

  bool isLoading = true; // Indicates if data is being loaded

  @override
  void initState() {
    super.initState();
    _fetchStoreSpecialOrderOptions(); // Fetch existing options from backend
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
    super.dispose();
  }

  // Method to fetch existing Special Order Options from backend
  Future<void> _fetchStoreSpecialOrderOptions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await getToken();
      if (token == null) {
        _showSnackBar("Authentication token not found.");
        _initializeWithDefaults();
        return;
      }

      final response = await http.get(
        Uri.parse(getStoreSpecialOrderOptions), // Ensure this URL is correct
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          // Assuming the response is a list of configurations
          List<OrderOption> fetchedOptions =
              List<OrderOption>.from(data.map((x) => OrderOption.fromMap(x)));
          // Flag each fetched option as selected
          for (var option in fetchedOptions) {
            option.isSelected = true;
            print(
                'Fetched Option: ${option.name}, isSelected: ${option.isSelected}');
          }
          setState(() {
            selectedOrderOptions.clear(); // Clear previous entries
            for (var option in fetchedOptions) {
              selectedOrderOptions[option.name] = option;
              // Initialize controllers
              _photoUploadPromptControllers[option.name] =
                  TextEditingController(text: option.photoUploadPrompt);
              _descriptionControllers[option.name] =
                  TextEditingController(text: option.description);
            }
            isLoading = false;
          });
        } else {
          // No existing configurations, initialize with defaults
          _initializeWithDefaults();
        }
      } else {
        // Handle server error
        _showSnackBar("Failed to fetch previous configurations.");
        _initializeWithDefaults();
      }
    } on http.ClientException catch (e) {
      _showSnackBar("Client error: ${e.message}");
      _initializeWithDefaults();
    } on TimeoutException {
      _showSnackBar("Request timed out. Please try again.");
      _initializeWithDefaults();
    } catch (e) {
      _showSnackBar("An unexpected error occurred: $e");
      _initializeWithDefaults();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Initialize with default options if no existing configurations are found
  void _initializeWithDefaults() {
    final defaultOptions = categoryDefaultOptions[widget.category] ?? [];
    setState(() {
      selectedOrderOptions = {
        for (var option in defaultOptions)
          option: OrderOption(
            id: '', name: option, isSelected: true, // Flag as selected
          ),
      };
      // Initialize controllers for each option
      selectedOrderOptions.forEach((key, option) {
        _photoUploadPromptControllers[key] =
            TextEditingController(text: option.photoUploadPrompt);
        _descriptionControllers[key] =
            TextEditingController(text: option.description);
      });
      isLoading = false;
    });
  }

  // Method to show SnackBars
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Method to confirm and remove an option
  void _confirmRemoveOption(String optionTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Option'),
        content: Text('Are you sure you want to remove "$optionTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                // Remove the option from selectedOrderOptions
                selectedOrderOptions.remove(optionTitle);
                // Dispose and remove controllers
                _descriptionControllers[optionTitle]?.dispose();
                _descriptionControllers.remove(optionTitle);
                _photoUploadPromptControllers[optionTitle]?.dispose();
                _photoUploadPromptControllers.remove(optionTitle);
              });
              Navigator.pop(context); // Close the dialog
              _showSnackBar('"$optionTitle" has been removed.');
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Build the list of special order options with expandable configuration cards
  Widget _buildSpecialOrderOptions() {
    if (selectedOrderOptions.isEmpty) {
      return const Center(
        child: Text('No special order options available.'),
      );
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
            // Option Card with Checkbox and Delete Button
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
                      fontWeight: FontWeight.bold,
                      color:
                          myColor, // Ensure `myColor` is defined in your code
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Checkbox
                      Checkbox(
                        value: isSelected,
                        activeColor: myColor, // Replace with your desired color
                        onChanged: (value) {
                          setState(() {
                            orderOption.isSelected = value ?? false;
                            if (!orderOption.isSelected) {
                              // Optionally clear description and photo instructions when deselected
                              _descriptionControllers[optionTitle]?.text = '';
                              _photoUploadPromptControllers[optionTitle]?.text =
                                  '';
                            }
                          });
                        },
                      ),
                      // Delete Button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _confirmRemoveOption(optionTitle);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      orderOption.isSelected = !orderOption.isSelected;
                      if (!orderOption.isSelected) {
                        // Optionally clear description and photo instructions when deselected
                        _descriptionControllers[optionTitle]?.text = '';
                        _photoUploadPromptControllers[optionTitle]?.text = '';
                      }
                    });
                  },
                ),
              ),
            ),
            // Explanatory Text Between Option and Configuration
            if (isSelected)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  "Configure the details for this option below. Here, you can add specific choices, questions, and any important information you need from your customers to fulfill their orders effectively.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.justify,
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
                      const Divider(),
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
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 10),
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
                      // TextField for photo upload prompt (simplified statement)
                      if (orderOption.requiresPhotoUpload)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextFormField(
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(color: Colors.white70),
                            decoration: const InputDecoration(
                              labelText: 'Photo Instructions',
                              hintText:
                                  'e.g., Upload a similar design or your photo on the product',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintStyle: TextStyle(color: Colors.white70),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white70),
                              ),
                              focusedBorder: UnderlineInputBorder(
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
                      const SizedBox(height: 10),
                      const Divider(),
                      // Dynamic Custom Fields
                      ...orderOption.customFields.map((field) {
                        Widget fieldWidget;
                        switch (field.type) {
                          case FieldType.text:
                            fieldWidget = Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
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
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white70),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
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
                            break;
                          case FieldType.number:
                            fieldWidget = Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
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
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white70),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
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
                            break;
                          case FieldType.dropdown:
                            fieldWidget = Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
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
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white70),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
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
                                    .map(
                                      (option) => DropdownMenuItem(
                                        value: option.value,
                                        child: Text(
                                          '${option.value} (+\$${option.extraCost.toStringAsFixed(2)})',
                                          style: const TextStyle(
                                              color: Colors.white70),
                                        ),
                                      ),
                                    )
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
                            break;
                          case FieldType.checkbox:
                            fieldWidget = Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
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
                            break;
                          case FieldType.date:
                            fieldWidget = Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: DatePickerField(
                                label: field.label,
                                isRequired: field.isRequired,
                                // Implement onDateSelected if needed
                              ),
                            );
                            break;
                          default:
                            fieldWidget = const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            fieldWidget,
                            const SizedBox(height: 10),
                            const Divider(
                              color: Colors.white70,
                              thickness: 1,
                              height: 20,
                            ),
                          ],
                        );
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

  // Build the "Add Option" button
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
                  onPressed: () async {
                    final newOptionName = _newOptionController.text.trim();
                    if (newOptionName.isNotEmpty) {
                      final token = await getToken();
                      if (token == null) {
                        _showSnackBar("Authentication token not found.");
                        return;
                      }

                      // Show a loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      // Prepare the payload
                      Map<String, dynamic> payload = {
                        'name': newOptionName,
                        'description': '',
                        'requiresPhotoUpload': false,
                        'photoUploadPrompt': '',
                        'customFields': [],
                      };

                      try {
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

                        Navigator.of(context, rootNavigator: true)
                            .pop(); // Dismiss loading

                        if (response.statusCode == 201) {
                          final data = json.decode(response.body);
                          final createdOption = OrderOption.fromMap(data);
                          createdOption.isSelected =
                              true; // Ensure it's selected
                          setState(() {
                            selectedOrderOptions[createdOption.name] =
                                createdOption;
                            _photoUploadPromptControllers[createdOption.name] =
                                TextEditingController(
                                    text: createdOption.photoUploadPrompt);
                            _descriptionControllers[createdOption.name] =
                                TextEditingController(
                                    text: createdOption.description);
                            // Optionally, add the new option to categoryDefaultOptions
                            categoryDefaultOptions[widget.category]
                                ?.add(createdOption.name);
                          });

                          _showSnackBar("New option added successfully!");
                          _newOptionController.clear(); // Clear the input field

                          // Refresh the list by re-fetching from backend
                          await _fetchStoreSpecialOrderOptions();
                        } else {
                          _showSnackBar("Failed to add new option.");
                        }
                      } on http.ClientException catch (e) {
                        Navigator.of(context, rootNavigator: true)
                            .pop(); // Dismiss loading
                        _showSnackBar("Client error: ${e.message}");
                      } on TimeoutException {
                        Navigator.of(context, rootNavigator: true)
                            .pop(); // Dismiss loading
                        _showSnackBar("Request timed out. Please try again.");
                      } catch (e) {
                        Navigator.of(context, rootNavigator: true)
                            .pop(); // Dismiss loading
                        _showSnackBar("An unexpected error occurred: $e");
                      }
                    }
                    Navigator.pop(context); // Close the dialog
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
          'requiresPhotoUpload': orderOption.requiresPhotoUpload,
          'photoUploadPrompt':
              _photoUploadPromptControllers[optionTitle]?.text ?? '',
          'customFields': orderOption.customFields.map((field) {
            return {
              'id': field.id, // Ensure that 'id' is handled by the backend
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
        };
        print('payload $payload');

        // Determine if the option is new or existing
        bool isNewOption = orderOption.id.isEmpty;

        Uri uri;
        if (isNewOption) {
          // Endpoint to create a new option
          uri = Uri.parse(createStoreSpecialOrderOption);
        } else {
          // Endpoint to update an existing option
          uri = Uri.parse('$updateStoreSpecialOrderOption/${orderOption.id}');
          // Ensure that 'updateStoreSpecialOrderOption' is a base URL without trailing slash
        }

        // Choose POST for creating new options and PUT for updating existing ones
        http.Response response;
        if (isNewOption) {
          response = await http
              .post(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: json.encode(payload),
              )
              .timeout(const Duration(seconds: 10));
        } else {
          response = await http
              .put(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: json.encode(payload),
              )
              .timeout(const Duration(seconds: 10));
        }

        print('response ${response.body}');
        if (response.statusCode == 200 || response.statusCode == 201) {
          // Option created or updated successfully
          final updatedOption = OrderOption.fromMap(json.decode(response.body));
          updatedOption.isSelected = true; // Ensure it's selected
          setState(() {
            selectedOrderOptions[updatedOption.name] = updatedOption;
            _photoUploadPromptControllers[updatedOption.name]?.text =
                updatedOption.photoUploadPrompt;
            _descriptionControllers[updatedOption.name]?.text =
                updatedOption.description;
          });
        } else {
          // Handle failure
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Failed to save option '${orderOption.name}': ${response.reasonPhrase}",
              ),
            ),
          );
          print('Failed to save option ${orderOption.name}: ${response.body}');
        }
      }

      // Dismiss the loading indicator
      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Configurations saved successfully!")),
      );
    } on http.ClientException catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Client error: ${e.message}")),
      );
    } on TimeoutException {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request timed out. Please try again.")),
      );
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtain screen width and height for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Determine padding based on screen size
    final horizontalPadding = screenWidth * 0.05; // 5% of screen width
    final verticalPadding = screenHeight * 0.02; // 2% of screen height

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: screenHeight * 0.1, // 10% of screen height
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
              ).then((_) {
                // Refresh the page after returning from ManageSpecialOrderOptionsPage
                _fetchStoreSpecialOrderOptions();
              });
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
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
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
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildSpecialOrderOptions(),
                SizedBox(height: verticalPadding),
                // Add Option Button
                _buildAddOptionButton(),
                SizedBox(height: verticalPadding),
                // Save Configurations Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                SizedBox(height: verticalPadding),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
