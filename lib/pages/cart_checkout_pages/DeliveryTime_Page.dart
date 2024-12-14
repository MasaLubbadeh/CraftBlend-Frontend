import 'package:flutter/material.dart';
import '../../configuration/config.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DeliveryTimeCheckoutPage extends StatefulWidget {
  @override
  _DeliveryTimeCheckoutPageState createState() =>
      _DeliveryTimeCheckoutPageState();
}

class _DeliveryTimeCheckoutPageState extends State<DeliveryTimeCheckoutPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> cartData = [];
  Map<String, List<Map<String, dynamic>>> groupedCartData = {};
  double totalPrice = 0.0;

  Map<String, DateTime?> selectedDates = {}; // Store selected dates per store
  Map<String, int?> selectedHours = {}; // Store selected hours per store

  @override
  void initState() {
    super.initState();
    fetchCartData();
  }

  Future<void> fetchCartData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(Uri.parse(getCartData), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = List<Map<String, dynamic>>.from(data['cart']['items']);
        setState(() {
          cartData = items;
          groupedCartData = groupByStore();
          totalPrice = calculateCartTotal();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch cart data');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Map<String, List<Map<String, dynamic>>> groupByStore() {
    return cartData.fold({}, (grouped, item) {
      final storeId = item['storeId']['_id'];
      final storeName = item['storeId']['storeName'];
      final storeIcon = item['storeId']['icon'];

      if (!grouped.containsKey(storeId)) {
        grouped[storeId] = [];
      }

      grouped[storeId]!.add({
        ...item,
        'storeName': storeName,
        'storeIcon': storeIcon,
      });
      return grouped;
    });
  }

  double calculateCartTotal() {
    return cartData.fold(
      0.0,
      (sum, item) => sum + (item['totalPriceWithQuantity'] ?? 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Time"),
        backgroundColor: myColor,
      ),
      body: ListView.builder(
        itemCount: groupedCartData.keys.length,
        itemBuilder: (context, index) {
          final storeId = groupedCartData.keys.elementAt(index);
          final storeItems = groupedCartData[storeId]!;

          // Separate "upon order" and normal products
          final uponOrderItems = storeItems
              .where((item) => item['productId']['isUponOrder'] == true)
              .toList();
          final normalItems = storeItems
              .where((item) => item['productId']['isUponOrder'] == false)
              .toList();

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStoreHeader(storeItems.first),
                  const Divider(),
                  if (normalItems.isNotEmpty)
                    _buildProductList(normalItems, "Normal Items"),
                  if (uponOrderItems.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductList(uponOrderItems, "Upon Order Items"),
                        _buildDateAndHourPicker(storeId),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomCheckoutBar(),
    );
  }

  Widget _buildStoreHeader(Map<String, dynamic> storeItem) {
    final storeName = storeItem['storeName'];
    final storeIcon = storeItem['storeIcon'];

    return ListTile(
      leading: storeIcon != null
          ? Image.network(
              storeIcon,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            )
          : const Icon(Icons.store, size: 40),
      title: Text(
        storeName,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProductList(List<Map<String, dynamic>> items, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ...items.map((item) {
          final product = item['productId'];
          return ListTile(
            leading: product['image'] != null
                ? Image.network(
                    product['image'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.image, size: 50),
            title: Text(product['name']),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDateAndHourPicker(String storeId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Choose Delivery Day & Hour:"),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (selectedDate != null) {
                      setState(() {
                        selectedDates[storeId] = selectedDate;
                      });
                    }
                  },
                  child: Text(
                    selectedDates[storeId] != null
                        ? DateFormat('yyyy-MM-dd')
                            .format(selectedDates[storeId]!)
                        : "Select Date",
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _pickHour(context, storeId);
                  },
                  child: Text(
                    selectedHours[storeId] != null
                        ? "${selectedHours[storeId]}:00"
                        : "Select Hour",
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _pickHour(BuildContext context, String storeId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          child: ListView.builder(
            itemCount: 24,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text("${index.toString().padLeft(2, '0')}:00"),
                onTap: () {
                  setState(() {
                    selectedHours[storeId] = index;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomCheckoutBar() {
    return Container(
      color: myColor.withOpacity(.8),
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${totalPrice.toStringAsFixed(2)}₪',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle checkout logic
            },
            style: ElevatedButton.styleFrom(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text(
              'Checkout',
              style: TextStyle(
                color: myColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
