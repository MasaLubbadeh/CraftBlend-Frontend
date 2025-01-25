import 'package:craft_blend_project/pages/Admin/ReviewSuggestions_page.dart';
import 'package:craft_blend_project/pages/Admin/adminManagesSubscription.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'addAdminPage.dart';
import 'adminManageCategories.dart';
import '../../configuration/config.dart';
import '../User/login_page.dart';
import 'adminManageStores.dart';
//import 'manage_store_subscriptions.dart'; // Import your ManageStoreSubscriptions page
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'viewCurrentAdmins.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  Future<String?> getUserEmail() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception("No token found");
      }

      final response = await http.get(
        Uri.parse(getUserEmailUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['email'];
      } else {
        throw Exception("Failed to fetch user email");
      }
    } catch (e) {
      print("Error fetching user email: $e");
      return null;
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
          'Admin Dashboard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [myColor.withOpacity(0.9), Colors.blueGrey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background Image with Opacity
            Opacity(
              opacity: 0.2,
              child: Container(),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  FutureBuilder<String?>(
                    future: getUserEmail(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(); // Optional loading spinner
                      }

                      if (snapshot.hasData &&
                          snapshot.data == "admin@gmail.com") {
                        return Column(
                          children: [
                            _buildAddNewAdminCard(context),
                            _buildViewCurrentAdmin(context),
                          ],
                        );
                      }

                      return SizedBox
                          .shrink(); // Do nothing if not the main admin
                    },
                  ),
                  _buildManageCategoriesCard(context),
                  _buildManageStoresCard(context),
                  _buildReviewSuggestionsCard(context),
                  _buildManageStoreSubscriptionsCard(context), // New card
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewAdminCard(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: const Icon(Icons.add, color: myColor, size: 36),
        title: const Text(
          'Add New Admin',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: myColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: myColor),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAdminPage()),
          );
        },
      ),
    );
  }

  Widget _buildManageCategoriesCard(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: const Icon(Icons.category, color: myColor, size: 36),
        title: const Text(
          'Manage Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: myColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: myColor),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ManageCategoriesPage()),
          );
        },
      ),
    );
  }

  Widget _buildReviewSuggestionsCard(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: const Icon(Icons.rate_review, color: myColor, size: 36),
        title: const Text(
          'Review Category Suggestions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: myColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: myColor),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ReviewSuggestionsPage()),
          );
        },
      ),
    );
  }

  Widget _buildManageStoresCard(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: const Icon(Icons.store, color: myColor, size: 36),
        title: const Text(
          'Manage Stores',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: myColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: myColor),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AdminManageStoresPage()),
          );
        },
      ),
    );
  }

  Widget _buildManageStoreSubscriptionsCard(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: const Icon(Icons.subscriptions, color: myColor, size: 36),
        title: const Text(
          'Manage Store Subscriptions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: myColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: myColor),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AdminManageSubscriptionsPage()),
          );
        },
      ),
    );
  }

  Widget _buildViewCurrentAdmin(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: const Icon(Icons.supervisor_account, color: myColor, size: 36),
        title: const Text(
          'View Current Admins',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: myColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: myColor),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ViewCurrentAdminsPage()),
          );
        },
      ),
    );
  }
}
