import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:craft_blend_project/components/statusBadge.dart';
import 'package:craft_blend_project/configuration/config.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserOrderDetailsPage extends StatefulWidget {
  final dynamic order;

  const UserOrderDetailsPage({Key? key, required this.order}) : super(key: key);

  @override
  _UserOrderDetailsPageState createState() => _UserOrderDetailsPageState();
}

class _UserOrderDetailsPageState extends State<UserOrderDetailsPage> {
  late dynamic order;
  bool hasRated = false; // Track if the user has rated

  @override
  void initState() {
    super.initState();
    assert(widget.order != null, "Order data cannot be null");
    order = widget.order;
    hasRated = order['hasRatedStore'] ?? false; // Add appropriate logic here
  }

  Map<String, dynamic> groupItemsByStore(List<dynamic> items) {
    final Map<String, dynamic> groupedItems = {};

    print("  hasRated: $hasRated");

    for (var item in items) {
      final store = item['storeId'];
      if (store == null || store['_id'] == null) continue;

      final storeId = store['_id'];
      if (!groupedItems.containsKey(storeId)) {
        groupedItems[storeId] = {
          'storeDetails': store,
          'items': [],
          'storeTotal':
              item['storeTotal'] ?? 0.0, // Set the total from the first item
          'deliveryCost': item['storeDeliveryCost'] ??
              0.0, // Set the delivery cost from the first item
        };
      }

      groupedItems[storeId]['items'].add(item);
      //   groupedItems[storeId]['storeTotal'] = item[0]['storeTotal'] ?? 0.0;
      // groupedItems[storeId]['deliveryCost'] =
      //   item[0]['storeDeliveryCost'] ?? 0.0;
    }

    return groupedItems;
  }

