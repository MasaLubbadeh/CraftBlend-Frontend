import 'package:craft_blend_project/configuration/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StoreOrdersPage extends StatefulWidget {
  const StoreOrdersPage({Key? key}) : super(key: key);

  @override
  _StoreOrdersPageState createState() => _StoreOrdersPageState();
}

class _StoreOrdersPageState extends State<StoreOrdersPage> {
  late Future<List<dynamic>> _receivedOrders;
  late Future<List<dynamic>> _specialOrders;

  @override
  void initState() {
    super.initState();
    _receivedOrders = fetchOrders('/getReceivedOrders'); // Adjust API endpoint
    _specialOrders = fetchOrders('/getSpecialOrders'); // Adjust API endpoint
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<dynamic>> fetchOrders(String endpoint) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception("Authentication token not found!");
    }

    final response = await http.get(
      Uri.parse(getOrdersByStoreId), // Adjust with appropriate endpoint
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
    print(response.body);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['orders'];
    } else {
      throw Exception('Failed to load orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Main tabs: Received Orders and Special Orders
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
              Tab(text: "Received Orders"),
              Tab(text: "Special Orders"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNestedOrdersTabs(
                _receivedOrders), // Nested tabs for received orders
            _buildNestedOrdersTabs(
                _specialOrders), // Nested tabs for special orders
          ],
        ),
      ),
    );
  }

  Widget _buildNestedOrdersTabs(Future<List<dynamic>> ordersFuture) {
    return DefaultTabController(
      length: 3, // Nested tabs: Pending, In Progress, Shipped, Delivered
      child: Column(
        children: [
          const TabBar(
            labelColor: myColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: myColor,
            tabs: [
              Tab(text: "Pending"),
              //Tab(text: "In Progress"),
              Tab(text: "Shipped"),
              Tab(text: "Delivered"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFilteredOrdersList(ordersFuture, "Pending"),
                //_buildFilteredOrdersList(ordersFuture, "In Progress"),
                _buildFilteredOrdersList(ordersFuture, "Shipped"),
                _buildFilteredOrdersList(ordersFuture, "Delivered"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredOrdersList(
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
          final orders = snapshot.data!
              .where((order) => order['status'] == status)
              .toList();

          if (orders.isEmpty) {
            return Center(child: Text("No $status orders available."));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("Order ID: ${order['_id']}"),
                  subtitle: Text(
                    "Order #: ${order['orderNumber'] ?? 'N/A'}\n" // Use the extracted order number
                    "Status: ${order['status']}\n"
                    "Total: \$${order['totalPrice']}\n"
                    "City: ${order['deliveryDetails']['city']}",
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to detailed order view
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
