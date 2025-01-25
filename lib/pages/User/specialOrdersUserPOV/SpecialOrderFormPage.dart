// lib/pages/special_order_form_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../configuration/config.dart'; // Ensure this path is correct
import '../../../models/custom__field.dart';
import '../../../models/field_option.dart';
import '../../../models/order_option.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/Notifications/notification_helper.dart'; // Adjust the path as needed

class SpecialOrderFormPage extends StatefulWidget {
  final OrderOption option;

  const SpecialOrderFormPage({Key? key, required this.option})
      : super(key: key);

  @override
  _SpecialOrderFormPageState createState() => _SpecialOrderFormPageState();
}

class _SpecialOrderFormPageState extends State<SpecialOrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formData = {};
  bool _isSubmitting = false;
  File? _selectedImage;

  // New State Variables for Price Estimation
  double _estimatedPrice = 0.0;
  double _quantity = 1.0; // Default quantity

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  Future<void> _sendNotificationToStore(
      Map<String, dynamic> specialOrder) async {
    try {
      // Step 1: Retrieve the authentication token
      final token = await _getToken();
      if (token == null) {
        _showSnackBar('Authentication token not found.');
        return;
      }

      // Step 2: Fetch the store owner's user ID
      // Assuming the store owner's user ID is stored in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storeId =
          specialOrder['storeId']; // Ensure 'storeId' is stored during login
      // final storeName = prefs.getString('storeName') ?? 'Your Store';
      print('stor eid $storeId');
      if (storeId == null || storeId.isEmpty) {
        _showSnackBar('Store ID not found.');
        return;
      }

      // Step 3: Fetch the store owner's FCM token from the backend
      final fcmTokenUrl =
          '$getFMCToken?storeId=$storeId'; // Replace with your actual endpoint
      final fcmTokenResponse = await http.get(
        Uri.parse(fcmTokenUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (fcmTokenResponse.statusCode != 200) {
        _showSnackBar('Failed to fetch store FCM token.');
        print('FCM Token Fetch Error: ${fcmTokenResponse.body}');
        return;
      }

      final fcmTokenData = json.decode(fcmTokenResponse.body);
      if (fcmTokenData['tokens'] == null || fcmTokenData['tokens'].isEmpty) {
        _showSnackBar('No FCM token found for the store.');
        return;
      }

      final storeDeviceToken = fcmTokenData['tokens'][0]['fcmToken'];
      print('Store Device Token: $storeDeviceToken');

      // Step 4: Prepare the notification details
      final title = "New Special Order Received!";
      final body =
          "You have received a new special order. Check your orders for more details.";

      // Step 5: Send the notification via Firebase
      await NotificationService.sendNotification(storeDeviceToken, title, body);

      // Step 6: Optionally, log the notification in the backend database
      final addNotificationResponse = await http.post(
        Uri.parse(addNotification), // Replace with your actual endpoint
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'senderId':
              specialOrder['customerId'], // Assuming customerId is available
          'senderType': 'user',
          'recipientId': storeId,
          'recipientType': 'store',
          'title': title,
          'message': body,
          'metadata': {
            'orderId': specialOrder['_id'],
            'status': 'Received',
          },
        }),
      );

      if (addNotificationResponse.statusCode >= 200 &&
          addNotificationResponse.statusCode < 300) {
        print('Notification logged successfully.');
      } else {
        print('Failed to log notification: ${addNotificationResponse.body}');
      }
    } catch (e) {
      _showSnackBar('Error sending notification: $e');
      print('Notification Sending Error: $e');
    }
  }

  void _initializeFormData() {
    widget.option.customFields.forEach((field) {
      switch (field.type) {
        case FieldType.text:
        case FieldType.number:
        case FieldType.date:
          _formData[field.id] = '';
          break;
        case FieldType.dropdown:
          _formData[field.id] = null;
          break;
        case FieldType.checkbox:
          _formData[field.id] = <String>[];
          break;
      }
    });
    if (widget.option.requiresPhotoUpload) {
      _formData['photoUpload'] = null; // Placeholder for photo upload
    }

    // If there's a number field, initialize quantity
    // Assuming only one number field exists for quantity
    widget.option.customFields.forEach((field) {
      if (field.type == FieldType.number) {
        _formData[field.id] = 1.0; // Default quantity
      }
    });

    // Initial Price Calculation
    _calculateEstimatedPrice();
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs
        .getString('token'); // Adjust the key based on your implementation
  }

  // Firebase Image Upload Method
  Future<String?> _uploadImageToFirebase(File image, String optionName) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await FirebaseAuth.instance.signInAnonymously();
        user = FirebaseAuth.instance.currentUser;
        print("Anonymous user signed in: ${user?.uid}");
      }

      String uniqueFileName =
          'special_order_images/${optionName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';

      Reference storageRef =
          FirebaseStorage.instance.ref().child(uniqueFileName);
      UploadTask uploadTask = storageRef.putFile(image);

      TaskSnapshot snapshot = await uploadTask;
      if (snapshot.state == TaskState.success) {
        String downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } else {
        return null;
      }
    } catch (e) {
      _showSnackBar('Image upload failed: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Form is not valid
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
    });

    // Prepare `selectedCustomFields` including labels
    List<Map<String, dynamic>> selectedCustomFields =
        widget.option.customFields.map((field) {
      String fieldId = field.id;
      String label = field.label;
      dynamic value = _formData[field.id];

      // Handle different field types for value
      List<String> selectedOptions = [];
      String customValue = '';

      switch (field.type) {
        case FieldType.dropdown:
          if (value != null) selectedOptions.add(value);
          break;
        case FieldType.checkbox:
          selectedOptions = List<String>.from(value);
          break;
        case FieldType.text:
        case FieldType.date:
        case FieldType.number:
          customValue = value?.toString() ?? '';
          break;
      }

      return {
        "fieldId": fieldId,
        "label": label,
        "selectedOptions": selectedOptions,
        "customValue": customValue,
        "extraCost": field.options
                ?.firstWhere(
                  (option) => selectedOptions.contains(option.value),
                  orElse: () => FieldOption(value: '', extraCost: 0.0),
                )
                .extraCost ??
            0.0,
      };
    }).toList();

    // Prepare payload with user inputs and estimated price
    Map<String, dynamic> payload = {
      'optionId': widget.option.id,
      'selectedCustomFields': selectedCustomFields,
      'estimatedPrice': _estimatedPrice,
      'status': 'Pending',
    };

    // Handle photo upload if required
    if (widget.option.requiresPhotoUpload && _selectedImage != null) {
      String? imageUrl =
          await _uploadImageToFirebase(_selectedImage!, widget.option.name);
      if (imageUrl != null) {
        payload['photoUpload'] = imageUrl;
      } else {
        _showSnackBar('Failed to upload photo.');
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
    }

    try {
      // Replace with your backend's endpoint
      final String url =
          createSpecialOrder; // Ensure `createSpecialOrder` is defined in config.dart

      String? token = await _getToken();
      if (token == null) {
        _showSnackBar('Authentication token not found.');
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      print('Submitting Payload: $payload'); // Debug log to verify payload

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final specialOrder =
            responseData; // Directly assign the entire response

        print('Special Order Response: $specialOrder');
        // Send notification to the store
        await _sendNotificationToStore(specialOrder);
        // Show a stylized confirmation dialog
        showDialog(
          context: context,
          barrierDismissible:
              false, // Prevent dismissal by tapping outside the dialog
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    20.0), // Rounded corners for the entire dialog
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top section with custom background color
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: myColor, // Background color for the first section
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                    ),
                    child: const Text(
                      'Order Submitted',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  // Rest of the dialog
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15.0),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(178, 239, 227,
                          241), // Background color for the lower section
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20.0),
                        bottomRight: Radius.circular(20.0),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Text(
                            'Your special order has been submitted successfully!',
                            style: TextStyle(
                                fontSize: 16,
                                color: myColor,
                                letterSpacing: 0.5),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        const Text(
                          'You will receive a notification once the store owner confirms your order. '
                          'Once confirmed, you can proceed to checkout through your cart under "Scheduled Orders".',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20.0),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                              Navigator.of(context).pop(); // Pop the form page
                              Navigator.of(context)
                                  .pop(); // Pop to the store page
                            },
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                color: myColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        _showSnackBar(
            'Failed to submit order. Status Code: ${response.statusCode} , ${response.body}  ');
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e');
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Price Calculation Method
  void _calculateEstimatedPrice() {
    double subtotal = 0.0;
    double quantity = 1.0;

    widget.option.customFields.forEach((field) {
      switch (field.type) {
        case FieldType.text:
          // Typically, text fields don't affect the price
          break;
        case FieldType.number:
          // Treat as quantity
          double enteredQuantity = _formData[field.id] ?? 1.0;
          if (enteredQuantity <= 0) {
            enteredQuantity = 1.0; // Prevent zero or negative quantities
            _formData[field.id] = enteredQuantity;
          }
          quantity = enteredQuantity;
          break;
        case FieldType.dropdown:
          String? selectedOption = _formData[field.id];
          if (selectedOption != null) {
            FieldOption? option = field.options!.firstWhere(
                (opt) => opt.value == selectedOption,
                orElse: () => FieldOption(value: '', extraCost: 0.0));
            subtotal += option.extraCost;
          }
          break;
        case FieldType.checkbox:
          List<String> selectedOptions = _formData[field.id];
          selectedOptions.forEach((selected) {
            FieldOption? option = field.options!.firstWhere(
                (opt) => opt.value == selected,
                orElse: () => FieldOption(value: '', extraCost: 0.0));
            subtotal += option.extraCost;
          });
          break;
        case FieldType.date:
          // Dates typically don't affect the price
          break;
        default:
          break;
      }
    });

    double estimatedPrice = subtotal * quantity;

    setState(() {
      _estimatedPrice = estimatedPrice;
      _quantity = quantity;
    });
  }

  // Widget builders for different field types
  Widget _buildField(CustomField field) {
    switch (field.type) {
      case FieldType.text:
        return TextFormField(
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.isRequired ? 'Required' : 'Optional',
            labelStyle: TextStyle(color: myColor),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: myColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: myColor, width: 2.0),
            ),
          ),
          validator: (value) {
            if (field.isRequired && (value == null || value.isEmpty)) {
              return 'This field is required.';
            }
            return null;
          },
          onSaved: (value) {
            _formData[field.id] = value ?? '';
            _calculateEstimatedPrice(); // Recalculate on save
          },
        );
      case FieldType.number:
        return TextFormField(
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.isRequired ? 'Required' : 'Optional',
            labelStyle: TextStyle(color: myColor),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: myColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: myColor, width: 2.0),
            ),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (field.isRequired && (value == null || value.isEmpty)) {
              return 'This field is required.';
            }
            if (value != null && value.isNotEmpty) {
              double? parsed = double.tryParse(value);
              if (parsed == null || parsed <= 0) {
                return 'Please enter a valid quantity.';
              }
            }
            return null;
          },
          onChanged: (value) {
            // Update formData and recalculate price on every change
            _formData[field.id] =
                value != null && value.isNotEmpty ? double.parse(value) : 1.0;
            _calculateEstimatedPrice();
          },
          onSaved: (value) {
            _formData[field.id] =
                value != null && value.isNotEmpty ? double.parse(value) : 1.0;
            _calculateEstimatedPrice(); // Recalculate on save
          },
        );
      case FieldType.dropdown:
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.isRequired ? 'Please select' : 'Optional',
            labelStyle: TextStyle(color: myColor),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: myColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: myColor, width: 2.0),
            ),
          ),
          items: field.options!
              .map(
                (option) => DropdownMenuItem(
                  value: option.value,
                  child: Text(
                    option.extraCost != 0
                        ? '${option.value} (+\$${option.extraCost.toStringAsFixed(2)})'
                        : option.value,
                  ),
                ),
              )
              .toList(),
          validator: (value) {
            if (field.isRequired && value == null) {
              return 'Please select an option.';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _formData[field.id] = value;
              _calculateEstimatedPrice();
            });
          },
          onSaved: (value) {
            _formData[field.id] = value;
            _calculateEstimatedPrice(); // Recalculate on save
          },
        );
      case FieldType.checkbox:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: TextStyle(color: myColor, fontSize: 16.0),
            ),
            ...field.options!.map((option) {
              bool isChecked = _formData[field.id].contains(option.value);
              return CheckboxListTile(
                title: Text(
                    '${option.value} (+\$${option.extraCost.toStringAsFixed(2)})'),
                value: isChecked,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _formData[field.id].add(option.value);
                    } else {
                      _formData[field.id].remove(option.value);
                    }
                    _calculateEstimatedPrice();
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),
          ],
        );
      case FieldType.date:
        return TextFormField(
          readOnly: true, // Make the field read-only
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.isRequired ? 'Required' : 'Optional',
            labelStyle: TextStyle(color: myColor),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: myColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: myColor, width: 2.0),
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.calendar_today, color: myColor),
              onPressed: () => _selectDate(field.id),
            ),
          ),
          validator: (value) {
            if (field.isRequired &&
                (_formData[field.id] == null || _formData[field.id].isEmpty)) {
              return 'This field is required.';
            }
            return null;
          },
          controller: TextEditingController(
            text: _formData[field.id] != null && _formData[field.id].isNotEmpty
                ? DateTime.parse(_formData[field.id])
                    .toLocal()
                    .toString()
                    .split(' ')[0]
                : '',
          ),
          onTap: () async {
            await _selectDate(field.id);
            _calculateEstimatedPrice(); // Recalculate after date selection
          },
          onSaved: (value) {
            // Already handled in onTap
            _calculateEstimatedPrice(); // Recalculate on save
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Method to handle date selection
  Future<void> _selectDate(String fieldId) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2101);

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        _formData[fieldId] = pickedDate.toIso8601String();
      });
    }
  }

  // Widget builder for photo upload prompt
  Widget _buildPhotoUploadField() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white70,
          border: Border.all(
            color: myColor,
            width: 2,
          ),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.camera_alt,
                    size: 50,
                    color: myColor,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap to Upload Photo',
                    style: TextStyle(
                      color: myColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Method to pick image from gallery
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _formData['photoUpload'] = image.path; // Temporarily store path
          _calculateEstimatedPrice(); // Recalculate after image selection
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e');
    }
  }

  // Widget to display estimated price and note
  Widget _buildEstimatedPriceSection() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estimated Price Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated Price:',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${_estimatedPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          // Disclaimer Note
          const Text(
            'Note: This is an estimated price. The final price will be provided by the store owner upon confirmation.',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.black54,
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
        title: Text(
          widget.option.name,
          style: const TextStyle(
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
          // Background Image with Opacity
          Opacity(
            opacity: 0.2,
            child: Container(
                /*decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background_form.jpg'),
                  fit: BoxFit.cover,
                ),
              ),*/
                ),
          ),
          // Main Content
          GestureDetector(
            onTap: () => FocusScope.of(context)
                .unfocus(), // Dismiss keyboard on tap outside
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Photo Upload Widget at the Top
                        _buildPhotoUploadField(),
                        const SizedBox(height: 24.0),
                        // Option Description
                        Text(
                          widget.option.description,
                          style: const TextStyle(
                              fontSize: 16.0, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24.0),
                        // Dynamic Fields
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              ...widget.option.customFields
                                  .map((field) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: _buildField(field),
                                      ))
                                  .toList(),
                              const SizedBox(height: 24.0),
                              // Estimated Price and Note
                              //_buildEstimatedPriceSection(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildEstimatedPriceSection(),

                // Submit Button Fixed at the Bottom
                Container(
                  padding: const EdgeInsets.all(16.0),
                  width: double.infinity,
                  color: Colors
                      .white70, // Optional: background color for the button area
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: myColor)
                      : ElevatedButton(
                          onPressed: _submitForm,
                          child: const Text(
                            'Submit Special Order',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: myColor,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 32.0),
                            textStyle: const TextStyle(fontSize: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
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
