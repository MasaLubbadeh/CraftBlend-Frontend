import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../configuration/config.dart';

class AdminManageStoresPage extends StatefulWidget {
  const AdminManageStoresPage({Key? key}) : super(key: key);

  @override
  _AdminManageStoresPageState createState() => _AdminManageStoresPageState();
}

class _AdminManageStoresPageState extends State<AdminManageStoresPage> {
  Map<String, dynamic>? categoriesData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategoriesAndStores();
  }

  Future<void> _fetchCategoriesAndStores() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token != null) {
      try {
        // Fetch categories and stores
        final response = await http.get(
          Uri.parse(getAllStoresAndCategories), // Replace with your endpoint
          /* headers: {
            'Authorization': 'Bearer $token',
          },*/
        );

        if (response.statusCode == 200) {
          setState(() {
            categoriesData = json.decode(response.body);
            isLoading = false;
          });
        } else {
          print('Error fetching categories and stores: ${response.statusCode}');
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        print('Exception while categories and stores: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      print('Token not found. Cannot fetch categories and stores.');
      setState(() {
        isLoading = false;
      });
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
        title: const Text(
          'Manage Stores',
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
          : categoriesData != null
              ? ListView.builder(
                  itemCount: categoriesData!.length,
                  itemBuilder: (context, index) {
                    String categoryName = categoriesData!.keys.elementAt(index);
                    List stores = categoriesData![categoryName];

                    return _buildCategorySection(categoryName, stores);
                  },
                )
              : const Center(
                  child: Text('No data found'),
                ),
    );
  }

  Widget _buildCategorySection(String categoryName, List stores) {
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        title: Text(
          categoryName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: myColor,
          ),
        ),
        children:
            stores.map<Widget>((store) => _buildStoreCard(store)).toList(),
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: const Icon(Icons.store, color: myColor),
        title: Text(
          store['storeName'] ?? 'Store Name',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${store['contactEmail'] ?? 'N/A'}'),
            Text('Phone: ${store['phoneNumber'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }
}

// Replace this with your actual endpoint URL
const String getCategoriesAndStoresEndpoint = "YOUR_API_ENDPOINT_HERE";

// Replace myColor with your app's main color constant
const Color myColor = Color(0xFF7D648F);
