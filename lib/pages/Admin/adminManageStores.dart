import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../configuration/config.dart';

class AdminManageStoresPage extends StatefulWidget {
  const AdminManageStoresPage({super.key});

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
            fontSize: 22,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [myColor.withOpacity(0.9), Colors.blueGrey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : categoriesData != null
                ? ListView.builder(
                    itemCount: categoriesData!.length,
                    itemBuilder: (context, index) {
                      String categoryName =
                          categoriesData!.keys.elementAt(index);
                      List stores = categoriesData![categoryName];

                      return _buildCategorySection(categoryName, stores);
                    },
                  )
                : const Center(
                    child: Text('No data found'),
                  ),
      ),
    );
  }

  Widget _buildCategorySection(String categoryName, List stores) {
    return Card(
      color: myColor2,
      margin: const EdgeInsets.all(10),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        title: Text(
          categoryName,
          style: const TextStyle(
            fontSize: 18,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Card(
        color: myColor2,
        //color: Colors.white70,
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: ClipOval(
            child: store['logo'] != null && store['logo'].isNotEmpty
                ? Image.network(
                    store[
                        'logo'], // Replace with the actual key for the logo URL
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.store,
                        color: myColor,
                        size: 50,
                      ); // Fallback icon if image fails to load
                    },
                  )
                : const Icon(
                    Icons.store,
                    color: myColor,
                    size: 50,
                  ), // Fallback icon if no logo URL is provided
          ),
          title: Text(
            store['storeName'] ?? 'Store Name',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: myColor,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email: ${store['contactEmail'] ?? 'N/A'}',
                style: TextStyle(
                  //fontSize: 18,
                  // fontWeight: FontWeight.bold,
                  color: myColor,
                ),
              ),
              Text(
                'Phone: ${store['phoneNumber'] ?? 'N/A'}',
                style: TextStyle(
                  //fontSize: 18,
                  // fontWeight: FontWeight.bold,
                  color: myColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
