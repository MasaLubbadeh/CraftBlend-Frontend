import 'package:craft_blend_project/config.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MaterialApp(home: AddCardView()));

class AddCardView extends StatefulWidget {
  const AddCardView({super.key});

  @override
  State<AddCardView> createState() => _AddCardViewState();
}

class _AddCardViewState extends State<AddCardView> {
  TextEditingController txtCardNumber = TextEditingController();
  TextEditingController txtCardMonth = TextEditingController();
  TextEditingController txtCardYear = TextEditingController();
  TextEditingController txtCardCode = TextEditingController();
  TextEditingController txtFirstName = TextEditingController();
  TextEditingController txtLastName = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool isLoading = false; // Track the loading state

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Card')),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        width: media.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Add Credit/Debit Card Details",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      icon: Icon(
                        Icons.close,
                        color: Colors.black,
                        size: 25,
                      ),
                    ),
                  ],
                ),
                Divider(color: Colors.grey.withOpacity(0.4), height: 1),
                const SizedBox(height: 15),
                _buildTextField(
                  hintText: "Card Number",
                  controller: txtCardNumber,
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a card number'
                      : !RegExp(r'^[0-9]{16}$').hasMatch(value)
                          ? 'Enter a valid 16-digit card number'
                          : null,
                ),
                const SizedBox(height: 15),
                _buildExpiryRow(),
                const SizedBox(height: 15),
                _buildTextField(
                  hintText: "Card Security Code",
                  controller: txtCardCode,
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter the security code'
                      : !RegExp(r'^[0-9]{3,4}$').hasMatch(value)
                          ? 'Enter a valid 3 or 4 digit code'
                          : null,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  hintText: "First Name",
                  controller: txtFirstName,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your first name'
                      : null,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  hintText: "Last Name",
                  controller: txtLastName,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your last name'
                      : null,
                ),
                const SizedBox(height: 25),
                isLoading
                    ? CircularProgressIndicator() // Show loading indicator
                    : _buildSubmitButton(media),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function for building text fields
  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return RoundTextfield(
      hintText: hintText,
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  // Helper function for building expiry row
  Row _buildExpiryRow() {
    return Row(
      children: [
        Text(
          "Expiry",
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 100,
          child: _buildTextField(
            hintText: "MM",
            controller: txtCardMonth,
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty
                ? 'Field Required'
                : !RegExp(r'^(0[1-9]|1[0-2])$').hasMatch(value)
                    ? 'Syntax: MM'
                    : null,
          ),
        ),
        const SizedBox(width: 25),
        SizedBox(
          width: 100,
          child: _buildTextField(
            hintText: "YYYY",
            controller: txtCardYear,
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty
                ? 'Field Required'
                : !RegExp(r'^[0-9]{4}$').hasMatch(value) ||
                        int.parse(value) < DateTime.now().year
                    ? 'Syntax: YYYY'
                    : null,
          ),
        ),
      ],
    );
  }

  // Helper function for the submit button
  Widget _buildSubmitButton(Size media) {
    return SizedBox(
      width: media.width * 0.6,
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            setState(() {
              isLoading = true; // Set loading to true
            });

            // Collect the card details
            var cardDetails = {
              'cardNumber': txtCardNumber.text,
              'expiryMonth': txtCardMonth.text,
              'expiryYear': txtCardYear.text,
              'cardCode': txtCardCode.text,
              'firstName': txtFirstName.text,
              'lastName': txtLastName.text,
            };

            // Retrieve token from SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            final String? token =
                prefs.getString('token'); // Retrieve the stored token

            if (token != null) {
              // Make an API call to save the card details (assuming you've set up an API endpoint)
              try {
                var response = await http.post(
                  Uri.parse(addCreditCard),
                  body: jsonEncode({'visaCard': cardDetails}),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $token', // Add the token here
                  },
                );
                print("add credit Response status: ${response.statusCode}");
                print("Response body: ${response.body}");
                if (response.statusCode == 200) {
                  setState(() {
                    isLoading = false;
                  });
                  Navigator.pop(context, true); // Return success
                } else {
                  setState(() {
                    isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add card details')),
                  );
                }
              } catch (e) {
                setState(() {
                  isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            } else {
              setState(() {
                isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Token is missing')),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: myColor, // Set your primary color here
          shape: const StadiumBorder(),
        ),
        child: const Text(
          'Add Card',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class RoundTextfield extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;

  const RoundTextfield({
    super.key,
    required this.hintText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(10),
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
