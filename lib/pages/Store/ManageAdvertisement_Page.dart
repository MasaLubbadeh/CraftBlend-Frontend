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
        Uri.parse('$removeAdvertisement/$adId'), // API endpoint
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
    ).then((_) {
      // Refresh advertisements when returning to this page
      _fetchCurrentAdvertisement();
    });
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
            fontSize: 22,
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
                  onPressed: () => _showRemoveConfirmationDialog(ad['_id']),
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No current advertisement found.',
              style: TextStyle(
                fontSize: 18,
                color: myColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAdvertisementButton() {
    final adCount = advertisements.length;
    final canAddNewAd = adCount < 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity, // Ensures the button spans full width
            child: ElevatedButton.icon(
              onPressed: adCount == 0
                  ? _navigateToAddAdvertisementPage // Allow directly adding if no ads
                  : adCount == 1
                      ? _showAddConfirmationDialog // Show confirmation if 1 ad exists
                      : null, // Disable button if 2 or more ads exist
              style: ElevatedButton.styleFrom(
                backgroundColor: canAddNewAd ? myColor : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                adCount == 0
                    ? 'Add Advertisement'
                    : 'Add Another Advertisement',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          if (adCount >= 2)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                '**You already have 2 active advertisements. You cannot add more.**',
                style: TextStyle(
                    color: myColor, fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  void _showAddConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Additional Advertisement'),
        content: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 16,
              color: Colors.black, // Default text color
            ),
            children: [
              TextSpan(
                text: 'There will be ',
                style: TextStyle(fontWeight: FontWeight.w300), // Make it bold
              ),
              TextSpan(
                text: 'extra charges',
                style: TextStyle(fontWeight: FontWeight.w500), // Make it bold
              ),
              TextSpan(
                text:
                    ' for adding another advertisement. Are you sure you want to proceed?',
                style: TextStyle(fontWeight: FontWeight.w300), // Make it bold
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToAddAdvertisementPage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: myColor,
            ),
            child: const Text(
              'Proceed',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveConfirmationDialog(String adId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content:
            const Text('Are you sure you want to remove this advertisement? '),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeAdvertisement(adId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: myColor,
            ),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
