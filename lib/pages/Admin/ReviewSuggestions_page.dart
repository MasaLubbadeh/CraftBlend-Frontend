import 'package:craft_blend_project/components/statusBadge.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../configuration/config.dart';

class ReviewSuggestionsPage extends StatefulWidget {
  const ReviewSuggestionsPage({Key? key}) : super(key: key);

  @override
  _ReviewSuggestionsPageState createState() => _ReviewSuggestionsPageState();
}

class _ReviewSuggestionsPageState extends State<ReviewSuggestionsPage> {
  List<dynamic> suggestions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  Future<void> _fetchSuggestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('User not authenticated.');
      }

      final response = await http.get(
        Uri.parse(getAllSuggestions),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          suggestions = json.decode(response.body)['suggestions'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch suggestions.');
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

  Widget _buildSuggestionCard(dynamic suggestion) {
    bool isApprovedOrRejected = suggestion['status'] == 'approved' ||
        suggestion['status'] == 'rejected';

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: const Color.fromARGB(171, 243, 229, 245),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: myColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      suggestion['categoryName'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: myColor,
                      ),
                    ),
                  ],
                ),
                StatusBadge.getBadge(suggestion['status']),
              ],
            ),
            const SizedBox(height: 10),
            if (suggestion['description'] != null &&
                suggestion['description'].isNotEmpty)
              Text(
                suggestion['description'],
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isApprovedOrRejected
                      ? null
                      : () => _approveSuggestion(suggestion['_id']),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isApprovedOrRejected ? Colors.grey : Colors.green,
                  ),
                  child: const Text(
                    'Approve',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: isApprovedOrRejected
                      ? null
                      : () => _rejectSuggestion(suggestion['_id']),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isApprovedOrRejected ? Colors.grey : Colors.red,
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _approveSuggestion(String id) async {
    await _updateSuggestionStatus(id, 'approved');
  }

  Future<void> _rejectSuggestion(String id) async {
    await _updateSuggestionStatus(id, 'rejected');
  }

  Future<void> _updateSuggestionStatus(String id, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('User not authenticated.');
      }

      final response = await http.patch(
        Uri.parse('$updateSuggestionStatus/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suggestion $status successfully.')),
        );
        _fetchSuggestions();
      } else {
        throw Exception('Failed to update suggestion status.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        title: const Text(
          'Review Suggestions',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        backgroundColor: myColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white70,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : suggestions.isEmpty
                ? const Center(
                    child: Text(
                      'No suggestions available.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      return _buildSuggestionCard(suggestions[index]);
                    },
                  ),
      ),
    );
  }
}