  Future<void> _markOrderAsReceived() async {
    try {
      final response = await http.put(
        Uri.parse('$updateOrderStatusUrl/${order['_id']}/markAsReceived'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': 'Delivered'}),
      );

      if (response.statusCode == 200) {
        // Update local order status
        setState(() {
          order['status'] = 'Delivered';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order marked as received!")),
        );
      } else {
        throw Exception('Failed to update order status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void _showRatingModal(
      BuildContext context, dynamic storeDetails, List<dynamic> storeItems) {
    // State for ratings
    List<int> productRatings =
        List.filled(storeItems.length, 0); // Default 0 stars
    int storeRating = 0; // Default store rating is 0 stars

    Future<void> _submitRatings() async {
      final String? token = await _getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication token not found!")),
        );
        return;
      }

      // Prepare store rating data
      // Prepare store rating data
      final storeRatingPayload = {
        "storeId": storeDetails['_id'],
        "storeRating": storeRating,
        "orderId": order['_id'], // Ensure the order ID is included
      };

// Prepare product ratings data
      final productRatingsPayload = {
        "products": List.generate(
          storeItems.length,
          (index) => {
            "productId": storeItems[index]['productId']['_id'],
            "rating": productRatings[index],
          },
        ),
      };

      try {
        // API call for store rating
        print("Submitting store rating payload: $storeRatingPayload");
        final storeResponse = await http.post(
          Uri.parse(rateStore),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(storeRatingPayload),
        );

        print("Store rating response: ${storeResponse.body}");

        if (storeResponse.statusCode != 200) {
          throw Exception("Failed to rate store: ${storeResponse.body}");
        }

        // API call for product ratings
        print("Submitting product ratings payload: $productRatingsPayload");
        final productResponse = await http.post(
          Uri.parse(rateProduct),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(productRatingsPayload),
        );
        print("Product ratings response: ${productResponse.body}");

        if (productResponse.statusCode != 200) {
          throw Exception("Failed to rate products: ${productResponse.body}");
        }
        setState(() {
          hasRated = true;
        });
        // Success message
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thank you for your feedback!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                height: MediaQuery.of(context).size.height * 0.55,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Modal Title
                    const Text(
                      "Rate Store & Products",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: myColor,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Store Rating
                    const Text(
                      "Rate the Store:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: myColor,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => IconButton(
                          icon: Icon(
                            index < storeRating
                                ? Icons.star
                                : Icons.star_border,
                            color: myColor,
                          ),
                          onPressed: () {
                            setState(() {
                              storeRating = index + 1; // Update the rating
                            });
                          },
                        ),
                      ),
                    ),
                    const Divider(thickness: 1),
                    const SizedBox(height: 15),
                    // Product Ratings
                    const Text(
                      "Rate Products:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: myColor,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: storeItems.length,
                        itemBuilder: (context, index) {
                          final item = storeItems[index];
                          final productName =
                              item['productId']['name'] ?? 'Product';
                          final productImage = item['productId']['image'] ?? '';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 8,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: myColor.withOpacity(0.2),
                                      image: productImage.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(productImage),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: productImage.isEmpty
                                        ? const Icon(Icons.image,
                                            size: 40, color: myColor)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8.0),
                                          child: Text(
                                            productName,
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: myColor,
                                                letterSpacing: 1),
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(
                                            5,
                                            (starIndex) => IconButton(
                                              icon: Icon(
                                                starIndex <
                                                        productRatings[index]
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: myColor,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  productRatings[index] =
                                                      starIndex + 1;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 15,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _submitRatings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: myColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const SizedBox(
                        width: double.infinity,
                        child: Center(
                          child: Text(
                            "Submit Rating",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = groupItemsByStore(order['items'] ?? []);
    final double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        toolbarHeight: appBarHeight,
        title: Text(
          "Order Details: #${order['userOrderNumber'] ?? 'N/A'}",
          style: const TextStyle(
            fontSize: 24,
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
        child: ListView(
          children: [
            _buildOrderSummary(groupedItems),
            const SizedBox(height: 20),
            Container(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Order items:",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: myColor,
                    letterSpacing: 1.5),
              ),
            ),
            ...groupedItems.entries.map((entry) {
              final storeId = entry.key;
              final storeData = entry.value;

              return _buildStoreSection(storeData);
            }).toList(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: const Color.fromARGB(171, 243, 229, 245),
      child: ElevatedButton.icon(
        onPressed: () {
          _markOrderAsReceived();
        },
        label: const Text(
          "Mark as Received",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        icon: const Icon(LineAwesomeIcons.check_square, color: Colors.white70),
        style: ElevatedButton.styleFrom(
          backgroundColor: myColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(Map<String, dynamic> groupedStores) {
    return Card(
      color: const Color.fromARGB(171, 243, 229, 245),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Order Summary",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: myColor,
                  letterSpacing: 1.5),
            ),
            const Divider(),
            const SizedBox(height: 5),
            // Display the overall order status
            Text(
              "Status: ${order['status'] ?? 'Unknown'}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 10),
            if (order['paymentDetails'] != null &&
                order['paymentDetails']['method'] != null)
              Text(
                "Payment Method: ${order['paymentDetails']['method']}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black45,
                ),
              ),
            const SizedBox(height: 10),

            ...groupedStores.entries.map((entry) {
              final storeDetails = entry.value['storeDetails'];
              final storeName = storeDetails['storeName'] ?? 'Unknown Store';
              final storeLogo = storeDetails['logo'] ?? '';
              final storeTotal = entry.value['storeTotal'];
              final deliveryCost = entry.value['deliveryCost'];
              final storeStatus = entry.value['items'].isNotEmpty
                  ? entry.value['items'][0]['storeStatus'] ?? 'Unknown'
                  : 'Unknown';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (storeLogo.isNotEmpty)
                      CircleAvatar(
                        backgroundImage: NetworkImage(storeLogo),
                        radius: 20,
                      )
                    else
                      const CircleAvatar(
                        child: Icon(Icons.store, color: myColor),
                        radius: 20,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Text("Store Status: ",
                                  style: TextStyle(fontSize: 14)),
                              StatusBadge.getBadge(storeStatus),
                            ],
                          ),
                          Text(
                            "Store Total: ${storeTotal.toStringAsFixed(2)} ₪",
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            "Delivery Cost: ${deliveryCost.toStringAsFixed(2)} ₪",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreSection(Map<String, dynamic> storeData) {
    final storeDetails = storeData['storeDetails'];
    final storeName = storeDetails['storeName'] ?? 'Unknown Store';
    final storeLogo = storeDetails['logo'] ?? '';
    final storeStatus = storeData['items'].isNotEmpty
        ? storeData['items'][0]['storeStatus'] ?? 'Unknown'
        : 'Unknown';
    final storeItems = storeData['items'];

    return Card(
      color: const Color.fromARGB(171, 243, 229, 245),
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (storeLogo.isNotEmpty)
                  CircleAvatar(
                    backgroundImage: NetworkImage(storeLogo),
                    radius: 20,
                  )
                else
                  const CircleAvatar(
                    child: Icon(Icons.store, color: myColor),
                    radius: 20,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
                StatusBadge.getBadge(storeStatus),
              ],
            ),
            //if (storeStatus = 'Delivered')
            Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: hasRated
                        ? null // Disable button if hasRated is true
                        : () {
                            _showRatingModal(context, storeDetails, storeItems);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          hasRated ? Colors.grey : myColor, // Gray if disabled
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasRated ? "Already Rated" : "Rate Store & Products",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Column(
              children: storeItems
                  .map<Widget>((item) => _buildProductCard(item))
                  .toList(),
            ),
            const SizedBox(height: 10),
            // Add Rate Button
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic item) {
    final product = item['productId'] ?? {};
    final productName = product['name'] ?? 'No Name';
    final productImage = product['image'] ?? '';
    final quantity = item['quantity'] ?? 0;
    final price = item['pricePerUnitWithOptionsCost'] ?? 0.0;

    return Card(
      color: const Color.fromARGB(171, 243, 229, 245),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: myColor.withOpacity(0.2),
                image: productImage.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(productImage),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: productImage.isEmpty
                  ? const Icon(Icons.image, size: 40, color: myColor)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text("Quantity: $quantity"),
                  Text("Price: ${price.toStringAsFixed(2)} ₪"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
