import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../configuration/config.dart';
import 'package:http/http.dart' as http;

class AdminManageSubscriptionsPage extends StatefulWidget {
  const AdminManageSubscriptionsPage({super.key});

  @override
  State<AdminManageSubscriptionsPage> createState() =>
      _AdminManageSubscriptionsPageState();
}

class _AdminManageSubscriptionsPageState
    extends State<AdminManageSubscriptionsPage> {
  late Future<List<dynamic>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _plansFuture = _fetchPlans();
  }

  Future<List<dynamic>> _fetchPlans() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('User not authenticated. Please log in again.');
    }

    try {
      final response = await http.get(
        Uri.parse(getSubscriptionPlans),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to load plans. Server responded with: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching plans: $e');
    }
  }

  void _refreshPlans() {
    setState(() {
      _plansFuture = _fetchPlans();
    });
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
          'Manage Subscriptions',
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [myColor.withOpacity(0.9), Colors.blueGrey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _plansFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('No subscription plans available.'),
                      );
                    }

                    final plans = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: plans.length,
                      itemBuilder: (context, index) {
                        final plan = plans[index];
                        return Card(
                          color: myColor2,
                          elevation: 6,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            title: Text(
                              plan['name'] ?? 'Unnamed Plan',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: myColor,
                              ),
                            ),
                            subtitle: Text(
                              '₪${plan['price']} for ${plan['duration']} months',
                              style: const TextStyle(color: myColor),
                            ),
                            trailing: const Icon(Icons.edit, color: myColor),
                            onTap: () {
                              // Handle edit functionality here
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: myColor,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddSubscriptionPlanPage()),
          );
          if (result == true) {
            _refreshPlans(); // Refresh the plans when returning
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class AddSubscriptionPlanPage extends StatefulWidget {
  const AddSubscriptionPlanPage({super.key});

  @override
  State<AddSubscriptionPlanPage> createState() =>
      _AddSubscriptionPlanPageState();
}

class _AddSubscriptionPlanPageState extends State<AddSubscriptionPlanPage> {
  final TextEditingController planNameController = TextEditingController();
  final TextEditingController planDescriptionController =
      TextEditingController();
  final TextEditingController planPriceController = TextEditingController();
  final TextEditingController planFeaturesController = TextEditingController();
  final TextEditingController planDurationController = TextEditingController();

  @override
  void dispose() {
    planNameController.dispose();
    planDescriptionController.dispose();
    planPriceController.dispose();
    planFeaturesController.dispose();
    planDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        toolbarHeight: appBarHeight,
        title: const Text(
          'Add Subscription Plan',
          style: TextStyle(color: Colors.white70),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [myColor.withOpacity(0.9), Colors.blueGrey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField('Plan Name', planNameController),
                      _buildTextField(
                          'Plan Description', planDescriptionController),
                      _buildTextField('Plan Price (₪)', planPriceController,
                          keyboardType: TextInputType.number),
                      _buildTextField('Plan Features', planFeaturesController),
                      _buildTextField(
                        'Plan Duration (Months)',
                        planDurationController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _addPlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: myColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Save Plan',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(5),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _addPlan() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to log in first!')),
      );
      return;
    }

    final Map<String, dynamic> planData = {
      "name": planNameController.text.trim(),
      "description": planDescriptionController.text.trim(),
      "price": double.tryParse(planPriceController.text.trim()) ?? 0,
      "features": planFeaturesController.text.trim(),
      "duration": int.tryParse(planDurationController.text.trim()) ?? 0,
    };

    try {
      final response = await http.post(
        Uri.parse(addSubscriptionPlan),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(planData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Subscription Plan Added Successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        final errorMessage = json.decode(response.body)['message'] ??
            'Failed to add subscription plan.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errorMessage')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $error')),
      );
    }
  }
}

class ViewSubscriptionPlansPage extends StatelessWidget {
  const ViewSubscriptionPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        toolbarHeight: appBarHeight,
        title: const Text(
          'Subscription Plans',
          style: TextStyle(color: Colors.white70),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchPlans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No subscription plans available.'),
            );
          }

          final plans = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Card(
                color: myColor2,
                elevation: 6,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(
                    plan['name'] ?? 'Unnamed Plan',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: myColor,
                    ),
                  ),
                  subtitle: Text(
                    '₪${plan['price']} for ${plan['duration']} months',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  trailing: const Icon(Icons.edit, color: myColor),
                  onTap: () {
                    // Handle edit functionality here
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<dynamic>> _fetchPlans() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('User not authenticated. Please log in again.');
    }

    try {
      final response = await http.get(
        Uri.parse(getSubscriptionPlans), // Use proper baseUrl
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to load plans. Server responded with: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching plans: $e');
    }
  }
}
