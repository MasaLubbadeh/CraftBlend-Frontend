import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../configuration/config.dart';

class ManageSubscriptionPage extends StatefulWidget {
  const ManageSubscriptionPage({super.key});

  @override
  State<ManageSubscriptionPage> createState() => _ManageSubscriptionPageState();
}

class _ManageSubscriptionPageState extends State<ManageSubscriptionPage> {
  Map<String, dynamic>? subscriptionDetails;
  bool isLoading = true;
  bool isRenewing = false;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionDetails();
  }

  Future<void> _fetchSubscriptionDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse(getSubscriptionDetails), // Replace with your endpoint
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          subscriptionDetails = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch subscription details');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _renewSubscription() async {
    setState(() {
      isRenewing = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('renewSubscription'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'subscriptionPlanId': subscriptionDetails?['plan']['_id'],
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription renewed successfully!')),
        );
        _fetchSubscriptionDetails(); // Refresh details after renewal
      } else {
        throw Exception('Failed to renew subscription');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isRenewing = false;
      });
    }
  }

  String _formatDate(String isoDate) {
    final dateTime = DateTime.parse(isoDate);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Subscription',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : subscriptionDetails == null
              ? const Center(
                  child: Text(
                    'No subscription found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          myColor.withOpacity(0.9),
                          Colors.blueGrey.shade100,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                'Your Subscription Plan',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 10),
                        Text(
                          'Plan: ${subscriptionDetails?['subscriptionDetails']['plan']['name'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Price: ${subscriptionDetails?['subscriptionDetails']['plan']['price'] ?? 'N/A'}₪',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Expires on: ${subscriptionDetails?['subscriptionDetails']['expiresOn'] != null ? _formatDate(subscriptionDetails?['subscriptionDetails']['expiresOn']) : 'N/A'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subscriptionDetails?['subscriptionDetails']
                                      ['autoRenew'] ==
                                  true
                              ? 'Your subscription will automatically renew.'
                              : 'Your subscription will not renew automatically.',
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.white70,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: isRenewing
                              ? null
                              : () {
                                  _renewSubscription();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: myColor,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: isRenewing
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )
                              : const Text(
                                  'Renew Subscription',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
