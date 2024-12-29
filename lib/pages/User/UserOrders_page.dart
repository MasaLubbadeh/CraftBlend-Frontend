import 'package:craft_blend_project/configuration/config.dart';
import 'package:craft_blend_project/pages/User/userDetailedOrder_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({Key? key}) : super(key: key);

  @override
  _UserOrdersPageState createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> {
  late Future<List<dynamic>> _userOrders;

  @override
  void initState() {
    super.initState();
    _userOrders = fetchUserOrders('/getUserOrders'); // Adjust API endpoint
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<dynamic>> fetchUserOrders(String endpoint) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception("Authentication token not found!");
    }

    final response = await http.get(
      Uri.parse(getUserOrders), // Use appropriate base URL and endpoint
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['orders'];
    } else {
      throw Exception('Failed to load user orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return DefaultTabController(
      length: 3, // Main tabs: Pending, Shipped, Delivered
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: appBarHeight,
          automaticallyImplyLeading: true,
          title: const Text(
            "My Orders",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          backgroundColor: myColor,
          centerTitle: true,
          bottom: const TabBar(
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                color: Colors.white,
                width: 2.0,
              ),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Pending"),
              Tab(text: "Shipped"),
              Tab(text: "Delivered"),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: TabBarView(
          children: [
            _buildFilteredOrdersList(_userOrders, "Pending"),
            _buildFilteredOrdersList(_userOrders, "Shipped"),
            _buildFilteredOrdersList(_userOrders, "Delivered"),
          ],
        ),
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
                      Icons.shopping_cart,
                      color: myColor,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    "Order #: ${order['userOrderNumber'] ?? 'N/A'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
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
                          "Total: \$${order['totalPrice']?.toStringAsFixed(2) ?? '0.00'}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "City: ${order['deliveryDetails']['city'] ?? 'N/A'}",
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
                    print(
                        "Navigating to details with order: ${jsonEncode(order)}");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserOrderDetailsPage(order: order),
                      ),
                    );
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
