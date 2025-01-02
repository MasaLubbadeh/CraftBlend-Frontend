import 'dart:io';
import 'package:craft_blend_project/components/statusBadge.dart';
import 'package:craft_blend_project/pages/Store/AddAdvertisement_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../configuration/config.dart';

class ManageAdvertisementPage extends StatefulWidget {
  const ManageAdvertisementPage({Key? key}) : super(key: key);

  @override
  _ManageAdvertisementPageState createState() =>
      _ManageAdvertisementPageState();
}

class _ManageAdvertisementPageState extends State<ManageAdvertisementPage> {
  List<Map<String, dynamic>> advertisements = []; // Store multiple ads
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentAdvertisement(); // Fetch the current advertisement
  }

  Future<void> _fetchCurrentAdvertisement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(getStoreAdvertisements),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> ads =
            json.decode(response.body)['advertisements']; // Parse all ads
        setState(() {
          advertisements = ads.cast<Map<String, dynamic>>(); // Store all ads
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch advertisements');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching advertisements: $e');
    }
  }

  Future<void> _removeAdvertisement(String adId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('removeAdvertisementEndpoint/adId'), // API endpoint
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advertisement removed successfully.')),
        );
        setState(() {
          advertisements.removeWhere((ad) => ad['_id'] == adId);
        });
      } else {
        throw Exception('Failed to remove advertisement');
      }
    } catch (e) {
      print('Error removing advertisement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove advertisement: $e')),
      );
    }
  }

  void _navigateToAddAdvertisementPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AddAdvertisementPage(), // Redirect to AddAdvertisementPage
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        backgroundColor: myColor,
        elevation: 0,
        title: const Text(
          'Manage Advertisement',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
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
          : Column(
              children: [
                Expanded(
                  child: advertisements.isNotEmpty
                      ? _buildCurrentAdvertisementView()
                      : _buildNoAdvertisementView(),
                ),
                _buildAddAdvertisementButton(),
              ],
            ),
    );
  }

  Widget _buildCurrentAdvertisementView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: advertisements.length,
      itemBuilder: (context, index) {
        final ad = advertisements[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Advertisement #${index + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: myColor,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 5),
                ad['image'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          ad['image'],
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text(
                                'Failed to load advertisement image');
                          },
                        ),
                      )
                    : const Text('No image available'),
                const SizedBox(height: 16),
                Text(
                  'Start Date: ${ad['startDate'].split('T')[0]}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: myColor,
                  ),
                ),
                Text(
                  'End Date: ${ad['endDate'].split('T')[0]}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: myColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: myColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    StatusBadge.getBadge(ad['status']),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _removeAdvertisement(ad['_id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(.6),
                  ),
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text(
                    'Remove Advertisement',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoAdvertisementView() {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No current advertisement found.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddAdvertisementButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: _navigateToAddAdvertisementPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: myColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Another Advertisement',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
