import 'package:craft_blend_project/components/addressWidget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../configuration/config.dart';
import 'categoriesPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> categories = [];
  bool isLoadingCategories = true;
  final ScrollController _categoryScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: myColor.withOpacity(.9),
        elevation: 0,
        title: const AddressWidget(address: 'City Center, Al-Sharawiya'),
        centerTitle: true,
      ),
      body: Container(
        color: const Color.fromARGB(171, 243, 229, 245),
        child: Column(
          children: [
            // Categories Section
            if (isLoadingCategories)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else
              Card(
                color: myColor.withOpacity(.8),
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
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoriesPage(
                                  selectedCategoryId: category[
                                      '_id'], // Pass selected category ID
                                ),
                              ),
                            );
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
                                      color: Colors.grey,
                                      width: 2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: category['image'] != null &&
                                            category['image'].isNotEmpty
                                        ? Image.network(
                                            category['image'],
                                            fit: BoxFit.cover,
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
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black54,
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

            // Placeholder for additional content
            Expanded(
              child: Center(
                child: Text(
                  'Welcome to the Home Page!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
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

class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Center(
        child: const Text('Search functionality coming soon!'),
      ),
    );
  }
}
