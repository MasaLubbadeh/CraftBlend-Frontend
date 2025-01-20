import 'package:craft_blend_project/pages/Admin/ReviewSuggestions_page.dart';
import 'package:craft_blend_project/pages/Admin/adminManagesSubscription.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'adminManageCategories.dart';
import '../../configuration/config.dart';
import '../User/login_page.dart';
//import 'manage_store_subscriptions.dart'; // Import your ManageStoreSubscriptions page

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

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
            fontSize: 18,
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
                  _buildManageCategoriesCard(context),
                  _buildReviewSuggestionsCard(context),
                  _buildManageStoreSubscriptionsCard(context), // New card
                  _buildLogoutTile(context),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildLogoutTile(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: const Icon(Icons.logout, color: myColor, size: 36),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: myColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: myColor),
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have logged out successfully.'),
            ),
          );
        },
      ),
    );
  }
}
