import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../configuration/config.dart';
import 'Product/Pastry/pastryUser_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> stores = [];
  bool isLoadingStores = false;
  bool isLoadingCategories = true;
  String? selectedCategoryId;
  final ScrollController _categoryScrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCategories();

    // Save scroll offset whenever it changes
    _categoryScrollController.addListener(() {
      _scrollOffset = _categoryScrollController.offset;
    });
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse(getAllCategories));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          categories =
              List<Map<String, dynamic>>.from(jsonResponse['categories']);
          isLoadingCategories = false;
        });

        // Restore scroll position
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _categoryScrollController.jumpTo(_scrollOffset);
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      setState(() {
        isLoadingCategories = false;
      });
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchStores(String categoryId) async {
    try {
      setState(() {
        isLoadingStores = true;
      });

      final response =
          await http.get(Uri.parse('$getStoresByCategory/$categoryId/stores'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          stores = List<Map<String, dynamic>>.from(jsonResponse);
          isLoadingStores = false;
        });
      } else {
        throw Exception('Failed to load stores');
      }
    } catch (e) {
      setState(() {
        isLoadingStores = false;
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
        title: const Text(
          'Categories',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Categories Section
          if (isLoadingCategories)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else
            Card(
              borderOnForeground: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: SingleChildScrollView(
                  controller: _categoryScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categories.map((category) {
                      final isSelected = category['_id'] == selectedCategoryId;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategoryId = category['_id'];
                          });
                          _fetchStores(category['_id']);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected ? myColor : Colors.grey,
                                    width: 2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: category['image'] != null &&
                                          category['image'].isNotEmpty
                                      ? Opacity(
                                          opacity: isSelected ? 0.7 : 1,
                                          child: Image.network(
                                            category['image'],
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey,
                                          child: Center(
                                            child: Text(
                                              category['name'][0],
                                              style: const TextStyle(
                                                fontSize: 30,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  category['name'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color:
                                        isSelected ? myColor : Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.clip,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          // Stores Section
          Expanded(
            child: isLoadingStores
                ? const Center(child: CircularProgressIndicator())
                : stores.isEmpty
                    ? Center(
                        child: Text(
                          selectedCategoryId == null
                              ? 'Select a category to view stores.'
                              : 'No stores available for this category.',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width < 600 ? 2 : 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: stores.length,
                        itemBuilder: (context, index) {
                          final store = stores[index];
                          return GestureDetector(
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
                            child: Card(
                              color: Colors.white,
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        store['logo'] ?? '',
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.15,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.15,
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.15,
                                            color: Colors.grey,
                                            child: const Center(
                                              child: Icon(
                                                Icons.store,
                                                size: 40,
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      store['storeName'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Text(
                                      'review:',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
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
    );
  }
}
