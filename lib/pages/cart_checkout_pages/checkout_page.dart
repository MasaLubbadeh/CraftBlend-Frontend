import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:craft_blend_project/configuration/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../User/addCard.dart';
import '../../navigationBars/UserBottomNavigationBar.dart';

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
  Map<String, List<Map<String, dynamic>>> storeDeliveryCities = {};
// Store delivery cities by storeId
  bool isEditingPhoneNumber = false; // Add this at the class level
  bool isScheduleSectionExpanded = true;
  bool isCityValid = true; // Flag to track city validation status
  late double deliveryCost;
  String _deliveryPreference = "Deliver All Together"; // Default preference

  @override
  void dispose() {
    phoneNumberController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchStoreDeliveryCities();
    _fetchCities();
    _fetchContactNumber();
    _fetchCreditCards();
    _loadSavedCity();
  }

  Future<void> _loadSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('selectedLocation');
    print('savedCity');

    print(savedCity);
    if (savedCity != null) {
      setState(() {
        selectedCity = savedCity;
      });
      // Validate the saved city after all cities are fetched
      //  WidgetsBinding.instance.addPostFrameCallback((_) {
      await _fetchStoreDeliveryCities();
      _validateSelectedCity(savedCity);
      // });
    }
  }

  Future<void> _fetchStoreDeliveryCities() async {
    final storeIds = widget.cartItems
        .map((item) => item['storeId']['_id'])
        .toSet(); // Get unique store IDs

    // Create a list of futures for fetching delivery cities
    List<Future<void>> fetchTasks = [];

    for (var storeId in storeIds) {
      fetchTasks.add(http
          .get(Uri.parse('$getStoreDeliveryCitiesByID/$storeId'))
          .then((response) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Extract city names
          final cities = data['deliveryCities']
              .map<Map<String, dynamic>>((city) => {
                    'cityName': city['cityName'],
                    'deliveryCost': city['deliveryCost'],
                  })
              .toList();

          storeDeliveryCities[storeId] = cities;
        } else {
          storeDeliveryCities[storeId] =
              []; // Default to empty if an error occurs
        }
      }));
    }

    // Wait for all fetch tasks to complete
    await Future.wait(fetchTasks);

    // Now validate the selected city after all data is fetched
    /*if (selectedCity != null) {
      _validateSelectedCity(selectedCity!);
    }*/
  }

  void _validateSelectedCity(String selectedCity) {
    Set<String> failingStores = {}; // Track stores that don't deliver

    for (var item in widget.cartItems) {
      print('Processing item: $item'); // Print the entire cart item

      final storeId = item['storeId']['_id']; // Get the store ID
      print('Store ID: $storeId'); // Print the store ID

      final storeCities =
          storeDeliveryCities[storeId] ?? []; // Get cities for the store
      print(
          'Delivery cities for store $storeId: $storeCities'); // Print cities for the store

      // Check if the selected city exists in the delivery cities for the store
      final deliversToCity =
          storeCities.any((city) => city['cityName'] == selectedCity);
      if (!deliversToCity) {
        print("failingStores.add(item['storeId']['storeName'])");
        print(item['storeId']['storeName']);
        failingStores.add(item['storeId']['storeName']);
      }
    }

    if (failingStores.isNotEmpty) {
      // Update validation flag
      setState(() {
        isCityValid = false;
        this.selectedCity = null; // Reset selected city
      });

      // Notify the user
      String message;
      if (failingStores.length == 1) {
        message =
            'Unfortunately, ${failingStores.first} does not deliver to $selectedCity.';
      } else {
        final storeList = failingStores.join(', ');
        message =
            'Unfortunately, the following stores do not deliver to $selectedCity: $storeList.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } else {
      // Update validation flag
      setState(() {
        isCityValid = true;
        this.selectedCity = selectedCity;
      });
    }
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

//This function calculates the total delivery cost across all stores for the selected city.
  // Function to calculate total delivery cost across all stores
  double _calculateDeliveryCosts(String selectedCity) {
    double totalDeliveryCost = 0.0;
    final Set<String> processedStores = {}; // To track processed store IDs

    for (var item in widget.cartItems) {
      final storeId = item['storeId']['_id'];

      // Skip this store if it has already been processed
      if (processedStores.contains(storeId)) {
        continue;
      }

      final storeCities = storeDeliveryCities[storeId] ?? [];

      // Find the city's delivery cost for the store
      final cityData = storeCities.firstWhere(
        (city) => city['cityName'] == selectedCity,
        orElse: () => {}, // Return an empty map
      );

      if (cityData.isNotEmpty) {
        final deliveryCost = (cityData['deliveryCost'] ?? 0).toDouble();
        totalDeliveryCost += deliveryCost;
      }

      // Mark this store as processed
      processedStores.add(storeId);
    }

    return totalDeliveryCost;
  }

  Map<String, double> _getDeliveryCostsByStore(String selectedCity) {
    Map<String, double> deliveryCostsByStore = {};
    final Set<String> processedStores = {}; // To track processed store IDs

    for (var item in widget.cartItems) {
      final storeId = item['storeId']['_id'];
      final storeName = item['storeId']['storeName'];

      // Skip this store if it has already been processed
      if (processedStores.contains(storeId)) {
        continue;
      }

      final storeCities = storeDeliveryCities[storeId] ?? [];

      // Find the city's delivery cost for the store
      final cityData = storeCities.firstWhere(
        (city) => city['cityName'] == selectedCity,
        orElse: () => {}, // Return an empty map
      );

      if (cityData.isNotEmpty) {
        final deliveryCost = (cityData['deliveryCost'] ?? 0).toDouble();
        deliveryCostsByStore[storeId] = deliveryCost; // Store by storeId
      }

      // Mark this store as processed
      processedStores.add(storeId);
    }

    return deliveryCostsByStore;
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;
    print('widget.cartItems');
    print(widget.cartItems);
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
            _buildDeliveryPreferenceSection(),
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

  bool _shouldShowDeliveryPreference() {
    // Check if the checkout type is "scheduled"
    if (widget.type != 'scheduled') return false;

    // Ensure there is more than one item
    if (widget.cartItems.length <= 1) return false;

    // Check if at least one item is "upon order"
    bool hasUponOrder = widget.cartItems.any((item) {
      return item['productId']['isUponOrder'] ?? false;
    });

    return hasUponOrder;
  }

  Widget _buildDeliveryPreferenceSection() {
    if (!_shouldShowDeliveryPreference()) {
      return const SizedBox
          .shrink(); // Return an empty widget if not applicable
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Preference',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        Divider(),
        const SizedBox(height: 10),

        // Deliver Together Option
        _buildDeliveryOption('Deliver All Together', 'Deliver All Together'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
          child: Text(
            'For each store, products will be delivered together after the longest preparation time.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),

        // Deliver When Ready Option
        _buildDeliveryOption('Deliver When Ready', 'Deliver When Ready'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
          child: Text(
            'Products will be delivered as soon as they are ready. This may result in higher delivery costs.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        _buildCustomDivider(),

        const SizedBox(
          height: 15,
        ),
      ],
    );
  }

  Widget _buildDeliveryOption(String title, String value) {
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
        groupValue: _deliveryPreference,
        title: Text(
          title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500, color: myColor),
        ),
        activeColor: myColor,
        controlAffinity:
            ListTileControlAffinity.trailing, // Radio button on right
        onChanged: (val) => setState(() => _deliveryPreference = val!),
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
        .where((item) =>
            item['productId']['allowDeliveryDateSelection'] == true &&
            item['productId']['deliveryType'] == 'scheduled')
        .toList();

    if (uponOrderItems.isEmpty) {
      return SizedBox.shrink(); // Returns an empty widget
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
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Please select a date and time for items that allow scheduled delivery.',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                  letterSpacing: .5),
            ),
          ),
          _buildCustomDivider(),
        ],
        const SizedBox(
          height: 15,
        ),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const Divider(),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: selectedCity, // Preselected value from prefs if available
          decoration: const InputDecoration(
            labelText: 'City',
            border: OutlineInputBorder(),
          ),
          items: cities.map((city) {
            return DropdownMenuItem(
              value: city,
              child: Text(city),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedCity = value;
              });
              _validateSelectedCity(value); // Validate the selected city
            }
          },
        ),
        if (!isCityValid) // Show error message when isCityValid is false
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'One or more stores in your cart do not deliver to the selected city.',
              style: TextStyle(
                color: Colors.red[300],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        const SizedBox(height: 10),
        TextField(
          controller: streetController,
          decoration: const InputDecoration(
            labelText: 'Street Details',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '* Delivery may not be available in some cities',
          style: TextStyle(fontSize: 14, color: Colors.black54),
          textAlign: TextAlign.center,
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
    deliveryCost =
        selectedCity != null ? _calculateDeliveryCosts(selectedCity!) : 0.0;
    print('deliveryCost');

    print(deliveryCost);
    print('selectedCity');
    print(selectedCity);

    Map<String, double> deliveryCostsByStore =
        selectedCity != null ? _getDeliveryCostsByStore(selectedCity!) : {};

    print('deliveryCostsByStore');

    print(deliveryCostsByStore);
    Map<String, Map<String, double>> storeTotals = {};
    Map<String, String> storeIdToName = {}; // Map to store ID-to-name mapping

    for (var item in widget.cartItems) {
      final storeId = item['storeId']['_id'];
      final storeName = item['storeId']['storeName'];
      final productTotal = item['totalPriceWithQuantity'];

      // Populate storeId-to-name map
      storeIdToName[storeId] = storeName;

      if (!storeTotals.containsKey(storeId)) {
        storeTotals[storeId] = {
          "productsTotal": 0,
          "deliveryCost": deliveryCostsByStore[storeId] ?? 0,
          "grandTotal": 0,
        };
      }

      storeTotals[storeId]!["productsTotal"] =
          (productTotal ?? 0) + (storeTotals[storeId]!["productsTotal"] ?? 0);

      storeTotals[storeId]!["grandTotal"] =
          (storeTotals[storeId]!["productsTotal"] ?? 0) +
              (storeTotals[storeId]!["deliveryCost"] ?? 0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Order Summary",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        ...storeTotals.entries.map((entry) {
          final storeId = entry.key;
          final totals = entry.value;
          final storeName = storeIdToName[storeId] ?? 'Unknown Store';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                storeName,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Column(
                  children: [
                    _buildSummaryRow('Products Total',
                        '${totals["productsTotal"]!.toStringAsFixed(2)}₪',
                        isLight: true),
                    _buildSummaryRow('Delivery Cost',
                        '${totals["deliveryCost"]!.toStringAsFixed(2)}₪',
                        isLight: true),
                    _buildSummaryRow('Grand Total',
                        '${totals["grandTotal"]!.toStringAsFixed(2)}₪',
                        isBold: true),
                  ],
                ),
              ),
              const Divider(),
            ],
          );
        }),
        _buildSummaryRow(
          'Overall Total',
          '${(widget.total + deliveryCost).toStringAsFixed(2)}₪',
          isBold: true,
        ),
      ],
    );
  }

