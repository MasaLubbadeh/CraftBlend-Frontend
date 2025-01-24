import 'package:craft_blend_project/components/statusBadge.dart';
import 'package:craft_blend_project/configuration/config.dart';
import 'package:craft_blend_project/pages/Product/Pastry/pastryUser_page.dart';
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
  String _selectedStatus = "All"; // Default to showing all orders
  bool _isDropdownVisible = false;

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

  void _toggleDropdownVisibility() {
    setState(() {
      _isDropdownVisible = !_isDropdownVisible;
    });
  }

  void _applyStatusFilter(String status) {
    setState(() {
      _selectedStatus = status;
      _isDropdownVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Filter Row with Title
              Container(
                color: myColor,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    const Text(
                      "Filter by Status:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Dropdown Button
                    GestureDetector(
                      onTap: _toggleDropdownVisibility,
                      child: FilterButton(
                        text: _selectedStatus,
                        isActive: _isDropdownVisible,
                      ),
                    ),
                  ],
                ),
              ),
              // Orders List
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _userOrders,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No orders available."));
                    } else {
                      final filteredOrders =
                          _filterOrdersByStatus(snapshot.data!);
                      return ListView.builder(
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _buildOrderCard(order);
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          // Dropdown Menu
          if (_isDropdownVisible) _buildDropdownMenu(),
        ],
      ),
    );
  }

  List<dynamic> _filterOrdersByStatus(List<dynamic> orders) {
    if (_selectedStatus == "All") {
      return orders;
    }

    return orders.where((order) {
      // Normalize both _selectedStatus and order['status'] to lowercase
      final status = order['status']?.toLowerCase() ?? '';

      // Include "Partially Shipped" with "Shipped"
      if (_selectedStatus.toLowerCase() == "shipped") {
        return status == "shipped" || status == "partially shipped";
      }
      if (_selectedStatus.toLowerCase() == "delivered") {
        return status == "delivered" || status == "partially delivered";
      }

      // Default case: match the selected status
      return status == _selectedStatus.toLowerCase();
    }).toList();
  }

  Widget _buildOrderCard(dynamic order) {
    final bool isDelivered = order['status']?.toLowerCase() == 'delivered';

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
              Row(
                children: [
                  const Text("Status: "),
                  StatusBadge.getBadge(order['status'] ?? 'Unknown'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Total: ${order['totalPrice']?.toStringAsFixed(2) ?? '0.00'} ₪",
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              if (order['paymentDetails'] != null &&
                  order['paymentDetails']['method'] != null)
                Text(
                  "Payment Method: ${order['paymentDetails']['method']}",
                  // style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              const SizedBox(height: 4),
              Text(
                "Order Date: ${DateTime.parse(order['createdAt']).toLocal().toString().split(' ')[0]}",
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              if (isDelivered)
                const Row(
                  children: [
                    Icon(Icons.star, size: 18, color: Colors.amber),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        "You can rate the product and store!",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                        softWrap:
                            true, // Ensures the text wraps to the next line
                        overflow: TextOverflow
                            .visible, // Allows visible overflow if needed
                      ),
                    ),
                  ],
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
              builder: (context) => UserOrderDetailsPage(order: order),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdownMenu() {
    final options = ["All", "Pending", "Shipped", "Delivered"];
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.06,
      left: 0,
      right: 0,
      child: Material(
        elevation: 4,
        color: Colors.white,
        child: ListView(
          shrinkWrap: true,
          children: options.map((option) {
            return ListTile(
              title: Text(
                option == 'Shipped'
                    ? 'Shipped & Partially Shipped'
                    : option == 'Delivered'
                        ? 'Delivered & Partially Delivered'
                        : option,
                style: TextStyle(
                  color: option == _selectedStatus ? myColor : Colors.black,
                  fontWeight: option == _selectedStatus
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              trailing: option == _selectedStatus
                  ? const Icon(Icons.check, color: myColor)
                  : null,
              onTap: () => _applyStatusFilter(option),
            );
          }).toList(),
        ),
      ),
    );
  }
}
