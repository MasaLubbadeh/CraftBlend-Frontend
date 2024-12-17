import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../configuration/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageDeliveryLocationsPage extends StatefulWidget {
  const ManageDeliveryLocationsPage({super.key});

  @override
  _ManageDeliveryLocationsPageState createState() =>
      _ManageDeliveryLocationsPageState();
}

class _ManageDeliveryLocationsPageState
    extends State<ManageDeliveryLocationsPage> {
  String? token;

  final Map<String, bool> citiesSelection = {}; // Selection state for cities
  final Map<String, TextEditingController> priceControllers =
      {}; // Price inputs
  List<Map<String, dynamic>> cities = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchToken();
    await _fetchCities();
  }

  Future<void> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    if (token == null) {
      print('Token not found. User might not be logged in.');
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    priceControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _fetchCities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        print('Token not found.');
        return;
      }

      // Fetch all cities
      var citiesUrl = Uri.parse(getAllCities);
      var citiesResponse = await http.get(citiesUrl);
      print("citiesResponse:");
      print(citiesResponse.body);
      // Fetch store's delivery cities
      var deliveryCitiesUrl = Uri.parse(getStoreDeliveryCities);
      var deliveryCitiesResponse = await http.get(
        deliveryCitiesUrl,
        headers: {
          'Authorization': 'Bearer ${token}', // Pass user's token
        },
      );
      print("deliveryCitiesResponse:");
      print(deliveryCitiesResponse.body);

      if (citiesResponse.statusCode == 200 &&
          deliveryCitiesResponse.statusCode == 200) {
        final List<dynamic> cityList =
            jsonDecode(citiesResponse.body)['cities'];
        final List<dynamic> deliveryCityList =
            jsonDecode(deliveryCitiesResponse.body)['deliveryCities'];
        print("City List:");
        print(cityList);

        // Print the list of delivery cities with their costs
        print("Delivery City List:");
        print(deliveryCityList);

        setState(() {
          cities = cityList
              .map((city) => {
                    'id': city['_id'].toString(),
                    'name': city['name'] as String,
                  })
              .toList();

          for (var city in cities) {
            var matchingDeliveryCity = deliveryCityList.firstWhere(
              (deliveryCity) =>
                  deliveryCity['cityId'] == city['id'], // Match by city ID
              orElse: () => null, // Return null if no match found
            );

            citiesSelection[city['id']!] = matchingDeliveryCity != null;

            priceControllers[city['id']!] = TextEditingController(
              text: matchingDeliveryCity != null
                  ? matchingDeliveryCity['deliveryCost'].toString()
                  : '', // Set empty string if no match found
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load cities or delivery settings.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching cities: $e')),
      );
    }
  }

  Future<void> _saveDeliverySettings() async {
    // Gather selected cities and their prices
    final selectedCities = citiesSelection.entries
        .where((entry) => entry.value) // Only selected cities
        .map((entry) => {
              "city": entry.key, // City ID
              "deliveryCost":
                  double.tryParse(priceControllers[entry.key]?.text ?? "0") ??
                      0, // Cost
            })
        .toList();

    if (selectedCities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one city.')),
      );
      return;
    }

    try {
      // Send the data to your backend
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token'); // Retrieve user token

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token not found.')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse(updateDeliveryCitiesUrl), // Replace with your API endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"deliveryCities": selectedCities}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery settings updated successfully.'),
          ),
        );
        print("Response: ${response.body}");

        // Pop the page and return to the profile page
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: ${response.body}'),
          ),
        );
        print("Error: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating settings: $e')),
      );
      print("Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'Manage Delivery Locations',
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select the cities you deliver to and set delivery charges.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: cities.length,
                itemBuilder: (context, index) {
                  final city = cities[index];
                  final cityId = city['id']!;
                  final cityName = city['name']!;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: citiesSelection[cityId],
                            onChanged: (value) {
                              setState(() {
                                citiesSelection[cityId] = value!;
                              });
                            },
                            activeColor: myColor,
                          ),
                          Expanded(
                            child: Text(
                              cityName,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          if (citiesSelection[cityId] == true)
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: priceControllers[cityId],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Price",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Save Button
            Center(
              child: ElevatedButton(
                onPressed: _saveDeliverySettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: myColor,
                  padding: const EdgeInsets.symmetric(
                      vertical: 15.0, horizontal: 50.0),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
