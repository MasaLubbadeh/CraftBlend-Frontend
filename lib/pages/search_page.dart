import 'package:craft_blend_project/pages/Product/Pastry/pastryUser_page.dart';
import 'package:craft_blend_project/pages/Product/productDetails_page.dart';
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
  String selectedSortOrder = 'None'; // Default sort order

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
      print('allStores');
      print(allStores);

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

    if (currentQuery.isEmpty) {
      // Default behavior when no query is provided
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
      // Filter by search query
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

    // Apply the Deliverable filter if it is active
    if (filterDelivery && selectedCity != null) {
      results = results.where((item) {
        final isStore = item.containsKey('storeName');
        if (isStore) {
          // For stores, check if they deliver to the selected city
          final deliveryCities = item['deliveryCities'] as List<dynamic>?;
          return deliveryCities?.any((city) => city['city'] == selectedCity) ??
              false;
        } else {
          // For products, check if the associated store delivers to the selected city
          final storeId = item['store'];
          final store = allStores.firstWhere(
            (store) => store['_id'] == storeId,
            orElse: () => {},
          );
          final deliveryCities = store['deliveryCities'] as List<dynamic>?;
          return deliveryCities?.any((city) => city['city'] == selectedCity) ??
              false;
        }
      }).toList();
    }

    setState(() {
      filteredResults = results;
    });

    print("Delivery Filter: $filterDelivery");
    print("Selected City: $selectedCity");
    print("Filtered Results: ${filteredResults.length}");
  }

  void sortResults() {
    if (selectedSortOrder == 'Price Ascending') {
      filteredResults.sort((a, b) {
        if (a.containsKey('price') && b.containsKey('price')) {
          return (a['price'] as num).compareTo(b['price'] as num);
        }
        return 0; // If no price, keep the same order
      });
    } else if (selectedSortOrder == 'Price Descending') {
      filteredResults.sort((a, b) {
        if (a.containsKey('price') && b.containsKey('price')) {
          return (b['price'] as num).compareTo(a['price'] as num);
        }
        return 0;
      });
    }
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
            fontSize: 25,
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
                            // Toggle between "Stores" and "Both"
                            selectedFilter =
                                selectedFilter == 'Stores' ? 'Both' : 'Stores';
                            updateFilteredResults();
                          });
                        },
                      ),
                      FilterButton(
                        text: 'Products',
                        isSelected: selectedFilter == 'Products',
                        onTap: () {
                          setState(() {
                            // Toggle between "Products" and "Both"
                            selectedFilter = selectedFilter == 'Products'
                                ? 'Both'
                                : 'Products';
                            updateFilteredResults();
                          });
                        },
                      ),
                      FilterButton(
                        text: 'Deliverable',
                        isSelected: filterDelivery,
                        onTap: () {
                          setState(() {
                            filterDelivery = !filterDelivery;
                            updateFilteredResults();
                          });
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: selectedSortOrder != 'None'
                              ? myColor.withOpacity(
                                  .7) // Highlight container when an option is selected
                              : Colors
                                  .grey[200], // Default background for "Sort"
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: Colors.grey,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 1.0),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value:
                                selectedSortOrder, // Ensure this matches an item in the list
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: selectedSortOrder == 'None'
                                  ? Colors.black
                                  : Colors.white,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'None',
                                child: Text(
                                  'Sort', // Visible placeholder
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: selectedSortOrder == 'None'
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Price Ascending',
                                child: Text(
                                  'Price ↑',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: selectedSortOrder != 'None'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Price Descending',
                                child: Text(
                                  'Price ↓',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: selectedSortOrder != 'None'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedSortOrder =
                                    value!; // Update selected option
                                sortResults(); // Call sorting logic
                              });
                            },
                            dropdownColor: selectedSortOrder == 'None'
                                ? Colors.grey[200]
                                : const Color.fromARGB(255, 172, 154,
                                    184), // Background for dropdown menu
                            isDense: true,
                            menuMaxHeight: 200,
                            itemHeight: 50,
                            elevation: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (currentQuery.isEmpty && !filterDelivery)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.trending_up, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            'Most Searched Items',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
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
                        : Expanded(
                            child: filteredResults.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No results found.',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 16),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: filteredResults.length,
                                    itemBuilder: (context, index) {
                                      final item = filteredResults[index];
                                      final isStore = item.containsKey(
                                          'storeName'); // Determine type

                                      return GestureDetector(
                                        onTap: () {
                                          if (isStore) {
                                            // Navigate to PastryPage for stores
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PastryPage(
                                                  storeId: item[
                                                      '_id'], // Assuming `_id` is the store ID
                                                  storeName:
                                                      item['storeName'] ?? '',
                                                ),
                                              ),
                                            );
                                          } else {
                                            // Navigate to DetailPage for products
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailPage(
                                                  product: item,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical:
                                                  10.0), // Add padding for height
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              // Leading Image/Logo
                                              Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10.0),
                                                width: 80, // Increased width
                                                height: 80, // Increased height
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  shape: BoxShape.rectangle,
                                                  image: DecorationImage(
                                                    image: NetworkImage(
                                                      isStore
                                                          ? item['logo'] ?? ''
                                                          : item['image'] ?? '',
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),

                                              // Title, Badge, and Store Information
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      isStore
                                                          ? item['storeName'] ??
                                                              'No Store Name'
                                                          : item['name'] ??
                                                              'No Product Name',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),

                                                    // Store Information for Products
                                                    if (!isStore)
                                                      Row(
                                                        children: [
                                                          // Store Logo
                                                          Container(
                                                            width: 20,
                                                            height: 20,
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    right: 8.0,
                                                                    top: 6.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              image:
                                                                  DecorationImage(
                                                                image:
                                                                    NetworkImage(
                                                                  allStores
                                                                          .firstWhere(
                                                                        (store) =>
                                                                            store['_id'] ==
                                                                            item['store'],
                                                                        orElse:
                                                                            () {
                                                                          print(
                                                                              "Store not found for product: ${item['name']}"); // Debugging
                                                                          return {};
                                                                        },
                                                                      )['logo'] ??
                                                                      '', // Fallback if logo is missing
                                                                ),
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            ),
                                                          ),
                                                          // Store Name
                                                          Text(
                                                            allStores
                                                                    .firstWhere(
                                                                  (store) =>
                                                                      store[
                                                                          '_id'] ==
                                                                      item[
                                                                          'store'],
                                                                  orElse: () {
                                                                    print(
                                                                        "Store not found for product: ${item['name']}"); // Debugging
                                                                    return {};
                                                                  },
                                                                )['storeName'] ??
                                                                'No Store', // Fallback if storeName is missing
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    // Badge for Item Type
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              top: 4.0),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8.0,
                                                          vertical: 4.0),
                                                      decoration: BoxDecoration(
                                                        color: myColor
                                                            .withOpacity(.5),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Text(
                                                        isStore
                                                            ? 'Store'
                                                            : 'Product',
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.white70,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Price for Products
                                              if (!isStore)
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 15),
                                                  child: Text(
                                                    "${item['price'] ?? 'N/A'} ₪", // Assuming `price` is part of product data
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: myColor,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    separatorBuilder: (context, index) =>
                                        const Divider(
                                      color: Colors.grey,
                                      height: 1,
                                      thickness: 0.5,
                                    ),
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
        margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 5.0),
        decoration: BoxDecoration(
          color: isSelected ? myColor.withOpacity(.7) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected ? myColor.withOpacity(.7) : Colors.grey,
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
