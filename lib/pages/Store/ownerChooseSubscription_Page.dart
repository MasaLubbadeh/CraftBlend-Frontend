import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChooseSubscriptionPage extends StatefulWidget {
  const ChooseSubscriptionPage({super.key});

  @override
  State<ChooseSubscriptionPage> createState() => _ChooseSubscriptionPageState();
}

class _ChooseSubscriptionPageState extends State<ChooseSubscriptionPage> {
  List<dynamic> subscriptionPlans = [];
  dynamic selectedPlan;
  final TextEditingController txtCardNumber = TextEditingController();
  final TextEditingController txtCardMonth = TextEditingController();
  final TextEditingController txtCardYear = TextEditingController();
  final TextEditingController txtCardCode = TextEditingController();
  final TextEditingController txtFirstName = TextEditingController();
  final TextEditingController txtLastName = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionPlans();
  }

  Future<void> _fetchSubscriptionPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse(getSubscriptionPlans),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          subscriptionPlans = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load subscription plans');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _submitSubscription() async {
    if (!_formKey.currentState!.validate() || selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a plan and complete the form')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final cardDetails = {
      'cardNumber': txtCardNumber.text.trim(),
      'expiryMonth': txtCardMonth.text.trim(),
      'expiryYear': txtCardYear.text.trim(),
      'cardCode': txtCardCode.text.trim(),
      'firstName': txtFirstName.text.trim(),
      'lastName': txtLastName.text.trim(),
    };

    final body = {
      'subscriptionPlanId': selectedPlan['_id'],
      'visaCard': cardDetails,
    };

    try {
      final response = await http.post(
        Uri.parse(chooseSubscription),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription added successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to submit: ${json.decode(response.body)['message']}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Subscription Plan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select a Subscription Plan',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: myColor),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Divider(),
                    ...subscriptionPlans.map((plan) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5), // Add spacing between items
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10), // Internal padding
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                              178, 239, 227, 241), // Light background
                          borderRadius:
                              BorderRadius.circular(10), // Rounded edges
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(2, 2), // Shadow position
                            ),
                          ],
                        ),
                        child: RadioListTile<dynamic>(
                          activeColor: myColor,
                          value: plan,
                          groupValue: selectedPlan,
                          title: Row(
                            children: [
                              const Icon(
                                Icons.star_border,
                                color: myColor, // Optional icon
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  plan['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: myColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${plan['price']}₪ for ${plan['duration']} month/s',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          controlAffinity: ListTileControlAffinity
                              .trailing, // Radio on the right
                          onChanged: (value) {
                            setState(() {
                              selectedPlan = value;
                            });
                          },
                        ),
                      );
                    }),
                    const SizedBox(
                      height: 30,
                    ),
                    const Text(
                      'Enter Credit Card Details',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: myColor),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    const Divider(height: 20),
                    _buildTextField(
                      hintText: 'Card Number',
                      controller: txtCardNumber,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a card number';
                        }
                        if (!RegExp(r'^[0-9]{16}$').hasMatch(value)) {
                          return 'Enter a valid 16-digit card number';
                        }
                        return null;
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            hintText: 'Expiry Month (MM)',
                            controller: txtCardMonth,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the expiry month';
                              }
                              if (!RegExp(r'^(0[1-9]|1[0-2])$')
                                  .hasMatch(value)) {
                                return 'Enter a valid month (01-12)';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            hintText: 'Expiry Year (YYYY)',
                            controller: txtCardYear,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the expiry year';
                              }
                              if (!RegExp(r'^[0-9]{4}$').hasMatch(value) ||
                                  int.parse(value) < DateTime.now().year) {
                                return 'Enter a valid year (YYYY)';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(
                      hintText: 'Card Code',
                      controller: txtCardCode,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the card code';
                        }
                        if (!RegExp(r'^[0-9]{3,4}$').hasMatch(value)) {
                          return 'Enter a valid 3 or 4 digit code';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      hintText: 'First Name',
                      controller: txtFirstName,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      hintText: 'Last Name',
                      controller: txtLastName,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    isSubmitting
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _submitSubscription,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: myColor,
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: hintText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