// Helper widget to build rows in the summary
  Widget _buildSummaryRow(String title, String value,
      {bool isBold = false, bool isLight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: (title == "Overall Total") ? 18 : 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
              color: isLight
                  ? Colors.black54
                  : Colors.black, // Use black for normal, black54 for light
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: (title == "Overall Total") ? 18 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
              color: isLight ? Colors.black54 : Colors.black, // Same logic here
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reduceProductQuantities() async {
    final token = await _fetchToken(); // Fetch authentication token
    if (token == null) return;

    for (var item in widget.cartItems) {
      final product = item['productId'];
      final isUponOrder =
          product['isUponOrder'] ?? false; // Check if "upon order"
      final quantityToReduce =
          item['quantity'] ?? 1; // Use cart quantity, default to 1

      if (!isUponOrder) {
        final productId = product['_id'];
        final reduceQuantityUrl = '$reduceProductQuantity/$productId';

        try {
          final response = await http.put(
            Uri.parse(reduceQuantityUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json
                .encode({'quantity': quantityToReduce}), // Pass the quantity
          );

          if (response.statusCode == 200) {
            print(
                'Product quantity reduced successfully for product: $productId by $quantityToReduce');
          } else {
            print(
                'Failed to reduce quantity for product: $productId. Status Code: ${response.statusCode}');
          }
        } catch (e) {
          print('Error reducing quantity for product $productId: $e');
        }
      }
    }
  }

  bool _isPlaceOrderButtonEnabled() {
    bool allScheduledItemsValid = widget.cartItems.every((item) {
      if (item['productId']['allowDeliveryDateSelection'] == true &&
          item['productId']['deliveryType'] == 'scheduled') {
        return item['selectedDate'] != null && item['selectedTime'] != null;
      }
      return true;
    });

    return isCityValid &&
        selectedCity != null &&
        streetController.text.isNotEmpty &&
        selectedPaymentMethod != null &&
        contactNumber != null &&
        contactNumber!.isNotEmpty &&
        allScheduledItemsValid;
  }

  Widget _buildPlaceOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isPlaceOrderButtonEnabled()
            ? () async {
                print('Placing Order...');

                try {
                  // Proceed to place the order
                  await _placeOrder();

                  // Show success modal on successful order placement
                  _showThankYouModal(context);
                } catch (e) {
                  // Handle errors gracefully
                  print('Error placing order: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to place order: $e')),
                  );
                }
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

  Future<void> _placeOrder() async {
    final token = await _fetchToken(); // Fetch authentication token
    if (token == null) return;

    Map<String, double> deliveryCostsByStore =
        selectedCity != null ? _getDeliveryCostsByStore(selectedCity!) : {};

    // Group items by store and calculate totals
    Map<String, Map<String, dynamic>> groupedStores = {};

    for (var item in widget.cartItems) {
      final storeId = item['storeId']['_id'];
      final storeName = item['storeId']['storeName'];
      final productTotal = item['totalPriceWithQuantity'] ?? 0.0;
      final deliveryCost = deliveryCostsByStore[storeId] ?? 0.0;

      if (!groupedStores.containsKey(storeId)) {
        groupedStores[storeId] = {
          "storeName": storeName,
          "items": [],
          "productsTotal": 0.0,
          "deliveryCost": deliveryCost,
          "grandTotal": 0.0,
        };
      }

      // Add the item to the store's list
      groupedStores[storeId]!["items"].add(item);

      // Accumulate the products' totals
      groupedStores[storeId]!["productsTotal"] += productTotal;
    }

    // Calculate grand totals for each store
    groupedStores.forEach((storeId, storeData) {
      storeData["grandTotal"] =
          storeData["productsTotal"] + storeData["deliveryCost"];
    });

    // Prepare the items for the backend
    List<Map<String, dynamic>> items = [];
    groupedStores.forEach((storeId, storeData) {
      for (var item in storeData["items"]) {
        items.add({
          "productId": item["productId"]["_id"],
          "storeId": storeId,
          "quantity": item["quantity"],
          "pricePerUnitWithOptionsCost": item["pricePerUnitWithOptionsCost"],
          "totalPriceWithQuantity": item["totalPriceWithQuantity"],
          "selectedOptions": item["selectedOptions"],
          "deliveryType": item["productId"]["deliveryType"],
          if (item["productId"]["allowDeliveryDateSelection"] == true) ...{
            "timePickingAllowed": true,
            "selectedDate": (item["selectedDate"] as DateTime?)
                ?.toIso8601String(), // Convert DateTime to ISO string
            "selectedTime": item["selectedTime"]
                ?.format(context), // Use TimeOfDay's format method
          },
          "storeTotal": storeData["productsTotal"],
          "storeDeliveryCost": storeData["deliveryCost"],
        });
      }
    });

    Map<String, dynamic> orderData = {
      "items": items,
      "totalPrice": widget.total + deliveryCost, // Overall total
      "deliveryDetails": {
        "city": selectedCity,
        "street": streetController.text,
        "contactNumber": contactNumber,
      },
      "status": "Pending",
      "deliveryPreference": _deliveryPreference,
    };

    try {
      final response = await http.post(
        Uri.parse(placeOrder), // Replace with your API URL
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(orderData),
      );

      if (response.statusCode == 201) {
        print('Order placed successfully.');
        await _reduceProductQuantities();
        await _refreshCart();
        // _showThankYouModal(context);
      } else {
        print('Failed to place order: ${response.body}');
      }
    } catch (e) {
      print('Error placing order: $e');
    }
  }

  Future<void> _refreshCart() async {
    final token = await _fetchToken(); // Get the authentication token
    if (token == null) return;

    try {
      final productIds =
          widget.cartItems.map((item) => item['productId']['_id']).toList();

      final response = await http.delete(
        Uri.parse('$removeCartItem'), // Update endpoint to handle batch delete
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'productIds': productIds}),
      );

      if (response.statusCode == 200) {
        print('Removed products from cart successfully.');
      } else {
        print(
            'Failed to remove products from cart. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error refreshing cart: $e');
    }
  }

  Future<void> _showThankYouModal(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Prevent dismissing the modal by tapping outside
      enableDrag: false, // Prevent dismissing the modal by dragging
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.6, // Set the height to 60% of the screen
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thank You Illustration
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.4, // Upper half
                child: Image.asset(
                  'assets/images/ThankYouCard.jpg', // Add your custom image
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Subtext
                    const Text(
                      'Your order is now being processed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Thank you for shopping with us!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Back to Home Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const UserBottomNavigationBar(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: myColor.withOpacity(.7),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Back To Home',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
