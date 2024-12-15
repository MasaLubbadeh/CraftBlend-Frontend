import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:craft_blend_project/configuration/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../User/addCard.dart';

class CheckoutPage extends StatefulWidget {
  final String type; // 'instant' or 'scheduled'
  final double total;
  final List<Map<String, dynamic>> cartItems; // Add cart items parameter

  const CheckoutPage(
      {required this.type,
      required this.total,
      required this.cartItems,
      Key? key})
      : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? selectedCity;
  List<String> cities = [];
  String? contactNumber;
  List<String> creditCards = [];
  String? selectedPaymentMethod;
  final TextEditingController streetController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  bool isEditingPhoneNumber = false; // Add this at the class level
  bool isScheduleSectionExpanded = true;

  @override
  void dispose() {
    phoneNumberController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchCities();
    _fetchContactNumber();
    _fetchCreditCards();
  }

  Future<void> _fetchCities() async {
    final response = await http.get(Uri.parse(getAllCities));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        cities = List<String>.from(data['cities'].map((city) => city['name']));
      });
    }
  }

  Future<String?> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchContactNumber() async {
    final token = await _fetchToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse(getPersonalInfo),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        contactNumber = data['user']['phoneNumber'];
      });
    }
  }

  Future<void> _fetchCreditCards() async {
    final token = await _fetchToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse(getCreditCardData),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final creditCardData = json.decode(response.body);
      if (creditCardData['creditCard'] != null) {
        setState(() {
          creditCards = [
            '**** **** **** ${creditCardData['creditCard']['cardNumber'].substring(12)}'
          ];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        toolbarHeight: appBarHeight,
        title: const Text(
          "Checkout",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.type == 'scheduled') _buildTimePickerSection(),
            const SizedBox(
              height: 15,
            ),
            _buildAddressSection(),
            const SizedBox(
              height: 7,
            ),
            _buildCustomDivider(),
            const SizedBox(
              height: 10,
            ),
            _buildContactNumberSection(),
            const SizedBox(
              height: 10,
            ),
            _buildCustomDivider(),
            const SizedBox(
              height: 10,
            ),
            _buildPaymentMethodSection(),
            const SizedBox(
              height: 10,
            ),
            _buildCustomDivider(),
            const SizedBox(
              height: 12,
            ),
            _buildSummarySection(),
            const SizedBox(
              height: 10,
            ),
            _buildCustomDivider(),
            const SizedBox(
              height: 5,
            ),
            const SizedBox(
              height: 10,
            ),
            _buildPlaceOrderButton(),
            const SizedBox(
              height: 10,
            ),
            if (widget.type == 'instant') _builInstantOrderDeliveryNote(),
            if (widget.type == 'scheduled') _builScheduledOrderDeliveryNote(),
          ],
        ),
      ),
    );
  }

  Widget _builInstantOrderDeliveryNote() {
    return Container(
      alignment: Alignment.center,
      child: const Text(
        "The products will be shipped once your order is placed.",
        style: TextStyle(fontSize: 14, color: Colors.black54),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _builScheduledOrderDeliveryNote() {
    return Container(
      alignment: Alignment.center,
      child: const Text(
        "Note: The delivery time for your items depends on the store's processing and shipping schedule.\n We'll keep you updated once the order is placed.",
        style: TextStyle(fontSize: 14, color: Colors.black54),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCustomDivider() {
    return Center(
      child: Container(
        width:
            MediaQuery.of(context).size.width * .75, // 80% of the screen width
        height: 4, // Adjust thickness
        //color: Colors.grey[400], // Adjust color if needed
        color: myColor.withOpacity(.5),
        margin: const EdgeInsets.symmetric(
            vertical: 10), // Add some vertical spacing
      ),
    );
  }

  Widget _buildTimePickerSection() {
    // Filter cart items to include only "upon order" items
    final uponOrderItems = widget.cartItems
        .where((item) => item['productId']['isUponOrder'] == true)
        .toList();

    if (uponOrderItems.isEmpty) {
      return const Text(
        'No items require scheduling.',
        style: TextStyle(fontSize: 16, color: Colors.black54),
        textAlign: TextAlign.center,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isScheduleSectionExpanded = !isScheduleSectionExpanded;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Schedule Your Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              Icon(
                isScheduleSectionExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        const Divider(),
        if (isScheduleSectionExpanded) ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: uponOrderItems.length,
            itemBuilder: (context, index) {
              final item = uponOrderItems[index];
              final productName =
                  item['productId']['name'] ?? 'Unnamed Product';
              final productImage = item['productId']['image'];
              final timeRequired =
                  item['productId']['timeRequired'] ?? 0; // Time in minutes
              final minDate =
                  DateTime.now().add(Duration(minutes: timeRequired));
              final selectedDate = item['selectedDate'] ?? null;
              final selectedTime = item['selectedTime'] ?? null;

              return Card(
                color: const Color.fromARGB(178, 239, 227, 241),
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: productImage != null
                                    ? NetworkImage(productImage)
                                    : const AssetImage(
                                            'assets/images/pastry.jpg')
                                        as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Picker
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: minDate,
                                    firstDate: minDate,
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 30),
                                    ),
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      item['selectedDate'] = pickedDate;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.date_range,
                                    color: Colors.white70),
                                label: Text(
                                  selectedDate != null
                                      ? "${selectedDate.toLocal()}"
                                          .split(' ')[0]
                                      : "Pick a Date",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: myColor.withOpacity(.6),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Time Picker
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (pickedTime != null) {
                                    setState(() {
                                      item['selectedTime'] = pickedTime;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.access_time,
                                    color: Colors.white70),
                                label: Text(
                                  selectedTime != null
                                      ? "${selectedTime.format(context)}"
                                      : "Pick a Time",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: myColor.withOpacity(.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
        _buildCustomDivider(),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Address',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        Divider(),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: selectedCity,
          decoration: const InputDecoration(
            labelText: 'City',
            border: OutlineInputBorder(),
          ),
          items: cities
              .map((city) => DropdownMenuItem(value: city, child: Text(city)))
              .toList(),
          onChanged: (value) => setState(() => selectedCity = value),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: streetController,
          decoration: const InputDecoration(
            labelText: 'Street Details',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Container(
          child: const Text(
            '* Delivery may not be available in some cities',
            style: TextStyle(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center, // Optional styling
          ),
        ),
      ],
    );
  }

  Widget _buildContactNumberSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Number',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const Divider(),
        const SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * .9,
          height: MediaQuery.of(context).size.width * .15,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          decoration: BoxDecoration(
            color: myColor,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                LineAwesomeIcons.phone,
                color: Colors.white70,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: isEditingPhoneNumber
                    ? TextField(
                        textAlign: TextAlign.start,
                        controller: phoneNumberController,
                        onChanged: (value) {
                          setState(() {
                            contactNumber = value;
                          });
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none, // Remove the border
                          hintText: 'Phone Number',
                          hintStyle: TextStyle(color: Colors.white70),
                        ),
                        cursorColor: Colors.white70,
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600),
                      )
                    : Text(
                        textAlign: TextAlign.start,
                        contactNumber ?? 'Loading...',
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600),
                      ),
              ),
              Center(
                child: IconButton(
                  padding: const EdgeInsets.only(bottom: 1),
                  icon: Icon(
                    isEditingPhoneNumber ? LineAwesomeIcons.save : Icons.edit,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () {
                    if (isEditingPhoneNumber) {
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Update'),
                            content: Text(
                                'Do you want to update your profile phone number to "$contactNumber"?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    isEditingPhoneNumber = false;
                                  });
                                },
                              ),
                              TextButton(
                                child: const Text('Yes'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _savePhoneNumber(
                                      contactNumber!); // Save the number
                                  setState(() {
                                    isEditingPhoneNumber = false;
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      // Start editing
                      phoneNumberController.text =
                          contactNumber ?? ''; // Populate the controller
                      setState(() {
                        isEditingPhoneNumber = true;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'This is the phone number you provided, feel free to change it or use another number.',
          style: TextStyle(fontSize: 14, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _savePhoneNumber(String updatedPhoneNumber) async {
    final token = await _fetchToken();
    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse(getPersonalInfo), // Update the endpoint if needed
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'phoneNumber': updatedPhoneNumber}),
      );

      if (response.statusCode == 200) {
        print('Phone number updated successfully.');
      } else {
        print('Failed to update phone number. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating phone number: $e');
    }
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        Divider(),
        const SizedBox(height: 10),

        // Cash on Delivery Option
        _buildPaymentOption('Cash on Delivery', 'Cash on Delivery', 'cash'),

        // List of Credit Cards
        ...creditCards.isNotEmpty
            ? creditCards.map(
                (card) => _buildPaymentOption(
                  card,
                  '**** **** **** ${card.substring(card.length - 4)}',
                  'visa',
                ),
              )
            : [
                const Text(
                  'No saved credit cards found.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],

        // Apple Pay Option
        _buildPaymentOption('Apple Pay', 'Apple Pay', 'apple pay'),

        // Add New Card Option
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddCardView(),
              ),
            );
            if (result == true) {
              _fetchCreditCards(); // Refresh data if the card was updated
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: myColor,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white70),
                  SizedBox(width: 8),
                  Text(
                    'Add a card',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Paying by card allows you to earn points, which can be redeemed for discounts on future orders.',
          style: TextStyle(fontSize: 14, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String value, String title, String type) {
    // Determine the icon for cards (e.g., Visa, MasterCard)
    Widget cardIcon;
    if (type == 'cash') {
      cardIcon = const Icon(LineAwesomeIcons.cash_register, color: myColor);
    } else if (type == 'visa') {
      cardIcon = const Icon(LineAwesomeIcons.visa_credit_card, color: myColor);
    } else if (type == 'apple pay') {
      cardIcon = const Icon(LineAwesomeIcons.apple_pay, color: myColor);
    } else {
      cardIcon = const Icon(Icons.payment, color: myColor);
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5), // Spacing
      padding: const EdgeInsets.symmetric(horizontal: 5), // Internal padding
      decoration: BoxDecoration(
        color:
            const Color.fromARGB(178, 239, 227, 241), // Light gray background
        borderRadius: BorderRadius.circular(10), // Rounded edges
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: selectedPaymentMethod,
        title: Row(
          children: [
            //if (isCard) ...[
            cardIcon, // Show card icon
            const SizedBox(width: 10), // Add spacing

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500, color: myColor),
              ),
            ),
          ],
        ),
        activeColor: myColor,
        controlAffinity:
            ListTileControlAffinity.trailing, // Radio button on right
        onChanged: (val) => setState(() => selectedPaymentMethod = val),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      children: [
        _buildSummaryRow('Sub Total', '${(widget.total).toStringAsFixed(2)}₪'),
        _buildSummaryRow('Delivery Cost', '10.0₪'),
        _buildSummaryRow('Discount', '0.0₪'),
        const Divider(thickness: 1.5),
        _buildSummaryRow('Total', '${widget.total.toStringAsFixed(2)}₪',
            isBold: true),
      ],
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  bool _isPlaceOrderButtonEnabled() {
    return selectedCity != null &&
        streetController.text.isNotEmpty &&
        selectedPaymentMethod != null &&
        contactNumber != null &&
        contactNumber!.isNotEmpty;
  }

  Widget _buildPlaceOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isPlaceOrderButtonEnabled()
            ? () {
                print('Order Placed');
                // Add your order placement logic here
              }
            : null, // Disable button if conditions are not met
        style: ElevatedButton.styleFrom(
          backgroundColor: _isPlaceOrderButtonEnabled()
              ? myColor
              : myColor.withOpacity(0.5), // Dim color when disabled
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Place Order',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
