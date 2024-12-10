import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../configuration/config.dart';
import 'Product/Pastry/pastryUser_page.dart';

class StoresPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const StoresPage(
      {super.key, required this.categoryId, required this.categoryName});

  @override
  _StoresPageState createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  List<Map<String, dynamic>> stores = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStores();
  }

  Future<void> _fetchStores() async {
    try {
      final response = await http
          .get(Uri.parse('$getStoresByCategory/${widget.categoryId}/stores'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          stores = List<Map<String, dynamic>>.from(jsonResponse);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load stores');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching stores: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final store = stores[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 15), // Increased margin
                  color: myColor,
                  elevation: 4,
                  child: Container(
                    height:
                        100, // Set a fixed height for the card to increase size
                    padding:
                        const EdgeInsets.all(8.0), // Padding inside the card
                    child: ListTile(
                      leading: const Icon(
                        Icons.store, // Store icon as leading
                        color: Colors.white,
                        size: 40, // Adjusted icon size for better visibility
                      ),
                      title: Text(
                        store['storeName'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20, // Increased font size for title
                        ),
                      ),
                      subtitle: Text(
                        store['contactEmail'],
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios, // Trailing arrow icon
                        color: Colors.white70,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PastryPage(
                              storeId: store['_id'],
                              storeName: store['storeName'],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
