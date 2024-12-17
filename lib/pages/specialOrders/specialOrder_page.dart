import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../configuration/config.dart';
import 'specialOrderOptions.dart';

class SpecialOrdersPage extends StatefulWidget {
  const SpecialOrdersPage({super.key});

  @override
  _SpecialOrdersPageState createState() => _SpecialOrdersPageState();
}

class _SpecialOrdersPageState extends State<SpecialOrdersPage> {
  bool specialOrdersEnabled =
      true; // Indicates if the store allows special orders
  bool isEditing = false; // Tracks whether the user is editing
  Map<String, bool> selectedOrderOptions = {
    'Custom-Made Cake': false,
    'Large Orders': false,
  }; // Tracks the selection state of each option

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
          'Special Orders',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Image with Opacity
          Opacity(
            opacity: 0.2,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/pastry.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSpecialOrdersSwitchCard(),
                const SizedBox(height: 16),
                //if (specialOrdersEnabled)
                _buildReviewRequestsCard(), // New Card for Review Requests
                const SizedBox(height: 16),
                if (specialOrdersEnabled) _buildOrderOptionsSelectionCard(),
                const SizedBox(height: 24),
                if (specialOrdersEnabled) _buildManageFormsButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Special Orders Switch Card
  Widget _buildSpecialOrdersSwitchCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Allow Special Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: myColor,
              ),
            ),
            Switch(
              activeColor: myColor,
              value: specialOrdersEnabled,
              onChanged: (value) {
                setState(() {
                  specialOrdersEnabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // New Card for Navigating to Review Requests
  Widget _buildReviewRequestsCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: const Icon(Icons.receipt, color: myColor),
        title: const Text(
          'Review Special Order Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: myColor,
          ),
        ),
        onTap:
            _navigateToReviewRequestsPage, // Navigate to review requests page
      ),
    );
  }

  // Review Requests Page Navigation
  void _navigateToReviewRequestsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReviewSpecialOrdersPage()),
    );
  }

// Order Options Selection Card
  Widget _buildOrderOptionsSelectionCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Special Order Options:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: myColor,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isEditing ? Icons.check : Icons.edit,
                    color: myColor,
                  ),
                  onPressed: () {
                    setState(() {
                      isEditing = !isEditing;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.8,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildOrderOptionTile(
                      'Custom-Made Cake',
                      'assets/images/cake.png',
                      selectedOrderOptions['Custom-Made Cake'] ?? false,
                      (value) {
                        if (isEditing) {
                          setState(() {
                            selectedOrderOptions['Custom-Made Cake'] =
                                value ?? false;
                          });
                        }
                      },
                    ),
                    _buildOrderOptionTile(
                      'Large Orders',
                      'assets/images/bulkBuying.png',
                      selectedOrderOptions['Large Orders'] ?? false,
                      (value) {
                        if (isEditing) {
                          setState(() {
                            selectedOrderOptions['Large Orders'] =
                                value ?? false;
                          });
                        }
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Container(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: isEditing ? _navigateToSetupFormPage : null,
                icon: const Icon(Icons.add, color: Colors.white70),
                label: const Text(
                  'Add new option',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEditing
                      ? myColor
                      : myColor
                          .withOpacity(0.5), // Reduced opacity when disabled
                  padding: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 30.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderOptionTile(
      String title, String imagePath, bool value, Function(bool?) onChanged) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Image.asset(
            imagePath,
            height: MediaQuery.of(context).size.height * 0.15,
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: value,
              activeColor: myColor,
              onChanged: isEditing ? onChanged : null,
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: myColor,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManageFormsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _navigateToSetupFormPage,
        icon: const Icon(Icons.settings, color: Colors.white70),
        label: const Text(
          'Manage Special Order Forms',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: myColor,
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
        ),
      ),
    );
  }

  void _navigateToSetupFormPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const SpecialOrdersOverviewPage()),
    );
  }
}

// Placeholder for the ReviewSpecialOrdersPage
class ReviewSpecialOrdersPage extends StatelessWidget {
  const ReviewSpecialOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'Review Special Requests',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          'Here, the store owner will be able to see and review all the special order requests.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
