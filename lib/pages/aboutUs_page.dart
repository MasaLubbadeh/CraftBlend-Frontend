import 'package:flutter/material.dart';
import '../configuration/config.dart';

class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        automaticallyImplyLeading: false,
        backgroundColor: myColor, // Your primary color
        title: const Text(
          'About Us',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/craftsBackground.jpg', // Replace with your image path
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color:
                  Colors.white70.withOpacity(0.92), // Adjust opacity as needed
            ),
          ),
          const Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Platform Information
                Center(
                  child: const Text(
                    'Welcome to Craft Blend!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: myColor, // Use app's primary color
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: myColor2,
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Craft Blend is a platform designed to connect stores and customers with unique products and special orders. \n'
                      'Our goal is to streamline interactions between customers and businesses by providing an easy-to-use platform for managing products, '
                      'categories, and personalized requests.\n Explore our features and find what you need!',
                      style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          letterSpacing: 1,
                          color: myColor),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Contact Information
                Card(
                  color: myColor2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.email, color: myColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Email: craftblend2024@gmail.com',
                          style: TextStyle(fontSize: 16, color: myColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: myColor2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: myColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Phone: +970598315911',
                          style: TextStyle(fontSize: 16, color: myColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Developers
                SizedBox(
                  width: double.infinity, // Make the card full width
                  child: Card(
                    color: myColor2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Center(
                            child: Text(
                              'Developed By:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: myColor,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Raya Hindi & Masa Lubbadeh',
                            style: TextStyle(
                                fontSize: 16,
                                color: myColor,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
