import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../configuration/config.dart';

class InsightsPage extends StatefulWidget {
  final String userID;

  const InsightsPage({required this.userID});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  bool isLoading = true;
  String? error;

  // Data for store insights
  Map<String, dynamic>? storeInsights;

  @override
  void initState() {
    super.initState();
    _fetchStoreInsights();
  }

  Future<void> _fetchStoreInsights() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$fetchStoreInsights${widget.userID}/insights'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            storeInsights = data['data'];
            isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Failed to fetch insights: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Widget buildProductCard(Map<String, dynamic> product, String title) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: myColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            product['image'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      product['image'],
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: Colors.grey,
                  ),
            const SizedBox(height: 12),
            Text(
              product['name'] ?? 'N/A',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: myColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              product['description'] ?? 'No description available',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Stock: ${product['stock'] ?? 0} (${product['inStock'] ? "In Stock" : "Out of Stock"})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: product['inStock'] ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            if (product['rating'] != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 5),
                  Text(
                    '${product['rating']['average'] ?? 0.0} / 5.0 (${product['rating']['count'] ?? 0} reviews)',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Greeting and description
        if (storeInsights?['storeName'] != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                Text(
                  "Hey, ${storeInsights!['storeName']}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: myColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Welcome to your store insights page. Here, you'll find key performance metrics for your store.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),

        // Store Rating Card
        if (storeInsights?['rating'] != null)
          Card(
            elevation: 6,
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Your store got",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: myColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(seconds: 2),
                    tween: Tween(
                        begin: 0, end: storeInsights!['rating']['average']),
                    builder: (context, value, child) {
                      return Text(
                        value.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Stars",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: myColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        // Number of Received Orders Card
        if (storeInsights?['numberOfReceivedOrders'] != null)
          Card(
            elevation: 6,
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "You Recieved",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: myColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<int>(
                    duration: const Duration(seconds: 2),
                    tween: IntTween(
                        begin: 0,
                        end: storeInsights!['numberOfReceivedOrders']),
                    builder: (context, value, child) {
                      return Text(
                        "$value",
                        style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: myColor,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Orders in total",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: myColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'I N S I G H T S',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    buildInfoCard(),
                    if (storeInsights?['mostSearchedProduct'] != null)
                      buildProductCard(
                        storeInsights!['mostSearchedProduct'],
                        'Your most Searched Product',
                      ),
                    if (storeInsights?['mostOrderedProduct'] != null)
                      buildProductCard(
                        storeInsights!['mostOrderedProduct'],
                        'Your most Ordered Product',
                      ),
                  ],
                ),
    );
  }
}
