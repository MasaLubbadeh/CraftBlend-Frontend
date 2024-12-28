import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../configuration/config.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> allStores = [];
  List<Map<String, dynamic>> filteredResults = [];
  List<Map<String, dynamic>> mostSearchedItems = [];
  bool isLoading = true;
  String selectedFilter = 'Both'; // 'Stores', 'Products', or 'Both'
  String currentQuery = '';
  String? selectedCity; // Store the selected city ID
  bool filterDelivery = false; // Track the delivery filter state

  @override
  void initState() {
    super.initState();
    fetchAllData();
    fetchMostSearchedItems(); // Fetch most searched items at the start
  }

  Future<void> _loadSelectedCity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedCity = prefs.getString('selectedLocationID'); // Get saved city
    });
  }

  Future<void> fetchAllData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load the selected city before fetching data
      await _loadSelectedCity();

      final storeResponse = await http.get(Uri.parse(getAllStores));
      if (storeResponse.statusCode == 200) {
        final decodedStores = json.decode(storeResponse.body);
        allStores = List<Map<String, dynamic>>.from(
            decodedStores['stores'] ?? decodedStores);
      }

      final productResponse = await http.get(Uri.parse(getAllProducts));
      if (productResponse.statusCode == 200) {
        final decodedProducts = json.decode(productResponse.body);
        allProducts = List<Map<String, dynamic>>.from(decodedProducts);
      }

      setState(() {
        updateFilteredResults(); // Update results based on selected filter
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  Future<void> fetchMostSearchedItems() async {
    try {
      final response = await http.get(Uri.parse(getMostSearched));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            mostSearchedItems = [
              ...List<Map<String, dynamic>>.from(data['stores']),
              ...List<Map<String, dynamic>>.from(data['products']),
            ];
          });
        } else {
          throw Exception(
              data['message'] ?? 'Failed to fetch most searched items');
        }
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching most searched items: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load most searched items')),
      );
    }
  }

  void updateFilteredResults() {
    List<Map<String, dynamic>> results = [];

    // Filter by search query
    if (currentQuery.isEmpty) {
      results = selectedFilter == 'Stores'
          ? mostSearchedItems
              .where((item) => item.containsKey('storeName'))
              .toList()
          : selectedFilter == 'Products'
              ? mostSearchedItems
                  .where((item) => item.containsKey('name'))
                  .toList()
              : mostSearchedItems;
    } else {
      results = selectedFilter == 'Stores'
          ? allStores
              .where((store) =>
                  store['storeName']
                      ?.toLowerCase()
                      .contains(currentQuery.toLowerCase()) ??
                  false)
              .toList()
          : selectedFilter == 'Products'
              ? allProducts
                  .where((product) =>
                      product['name']
                          ?.toLowerCase()
                          .contains(currentQuery.toLowerCase()) ??
                      false)
                  .toList()
              : [
                  ...allStores.where((store) =>
                      store['storeName']
                          ?.toLowerCase()
                          .contains(currentQuery.toLowerCase()) ??
                      false),
                  ...allProducts.where((product) =>
                      product['name']
                          ?.toLowerCase()
                          .contains(currentQuery.toLowerCase()) ??
                      false),
                ];
    }

    // Apply delivery filter if enabled
    if (filterDelivery && selectedCity != null) {
      results = results.where((item) {
        final deliveryCities = item['deliveryCities'] as List<dynamic>?;
        final itemCity = item['city']; // Assuming the store has a 'city' field
        final deliversToCity = deliveryCities
                ?.any((deliveryCity) => deliveryCity['city'] == selectedCity) ??
            false;
        final isInSameCity = itemCity == selectedCity;

        return deliversToCity || isInSameCity;
      }).toList();
    }

    setState(() {
      filteredResults = results;
    });

    print("Delivery Filter: $filterDelivery");
    print("Selected City: $selectedCity");
    print("Filtered Results: ${filteredResults.length}");
  }

  void search(String query) {
    setState(() {
      currentQuery = query;
      updateFilteredResults();
    });

    // Update search count for all matches
    for (final item in filteredResults) {
      final isStore = allStores.contains(item);
      //updateSearchCount(item['_id'], isStore ? 'store' : 'product');
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        title: const Text(
          'Search',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        backgroundColor: myColor,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white70,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/searchBackground.jpg'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: myColor),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      onChanged: (value) {
                        search(value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search stores, products...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[200]?.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8.0, // Horizontal spacing between buttons
                    runSpacing:
                        8.0, // Vertical spacing between lines when wrapping
                    alignment: WrapAlignment.center,
                    children: [
                      FilterButton(
                        text: 'Stores',
                        isSelected: selectedFilter == 'Stores',
                        onTap: () {
                          setState(() {
                            selectedFilter = 'Stores';
                            updateFilteredResults();
                          });
                        },
                      ),
                      FilterButton(
                        text: 'Products',
                        isSelected: selectedFilter == 'Products',
                        onTap: () {
                          setState(() {
                            selectedFilter = 'Products';
                            updateFilteredResults();
                          });
                        },
                      ),
                      /*FilterButton(
                        text: 'Both',
                        isSelected: selectedFilter == 'Both',
                        onTap: () {
                          setState(() {
                            selectedFilter = 'Both';
                            updateFilteredResults();
                          });
                        },
                      ),*/
                      FilterButton(
                        text: 'Deliverable',
                        isSelected: filterDelivery,
                        onTap: () {
                          setState(() {
                            filterDelivery = !filterDelivery;
                            print("Delivery Filter: $filterDelivery");
                            updateFilteredResults();
                          });
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: filteredResults.isEmpty
                        ? const Center(
                            child: Text(
                              'No results found.',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredResults.length,
                            itemBuilder: (context, index) {
                              final item = filteredResults[index];
                              final isStore = item.containsKey('storeName');

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    isStore
                                        ? item['logo'] ?? ''
                                        : item['image'] ?? '',
                                  ),
                                ),
                                title: Text(
                                  isStore
                                      ? item['storeName'] ?? 'No Store Name'
                                      : item['name'] ?? 'No Product Name',
                                ),
                                subtitle: Text(isStore ? 'Store' : 'Product'),
                                onTap: () {
                                  if (isStore) {
                                    Navigator.pushNamed(
                                        context, '/storeDetails',
                                        arguments: item);
                                  } else {
                                    Navigator.pushNamed(
                                        context, '/productDetails',
                                        arguments: item);
                                  }
                                },
                              );
                            },
                            separatorBuilder: (context, index) => const Divider(
                              color: Colors.grey,
                              height: 1,
                              thickness: 0.5,
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterButton({
    Key? key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // This should trigger the onTap function
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? myColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected ? myColor : Colors.grey,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
