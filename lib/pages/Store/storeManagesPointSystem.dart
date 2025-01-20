import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../configuration/config.dart';

class ManagePointsPage extends StatefulWidget {
  const ManagePointsPage({Key? key}) : super(key: key);

  @override
  _ManagePointsPageState createState() => _ManagePointsPageState();
}

class _ManagePointsPageState extends State<ManagePointsPage> {
  int shekelPerPoint = 20; // Default value
  bool isLoading = true; // Loading state
  final TextEditingController _rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCurrentRate(); // Fetch the current rate when the page loads
  }

  @override
  void dispose() {
    _rateController.dispose(); // Dispose the controller
    super.dispose();
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs
        .getString('token'); // Adjust the key based on your implementation
  }

  // Fetch the current shekelPerPoint rate from the API
  Future<void> _fetchCurrentRate() async {
    setState(() {
      isLoading = true;
    });

    try {
      String? token = await _getToken();

      final response = await http.get(
        Uri.parse(getShekelPerPoint), // Replace with actual endpoint
        headers: {'Authorization': 'Bearer $token'}, // Include your auth token
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          shekelPerPoint = data['shekelPerPoint']?.toInt() ?? 20;
          _rateController.text =
              shekelPerPoint.toString(); // Set the initial value
        });
      } else {
        _showSnackBar('Failed to fetch current rate.');
      }
    } catch (error) {
      _showSnackBar('An error occurred: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Update the shekelPerPoint value via API
  Future<void> _updateRate(int newRate) async {
    try {
      String? token = await _getToken();

      final response = await http.patch(
        Uri.parse(updateShekelPerPoint), // Replace with actual endpoint
        headers: {
          'Authorization': 'Bearer $token', // Include your auth token
          'Content-Type': 'application/json',
        },
        body: json.encode({'shekelPerPoint': newRate}),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Updated successfully!');
        await _fetchCurrentRate(); // Refresh the current rate
        _rateController.clear(); // Clear the TextField
      } else {
        _showSnackBar('Failed to update rate.');
        print(response.body);
      }
    } catch (error) {
      _showSnackBar('An error occurred: $error');
    }
  }

  // Show SnackBar for notifications
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        toolbarHeight: appBarHeight,
        title: const Text(
          'Manage Point System',
          style: TextStyle(
            fontSize: 24,
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
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 8,
                color: myColor2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Shekel Per Point',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Current Rate: $shekelPerPoint ₪ per point',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _rateController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Update Rate',
                          labelStyle: const TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          prefixIcon: const Icon(Icons.edit, color: myColor),
                        ),
                        onChanged: (value) {
                          shekelPerPoint =
                              int.tryParse(value) ?? shekelPerPoint;
                        },
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _updateRate(shekelPerPoint);
                          },
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text(
                            'Save Changes',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: myColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
