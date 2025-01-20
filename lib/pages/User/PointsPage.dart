import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../configuration/config.dart';

class PointsPage extends StatefulWidget {
  const PointsPage({Key? key}) : super(key: key);

  @override
  State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  List<dynamic> pointsData = []; // Holds the fetched points data
  bool isLoading = true; // Track loading state
  bool hasError = false; // Track if an error occurred

  @override
  void initState() {
    super.initState();
    _fetchPointsData();
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchPointsData() async {
    try {
      String? token = await _getToken();
      if (token == null) {
        throw Exception("Authentication token not found!");
      }
      final response = await http.get(
        Uri.parse(getAllPoints),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pointsData = data['points'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch points.');
      }
    } catch (error) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      print('Error fetching points: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        toolbarHeight: appBarHeight,
        title: const Text(
          "My Points",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: myColor,
              ),
            )
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 50),
                      const SizedBox(height: 10),
                      const Text(
                        "Failed to load points.",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _fetchPointsData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: myColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        child: const Text(
                          "Retry",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Point System Note
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: myColor2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Text(
                          "Each store has its own point system, and the value of points earned depends on the store. "
                          "\n\nHowever, the points you have now can be redeemed as 1 point equals 1₪. "
                          "Redeem your points for discounts and save more!",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Points List
                    Expanded(
                      child: pointsData.isNotEmpty
                          ? ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: pointsData.length,
                              itemBuilder: (context, index) {
                                final storeData = pointsData[index];
                                final storeName =
                                    storeData['storeName'] ?? 'Unknown Store';
                                final points = storeData['totalPoints'] ?? 0;
                                final storeLogo = storeData['logo'];

                                return Card(
                                  color: myColor2,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 15),
                                    leading: CircleAvatar(
                                      backgroundImage: storeLogo != null
                                          ? NetworkImage(storeLogo)
                                          : null, // Fallback if no logo
                                      backgroundColor: storeLogo == null
                                          ? myColor.withOpacity(0.7)
                                          : Colors
                                              .transparent, // Transparent if logo exists
                                      child: storeLogo == null
                                          ? Text(
                                              storeName[0].toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            )
                                          : null, // No text if logo exists
                                    ),
                                    title: Text(
                                      storeName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "$points points",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black45,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.loyalty,
                                      color: myColor.withOpacity(0.9),
                                      size: 30,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.loyalty,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "No Points Available",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    "Start shopping to earn points in your favorite stores!",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black45,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
