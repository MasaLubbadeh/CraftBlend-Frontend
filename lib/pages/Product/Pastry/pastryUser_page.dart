import 'package:craft_blend_project/pages/Store/specialOrders/specialOrder_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../configuration/config.dart';
import '../productDetails_page.dart';
import '../../../components/badge.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PastryPage extends StatefulWidget {
  final String storeId;
  final String storeName;

  const PastryPage({super.key, required this.storeId, required this.storeName});

  @override
  _PastryPageState createState() => _PastryPageState();
}

class _PastryPageState extends State<PastryPage> {
  List<Map<String, dynamic>> pastries = [];
  List<Map<String, dynamic>> filteredPastries = [];
  bool isLoading = true;
  bool _isSearching = false;
  bool _isSorting = false; // New state for sorting dropdown
  bool allowSpecialOrders = false; // Track special orders permission

  bool isFavorite = false;
  String selectedSortOrder = 'Recently Added'; // Default title for sorting
  String activeFilter = ''; // Tracks the active dropdown
  final TextEditingController _searchController = TextEditingController();
  late double appBarHeight;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _fetchPastries();
    _fetchAllowSpecialOrders();
    _addUserViewingStore(); // Log the store view when the page is opened
  }

  Future<String?> _fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _addUserViewingStore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userType = prefs.getString('userType');

      if (userType != 'user') {
        return; // Only log store views for regular users
      }

      final response = await http.post(
        Uri.parse(addStoreView), // Your endpoint from the config
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'storeId': widget.storeId}),
      );

      if (response.statusCode == 200) {
        print('Store view recorded successfully.');
      } else {
        print('Failed to record store view: ${response.statusCode}');
      }
    } catch (error) {
      print('Error recording store view: $error');
    }
  }

  Future<void> _fetchAllowSpecialOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception("Token is missing.");
      }

      final response = await http.get(
        Uri.parse('$checkIfAllowSpecialOrders/${widget.storeId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          allowSpecialOrders =
              jsonResponse['data']['allowSpecialOrders'] ?? false;
        });
      } else {
        throw Exception('Failed to fetch allowSpecialOrders');
      }
    } catch (err) {
      print('Error fetching allowSpecialOrders: $err');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching allowSpecialOrders')),
      );
    }
  }

  Future<void> _fetchPastries() async {
    try {
      final response = await http
          .get(Uri.parse('$getStoreProductsForUser/${widget.storeId}'));
      print(response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
          setState(() {
            pastries = List<Map<String, dynamic>>.from(jsonResponse['data']);
            filteredPastries = pastries;

            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterPastries(String query) {
    List<Map<String, dynamic>> results = pastries;

    if (query.isNotEmpty) {
      results = results
          .where((pastry) =>
              pastry['name'] != null &&
              pastry['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    if (selectedSortOrder == 'Price Low to High') {
      results.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
    } else if (selectedSortOrder == 'Price High to Low') {
      results.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
    }

    setState(() {
      filteredPastries = results;
    });
  }

  Future<void> _checkIfFavorite() async {
    try {
      final token = await _fetchToken();
      if (token == null) {
        throw Exception("Token is missing.");
      }

      final response = await http.get(
        Uri.parse('$checkIfFavoriteStore/${widget.storeId}'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          isFavorite = jsonResponse['isFavorite'] ?? false;
        });
      } else {
        throw Exception('Failed to fetch favorite status.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final token = await _fetchToken();
      if (token == null) {
        throw Exception("Token is missing.");
      }

      final Uri url = Uri.parse(isFavorite
          ? '$removeFavoriteStore/${widget.storeId}'
          : '$addFavoriteStore/${widget.storeId}');

      final response = await (isFavorite
          ? http.delete(
              url,
              headers: {
                "Authorization": "Bearer $token",
                "Content-Type": "application/json",
              },
            )
          : http.put(
              url,
              headers: {
                "Authorization": "Bearer $token",
                "Content-Type": "application/json",
              },
            ));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          setState(() {
            isFavorite = !isFavorite;
          });

          final message = isFavorite
              ? '${widget.storeName} added to favorites!'
              : '${widget.storeName} removed from favorites!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        } else {
          throw Exception(jsonResponse['message'] ?? 'Action failed.');
        }
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _confirmToggleFavorite() {
    if (!isFavorite) {
      _toggleFavorite(); // Directly add to favorites without confirmation.
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Favorites'),
        content: const Text(
            'Are you sure you want to remove this store from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleFavorite();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String formatTimeRequired(int? timeRequired) {
    if (timeRequired == null || timeRequired <= 0) return "No time specified";

    // Convert to days and round
    final days = (timeRequired / 1440).round();

    // If less than a day, show hours
    if (days == 0) {
      final hours = (timeRequired / 60).round(); // Convert to hours
      return "$hours hour${hours > 1 ? 's' : ''}";
    }

    return "$days day${days > 1 ? 's' : ''}";
  }

  Widget _buildSortDropdown() {
    return Positioned(
      top: appBarHeight, // Position it right below the app bar
      left: 0,
      right: 0,
      child: Material(
        elevation: 4,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                'Recently Added',
                style: TextStyle(
                  color: selectedSortOrder == 'Recently Added'
                      ? myColor
                      : Colors.black,
                  fontWeight: selectedSortOrder == 'Recently Added'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              trailing: selectedSortOrder == 'Recently Added'
                  ? Icon(Icons.check, color: myColor)
                  : null,
              onTap: () {
                setState(() {
                  selectedSortOrder = 'Recently Added';
                  _isSorting = false;
                  _filterPastries('');
                });
              },
            ),
            ListTile(
              title: Text(
                'Price Low to High',
                style: TextStyle(
                  color: selectedSortOrder == 'Price Low to High'
                      ? myColor
                      : Colors.black,
                  fontWeight: selectedSortOrder == 'Price Low to High'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              trailing: selectedSortOrder == 'Price Low to High'
                  ? Icon(Icons.check, color: myColor)
                  : null,
              onTap: () {
                setState(() {
                  selectedSortOrder = 'Price Low to High';
                  _isSorting = false;
                  _filterPastries('');
                });
              },
            ),
            ListTile(
              title: Text(
                'Price High to Low',
                style: TextStyle(
                  color: selectedSortOrder == 'Price High to Low'
                      ? myColor
                      : Colors.black,
                  fontWeight: selectedSortOrder == 'Price High to Low'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              trailing: selectedSortOrder == 'Price High to Low'
                  ? Icon(Icons.check, color: myColor)
                  : null,
              onTap: () {
                setState(() {
                  selectedSortOrder = 'Price High to Low';
                  _isSorting = false;
                  _filterPastries('');
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white70,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.storeName,
          style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            color: Colors.white70,
            onPressed: () {
              setState(() {
                _isSorting = !_isSorting; // Toggle sorting dropdown
              });
            },
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            color: Colors.white70,
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Show the "Make a Special Order" row if allowed
              if (_isSorting) _buildSortDropdown(),

              if (_isSearching)
                Container(
                  color: const Color.fromARGB(171, 243, 229, 245),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterPastries,
                    style: const TextStyle(color: myColor),
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(color: myColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white24,
                    ),
                  ),
                ),
              if (allowSpecialOrders)
                GestureDetector(
                  onTap: () {
                    // Navigate to the special order form
                    /*Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SpecialOrdersPage(
                            //    storeId: widget.storeId,
                            //    storeName: widget.storeName,
                            ),
                      ),
                    );*/
                  },
                  child: Container(
                    width: double.infinity,
                    color: myColor.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag, color: myColor),
                        SizedBox(width: 8),
                        Text(
                          'Make a Special Order',
                          style: TextStyle(
                            color: myColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: myColor),
                      )
                    : filteredPastries.isEmpty
                        ? const Center(
                            child: Text(
                              'No products available.',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(10.0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.7,
                            ),
                            itemCount: filteredPastries.length,
                            itemBuilder: (context, index) {
                              final pastry = filteredPastries[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetailPage(product: pastry),
                                    ),
                                  );
                                },
                                child: Card(
                                  color:
                                      const Color.fromARGB(171, 243, 229, 245),
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 110,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            image: DecorationImage(
                                              image: pastry['image'] != null &&
                                                      pastry['image'].isNotEmpty
                                                  ? NetworkImage(
                                                          pastry['image'])
                                                      as ImageProvider
                                                  : const AssetImage(
                                                      'assets/images/pastry.jpg'),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Product Title
                                            Expanded(
                                              child: Text(
                                                pastry['name'] ?? 'No Name',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow
                                                    .ellipsis, // Prevent overflow
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${pastry['price']?.toStringAsFixed(2) ?? '0.00'}₪',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                // Display badges for Upon Order and Time Required
                                                if (pastry['isUponOrder'] ==
                                                    true)
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const badge(
                                                        text: 'Upon Order',
                                                        color:
                                                            Colors.orangeAccent,
                                                      ),
                                                      const SizedBox(
                                                        height: 2,
                                                      ),
                                                      if (pastry[
                                                              'timeRequired'] !=
                                                          null) // Time Required Badge
                                                        badge(
                                                          text: formatTimeRequired(
                                                              pastry[
                                                                  'timeRequired']),
                                                          color: myColor
                                                              .withOpacity(.6),
                                                          icon: Icons
                                                              .timer, // Add a time icon
                                                        ),
                                                    ],
                                                  ),

                                                // Display Out of Stock Badge
                                                if ((pastry['inStock'] ==
                                                        false) &&
                                                    (pastry['isUponOrder'] ==
                                                        false))
                                                  const badge(
                                                    text: 'Out of Stock',
                                                    color: Colors.redAccent,
                                                  ),
                                                if ((pastry['inStock'] ==
                                                        true) &&
                                                    (pastry['isUponOrder'] ==
                                                        false))
                                                  const badge(
                                                    text: 'Available',
                                                    color: Colors.green,
                                                  ),
                                              ],
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.arrow_forward,
                                                color: myColor,
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        DetailPage(
                                                            product: pastry),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ],
      ),
      // // Sorting dropdown
      floatingActionButton: FloatingActionButton(
        onPressed: _confirmToggleFavorite, // Toggles favorite status
        backgroundColor: myColor,
        foregroundColor: isFavorite
            ? const Color.fromARGB(171, 243, 229, 245)
            : const Color.fromARGB(227, 255, 255, 255),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.favorite),
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  final String text;
  final bool isActive;

  const FilterButton({Key? key, required this.text, required this.isActive})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isNonDefaultValue = text != 'Sort'; // Highlight non-default values

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : myColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color: isActive ? myColor : Colors.white,
              fontWeight: isActive || isNonDefaultValue
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          Icon(
            isActive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: isActive ? myColor : Colors.white,
            size: 18,
          ),
        ],
      ),
    );
  }
}
