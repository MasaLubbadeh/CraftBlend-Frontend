import '../../../configuration/config.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../productDetails_page.dart';

class PastryPage extends StatefulWidget {
  const PastryPage({super.key});

  @override
  _PastryPageState createState() => _PastryPageState();
}

class _PastryPageState extends State<PastryPage> {
  final String businessName = 'Pastry Delights';
  List<dynamic> pastries = []; // Dynamic list to hold fetched pastries
  bool isLoading = true; // Loading indicator
  String errorMessage = ''; // Error message for display

  @override
  void initState() {
    super.initState();
    _fetchPastries(); // Fetch pastries from the backend
  }

  Future<void> _fetchPastries() async {
    try {
      // Replace with your actual backend URL
      final response = await http.get(Uri.parse(getAllProducts));
      if (response.statusCode == 200) {
        setState(() {
          pastries = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load pastries: ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight, // Responsive height for the AppBar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white70,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          businessName,
          style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            color: Colors.white70,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('$businessName added to your favorites stores')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background image with opacity
          Opacity(
            opacity: 0.2,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      'assets/images/pastry.jpg'), // Background image path
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: myColor),
                  )
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Text(
                          errorMessage,
                          style:
                              const TextStyle(fontSize: 18, color: Colors.red),
                        ),
                      )
                    : ListView.builder(
                        itemCount: pastries.length,
                        itemBuilder: (context, index) {
                          final pastry = pastries[index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Pastry Image
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      image: const DecorationImage(
                                        image: AssetImage(
                                            'assets/images/pastry.jpg'), // Static image for now
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Pastry details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Pastry title
                                        Text(
                                          pastry[
                                              'name'], // Use 'name' from the backend
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        // Price
                                        Text(
                                          '${pastry['price'].toStringAsFixed(2)} ₪', // Format price
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Arrow button
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward),
                                    color: myColor,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DetailPage(
                                              product:
                                                  pastry), // Pass the product
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
