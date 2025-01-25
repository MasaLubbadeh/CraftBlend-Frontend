import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../configuration/config.dart';

class ViewCurrentAdminsPage extends StatefulWidget {
  const ViewCurrentAdminsPage({super.key});

  @override
  _ViewCurrentAdminsPageState createState() => _ViewCurrentAdminsPageState();
}

class _ViewCurrentAdminsPageState extends State<ViewCurrentAdminsPage> {
  List<dynamic> admins = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  Future<void> _fetchAdmins() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse(getAdminsUrl), // Replace with your endpoint
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            admins = json.decode(response.body)['data']; // Parse data
            isLoading = false;
          });
        } else {
          print('Error fetching admins: ${response.statusCode}');
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        print('Exception while fetching admins: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      print('Token not found. Cannot fetch admins.');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _confirmDeleteAdmin(String adminId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Admin"),
          content: const Text("Are you sure you want to delete this admin?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAdmin(adminId);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAdmin(String adminId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token != null) {
      try {
        final response = await http.delete(
          Uri.parse('$deleteAdminUrl/$adminId'), // Replace with your endpoint
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Admin deleted successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          _fetchAdmins(); // Refresh admin list
        } else {
          print('Error deleting admin: ${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to delete admin."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Exception while deleting admin: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error occurred while deleting admin."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'View Current Admins',
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : admins.isNotEmpty
                ? ListView.builder(
                    itemCount: admins.length,
                    itemBuilder: (context, index) {
                      return _buildAdminCard(admins[index]);
                    },
                  )
                : const Center(
                    child: Text('No admins found.'),
                  ),
      ),
    );
  }

  Widget _buildAdminCard(Map<String, dynamic> admin) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Card(
        color: myColor2,
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: ClipOval(
            child: const Icon(
              Icons.person,
              color: myColor,
              size: 50,
            ),
          ),
          title: Text(
            '${admin['firstName']} ${admin['lastName']}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: myColor,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email: ${admin['email']}',
                style: TextStyle(color: myColor),
              ),
              Text(
                'Phone: ${admin['phoneNumber'] ?? 'N/A'}',
                style: TextStyle(color: myColor),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _confirmDeleteAdmin(admin['_id']);
            },
          ),
        ),
      ),
    );
  }
}
