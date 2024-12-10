import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../configuration/config.dart';
import '../productDetails_page.dart';
import '../../../components/badge.dart';

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
  bool isFavorite = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPastries();
  }

  Future<void> _fetchPastries() async {
    try {
      final response = await http
          .get(Uri.parse('$getStoreProductsForUser/${widget.storeId}'));
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
    if (query.isEmpty) {
      setState(() {
        filteredPastries = pastries;
      });
    } else {
      setState(() {
        filteredPastries = pastries
            .where((pastry) =>
                pastry['name'] != null &&
                pastry['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
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
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            color: Colors.white70,
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  filteredPastries = pastries;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching)
            Container(
              color: const Color.fromARGB(171, 243, 229, 245),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: myColor),
                  )
                : filteredPastries.isEmpty
                    ? const Center(
                        child: Text(
                          'No pastries available.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
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
                              color: const Color.fromARGB(171, 243, 229, 245),
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: pastry['image'] != null &&
                                                  pastry['image'].isNotEmpty
                                              ? NetworkImage(pastry['image'])
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
                                        const SizedBox(
                                            width:
                                                8), // Add spacing between title and badge
                                        // Badge for Out of Stock or Special Note
                                        if ((pastry['inStock'] == false) &&
                                            (pastry['isUponOrder'] ==
                                                false)) // Out of Stock
                                          const badge(
                                            text: 'Out of Stock',
                                            color: Colors.redAccent,
                                          )
                                        else if (pastry['specialNote'] !=
                                            null) // Special Note
                                          badge(
                                            text: pastry['specialNote'] ?? '',
                                            color: Colors
                                                .blueAccent, // Adjust color as needed
                                          ),
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
                                            if (pastry['isUponOrder'] ==
                                                true) // Upon Order badge
                                              const badge(
                                                text: 'Upon Order',
                                                color: Colors.orangeAccent,
                                              ),
                                            if ((pastry['inStock'] == false) &&
                                                (pastry['isUponOrder'] ==
                                                    false)) // Out of Stock badge
                                              const badge(
                                                text: 'Out of Stock',
                                                color: Colors.redAccent,
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
                                                    DetailPage(product: pastry),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            isFavorite = !isFavorite;
          });
          // Add to favorites logic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.storeName} added to favorites!'),
            ),
          );
        },
        backgroundColor: myColor, //const Color.fromARGB(171, 243, 229, 245),
        foregroundColor: isFavorite
            ? const Color.fromARGB(171, 243, 229, 245)
            : const Color.fromARGB(227, 255, 255, 255),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ), //Colors.white70,
        child: const Icon(Icons.favorite),
      ),
    );
  }
}
