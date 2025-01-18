import 'package:flutter/material.dart';
import 'package:craft_blend_project/configuration/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/Notifications/notification_helper.dart';
import '../../pages/Store/storeDetailedOrder_page.dart';
import 'storeDetailedSpecialOrders_page.dart';

class StoreOrdersPage extends StatefulWidget {
  const StoreOrdersPage({Key? key}) : super(key: key);

  @override
  _StoreOrdersPageState createState() => _StoreOrdersPageState();
}

class _StoreOrdersPageState extends State<StoreOrdersPage> {
  late Future<List<dynamic>> _regularOrders;
  late Future<List<dynamic>> _specialOrders;

  @override
  void initState() {
    super.initState();
    _regularOrders = fetchRegularOrders(); // Fetch from /getOrdersByStoreId
    _specialOrders = fetchSpecialOrders(); // Fetch from /getStoreSpecialOrders
  }

  /// Retrieves the authentication token from SharedPreferences.
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Fetches Regular Orders from the API.
  Future<List<dynamic>> fetchRegularOrders() async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception("Authentication token not found!");
    }

    final response = await http.get(
      Uri.parse(getOrdersByStoreId),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData['orders'] is List) {
        return jsonData['orders'];
      } else {
        throw Exception("Invalid data format for Regular Orders.");
      }
    } else {
      throw Exception('Failed to load Regular Orders');
    }
  }

  /// Fetches Special Orders from the API.
  Future<List<dynamic>> fetchSpecialOrders() async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception("Authentication token not found!");
    }

    final response = await http.get(
      Uri.parse(getStoreSpecialOrders),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData['specialOrders'] is List) {
        return jsonData['specialOrders'];
      } else {
        throw Exception("Invalid data format for Special Orders.");
      }
    } else {
      throw Exception('Failed to load Special Orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Main tabs: "Regular Orders" and "Special Orders"
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            "Orders",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          backgroundColor: myColor, // Use your custom color
          centerTitle: true,
          bottom: const TabBar(
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                color: Colors.white, // Indicator color
                width: 2.0, // Indicator thickness
              ),
            ),
            labelColor: Colors.white, // Selected tab text color
            unselectedLabelColor: Colors.grey, // Unselected tab text color
            tabs: [
              Tab(text: "Regular Orders"),
              Tab(text: "Special Orders"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRegularOrdersTab(), // Builds the "Regular Orders" main tab
            _buildSpecialOrdersTab(), // Builds the "Special Orders" main tab
          ],
        ),
      ),
    );
  }

  /// Builds the "Regular Orders" main tab with "Instant" and "Scheduled" sub-tabs.
  Widget _buildRegularOrdersTab() {
    return DefaultTabController(
      length: 2, // Sub-tabs: "Instant Orders" and "Scheduled Orders"
      child: Column(
        children: [
          const TabBar(
            labelColor: myColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: myColor,
            tabs: [
              Tab(text: "Instant Orders"),
              Tab(text: "Scheduled Orders"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Instant Orders
                _buildStatusNestedTab(_regularOrders, "instant"),
                // Scheduled Orders
                _buildStatusNestedTab(_regularOrders, "scheduled"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds nested status tabs ("Pending", "Shipped", "Delivered") within each sub-tab.
  Widget _buildStatusNestedTab(
      Future<List<dynamic>> ordersFuture, String deliveryType) {
    return DefaultTabController(
      length: 3, // Status tabs: "Pending", "Shipped", "Delivered"
      child: Column(
        children: [
          const TabBar(
            labelColor: myColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: myColor,
            tabs: [
              Tab(text: "Pending"),
              Tab(text: "Shipped"),
              Tab(text: "Delivered"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFilteredRegularOrdersList(
                    ordersFuture, "Pending", deliveryType),
                _buildFilteredRegularOrdersList(
                    ordersFuture, "Shipped", deliveryType),
                _buildFilteredRegularOrdersList(
                    ordersFuture, "Delivered", deliveryType),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the "Special Orders" main tab with its own nested status tabs.
  Widget _buildSpecialOrdersTab() {
    return DefaultTabController(
      length: 4, // Status tabs: "Pending", "Confirmed", "Shipped", "Delivered"
      child: Column(
        children: [
          const TabBar(
            labelColor: myColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: myColor,
            tabs: [
              Tab(text: "Pending"),
              Tab(text: "Confirmed"),
              Tab(text: "Shipped"),
              Tab(text: "Delivered"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFilteredSpecialOrdersList(_specialOrders, "Pending"),
                _buildFilteredSpecialOrdersList(_specialOrders, "Confirmed"),
                _buildFilteredSpecialOrdersList(_specialOrders, "Shipped"),
                _buildFilteredSpecialOrdersList(_specialOrders, "Delivered"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a filtered list of Regular Orders based on status and delivery type.
  Widget _buildFilteredRegularOrdersList(
      Future<List<dynamic>> ordersFuture, String status, String deliveryType) {
    return FutureBuilder<List<dynamic>>(
        future: ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No $status orders available."));
          } else {
            // Filter orders by storeStatus and orderDeliveryType (case-insensitive)
            final orders = snapshot.data!.where((order) {
              // Retrieve and normalize deliveryType
              final orderDeliveryType =
                  order['orderDeliveryType']?.toString().toLowerCase() ?? '';
              final desiredDeliveryType = deliveryType.toLowerCase();

              if (desiredDeliveryType.isNotEmpty &&
                  orderDeliveryType != desiredDeliveryType) {
                return false; // Skip if the type doesn't match
              }

              // Retrieve and normalize storeStatus
              final items = order['items'] as List<dynamic>;
              if (items.isEmpty) return false; // Skip empty orders
              final itemStatus =
                  items[0]['storeStatus']?.toString().toLowerCase() ?? '';
              final desiredStatus = status.toLowerCase();

              return itemStatus == desiredStatus;
            }).toList();

            if (orders.isEmpty) {
              return Center(child: Text("No $status orders available."));
            }

            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                // Extract storeTotal and storeDeliveryCost from the first item
                final items = order['items'] as List<dynamic>;
                final double storeTotal = items.isNotEmpty
                    ? (items[0]['storeTotal'] ?? 0.0).toDouble()
                    : 0.0;
                final double storeDeliveryCost = items.isNotEmpty
                    ? (items[0]['storeDeliveryCost'] ?? 0.0).toDouble()
                    : 0.0;

                // Extract user's first and last name
                final firstName = order['userId']['firstName'] ?? '';
                final lastName = order['userId']['lastName'] ?? '';
                final userName = "$firstName $lastName".trim();

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 8,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: myColor.withOpacity(0.2),
                      child: const Icon(
                        Icons.receipt_long,
                        color: myColor,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      userName.isNotEmpty ? userName : "N/A",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18, // Slightly smaller than before
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order Number in smaller font
                          Text(
                            "Order #: ${order['orderNumber'] ?? 'N/A'}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Store Status: ${items[0]['storeStatus']}",
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Store Total: ${storeTotal.toStringAsFixed(2)} ₪",
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Delivery Cost: ${storeDeliveryCost.toStringAsFixed(2)} ₪",
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          if (order['paymentDetails'] != null &&
                              order['paymentDetails']['method'] != null)
                            Text(
                              "Payment Method: ${order['paymentDetails']['method']}",
                              style: const TextStyle(fontSize: 14),
                            ),
                        ],
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: myColor.withOpacity(0.7),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailsPage(order: order),
                        ),
                      ).then((result) {
                        if (result == true) {
                          setState(() {
                            _regularOrders =
                                fetchRegularOrders(); // Refresh Regular Orders
                            _specialOrders =
                                fetchSpecialOrders(); // Refresh Special Orders
                          });
                        }
                      });
                    },
                  ),
                );
              },
            );
          }
        });
  }

  /// Builds a filtered list of Special Orders based on status.
  Widget _buildFilteredSpecialOrdersList(
      Future<List<dynamic>> ordersFuture, String status) {
    return FutureBuilder<List<dynamic>>(
      future: ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No $status orders available."));
        } else {
          // Filter Special Orders by status (case-insensitive)
          final orders = snapshot.data!.where((order) {
            final orderStatus = order['status']?.toString().toLowerCase() ?? '';
            final desiredStatus = status.toLowerCase();
            return orderStatus == desiredStatus;
          }).toList();

          if (orders.isEmpty) {
            return Center(child: Text("No $status orders available."));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              // Extract `totalPrice` and `estimatedPrice` directly from the order
              final double totalPrice = (order['totalPrice'] ?? 0.0).toDouble();
              final double estimatedPrice =
                  (order['estimatedPrice'] ?? 0.0).toDouble();

              // Extract customer's first and last name
              final firstName = order['customerId']['firstName'] ?? '';
              final lastName = order['customerId']['lastName'] ?? '';
              final customerName = "$firstName $lastName".trim();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 8,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: myColor.withOpacity(0.2),
                    child: const Icon(
                      Icons.star, // Special icon for Special Orders
                      color: myColor,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    customerName.isNotEmpty ? customerName : "N/A",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18, // Slightly smaller than before
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Status: ${order['status']}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Total Price: ${totalPrice.toStringAsFixed(2)} ₪",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Estimated Price: ${estimatedPrice.toStringAsFixed(2)} ₪",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        if (order['paymentDetails'] != null &&
                            order['paymentDetails']['method'] != null)
                          Text(
                            "Payment Method: ${order['paymentDetails']['method']}",
                            style: const TextStyle(fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: myColor.withOpacity(0.7),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailedSpecialOrderPage(
                          specialOrder: order,
                        ),
                      ),
                    ).then((result) {
                      if (result == true) {
                        setState(() {
                          _regularOrders =
                              fetchRegularOrders(); // Refresh Regular Orders
                          _specialOrders =
                              fetchSpecialOrders(); // Refresh Special Orders
                        });
                      }
                    });
                  },
                ),
              );
            },
          );
        }
      },
    );
  }
}
