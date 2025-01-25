import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../Store/ownerChooseSubscription_Page.dart';
import 'addPastryProduct.dart';
import '../../../configuration/config.dart';
import '../EditPastryProduct.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PastryOwnerPage extends StatefulWidget {
  const PastryOwnerPage({super.key});

  @override
  _PastryOwnerPageState createState() => _PastryOwnerPageState();
}

class _PastryOwnerPageState extends State<PastryOwnerPage> {
  String businessName = 'Pastry Delights';
  List<Map<String, dynamic>> pastries = [];
  List<Map<String, dynamic>> filteredPastries = [];
  bool isLoading = true;
  bool _isAddingProduct = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  late Timer _timer;
  String _remainingTime = '';
  bool _showNoProductsOverlay = true; // New state variable
// Notifications state variables
  List<Map<String, dynamic>> notifications = [];
  bool isLoadingNotifications = true;
  int unreadNotificationsCount = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isDrawerOpen = false;

  /* @override
  void initState() {
    super.initState();
    _fetchStoreDetails();
    fetchPastries();
    // Initialize remaining time
    /* _updateRemainingTime();
    // Set up the timer to update the remaining time every second
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _updateRemainingTime();
        // print(_remainingTime);
      });
    });*/
    // Set up the timer to update the remaining time every second
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        // Update the remaining time for each pastry based on its endDate
        for (var pastry in pastries) {
          // Ensure 'onSale' is not null and true
          if (pastry['onSale'] == true) {
            // Check if endDate is null and assign a static date if necessary
            DateTime endDate;
            if (pastry['endDate'] != null) {
              try {
                // Parse the endDate string to DateTime
                endDate = DateTime.parse(pastry['endDate']);
              } catch (e) {
                // If endDate is not a valid date string, handle the error (optional logging or fallback)
                print("Invalid date format for pastry: ${pastry['endDate']}");
                // Assign a static fallback date if parsing fails
                endDate =
                    DateTime(2025, 12, 31); // Static date example (future date)
              }
            } else {
              // Assign a static fallback date if endDate is null
              endDate =
                  DateTime(2025, 12, 31); // Static date example (future date)
            }

            // Update remaining time based on endDate (static or real)
            _updateRemainingTime(endDate);
          }
        }
      });
    });
  }
*/
  @override
  void initState() {
    super.initState();
    _fetchStoreDetails();
    fetchPastries();
    _fetchNotifications(); // Fetch notifications

    // Set up the timer to update the remaining time for each pastry every second
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        for (var pastry in pastries) {
          if (pastry['onSale'] == true && pastry['endDate'] != null) {
            try {
              DateTime endDate = DateTime.parse(pastry['endDate']);
              pastry['remainingTime'] = _calculateRemainingTime(endDate);
            } catch (e) {
              print("Invalid endDate format for pastry: ${pastry['endDate']}");
              pastry['remainingTime'] = 'Invalid Date';
            }
          } else {
            pastry['remainingTime'] = 'Not on Sale';
          }
        }
      });
    });
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  String _calculateRemainingTime(DateTime endDate) {
    DateTime currentDate = DateTime.now();
    Duration difference = endDate.difference(currentDate);

    if (difference.isNegative) {
      return 'Sale Ended';
    } else {
      return '${difference.inDays}d ${difference.inHours % 24}h ${difference.inMinutes % 60}m ${difference.inSeconds % 60}s';
    }
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _timer.cancel();
    super.dispose();
  }

  void _handleDrawerStateChange() {
    if (isDrawerOpen && !_scaffoldKey.currentState!.isDrawerOpen) {
      // The drawer was open and now it's closed
      _markNotificationsAsRead();
    }
    isDrawerOpen = _scaffoldKey.currentState!.isDrawerOpen;
  }

  Future<void> _fetchNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }
      String? userType = prefs.getString('userType');

      final response = await http.get(
        Uri.parse(
            '$getNotifications?userType=$userType'), // Replace with your actual endpoint
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          notifications =
              List<Map<String, dynamic>>.from(jsonResponse['notifications']);
          unreadNotificationsCount = notifications
              .where((notification) => notification['isRead'] == false)
              .length;
          isLoadingNotifications = false;
        });
      } else {
        throw Exception(
            'Failed to fetch notifications. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      setState(() {
        isLoadingNotifications = false;
      });
    }
  }

  String _updateRemainingTime(DateTime endDate) {
    // Define your static sale end date
    DateTime currentDate = DateTime.now();
    Duration difference = endDate.difference(currentDate);

    if (difference.isNegative) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _remainingTime = 'Sale Ended';
          });
        }
      });

      return _remainingTime;
    } else {
      // Format the remaining time
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _remainingTime =
                '${difference.inDays}d ${difference.inHours % 24}h ${difference.inMinutes % 60}m ${difference.inSeconds % 60}s';
          });
        }
      });

      return _remainingTime;
    }
    return _remainingTime;
  }

  Future<void> _fetchStoreDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token != null) {
        final response = await http.get(
          Uri.parse(getStoreDetails),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          setState(() {
            businessName = jsonResponse['storeName'] ?? businessName;

            // Check for chosenSubscriptionPlan
            if (jsonResponse['chosenSubscriptionPlan'] == null ||
                jsonResponse['chosenSubscriptionPlan'].isEmpty) {
              _redirectToSubscriptionPlanPage(context);
            }
          });
        } else {
          throw Exception('Failed to load store details');
        }
      }
    } catch (e) {
      print('Error fetching store details: $e');
    }
  }

  void _redirectToSubscriptionPlanPage(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  20.0), // Rounded corners for the entire dialog
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top section with custom background color
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: const BoxDecoration(
                    color: myColor, // Background color for the first section
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                  ),
                  child: const Text(
                    'Activate Your Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                // Rest of the dialog
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15.0),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(178, 239, 227,
                        241), // Background color for the lower section
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10.0),
                      bottomRight: Radius.circular(10.0),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: const Text(
                          'To activate your account, you need to choose a subscription plan.',
                          style: TextStyle(
                              fontSize: 16, color: myColor, letterSpacing: 1),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChooseSubscriptionPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Choose Plan',
                            style: TextStyle(
                              color: myColor,
                              fontWeight: FontWeight.bold,
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
        },
      );
    });
  }

  Future<void> fetchPastries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(getStoreProducts),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
          // Check if `data` is a list or a map
          if (jsonResponse['data'] is List) {
            setState(() {
              pastries = List<Map<String, dynamic>>.from(jsonResponse['data']);
              filteredPastries = pastries; // Initialize filtered list
              isLoading = false;
            });
          } else if (jsonResponse['data'] is Map &&
              jsonResponse['data']['products'] != null) {
            setState(() {
              pastries = List<Map<String, dynamic>>.from(
                  jsonResponse['data']['products']);
              filteredPastries = pastries; // Initialize filtered list
              isLoading = false;
            });
          } else {
            throw Exception('Unexpected data structure in response.');
          }
        } else {
          throw Exception(
              'Failed to load pastries: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching pastries: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _filterPastries(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredPastries = pastries;
      });
    } else {
      setState(() {
        filteredPastries = pastries
            .where((pastry) =>
                pastry['name'] != null &&
                pastry['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Authentication token not found. Please log in again.')),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse('$deleteProductByID/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully!')),
        );
        setState(() {
          pastries.removeWhere((product) => product['_id'] == productId);
        });
      } else {
        throw Exception('Failed to delete product: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showDeleteConfirmationDialog(String productId, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete "$productName"?',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: myColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(productId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _getRemainingTime(String saleEndDate) {
    // Define a static sale end date for the example
    DateTime staticSaleEndDate = DateTime(2025, 2, 1, 23, 59, 59);
    DateTime endDate = DateTime.parse(saleEndDate);

    // Current date and time
    DateTime currentDate = DateTime.now();

    // Calculate the difference in time
    Duration difference = endDate.difference(currentDate);

    if (difference.isNegative) {
      return 'Sale Ended';
    }

    // Format the remaining time
    String formattedTime =
        '${difference.inDays}d ${difference.inHours % 24}h ${difference.inMinutes % 60}m';

    return formattedTime;
  }

// Helper function to calculate remaining time until the sale ends
  /* String _getRemainingTime(String saleEndDate) {
    DateTime now = DateTime.now();
    DateTime endDate = DateTime.parse(
        saleEndDate); // Assuming it's a string in ISO 8601 format

    Duration difference = endDate.difference(now);

    if (difference.isNegative) {
      return "Sale Ended";
    } else {
      int days = difference.inDays;
      int hours = difference.inHours % 24;
      int minutes = difference.inMinutes % 60;

      return '${days}d ${hours}h ${minutes}m';
    }
  }
*/
  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp); // Parse the timestamp
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 1) {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${dateTime.hour}:${dateTime.minute}';
      } else if (difference.inHours >= 1) {
        return '${difference.inHours} hour(s) ago';
      } else if (difference.inMinutes >= 1) {
        return '${difference.inMinutes} minute(s) ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      print('Error formatting timestamp: $e');
      return 'Unknown Time';
    }
  }

  Future<void> _markNotificationsAsRead() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      for (var notification in notifications) {
        if (!notification['isRead']) {
          final notificationId = notification['_id'];
          final response = await http.patch(
            Uri.parse('$markNotificationAsRead/$notificationId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            setState(() {
              notification['isRead'] = true;
            });
            print('Notification $notificationId marked as read.');
          } else {
            print(
                'Failed to mark notification $notificationId as read: ${response.body}');
          }
        }
      }
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  Future<void> _markSingleNotificationAsRead(String notificationId) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.patch(
        Uri.parse(
            '$markNotificationAsRead/$notificationId'), // Replace with your endpoint
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          final index =
              notifications.indexWhere((n) => n['_id'] == notificationId);
          if (index != -1) {
            notifications[index]['isRead'] = true;
            unreadNotificationsCount--;
          }
        });
      } else {
        throw Exception('Failed to mark notification as read.');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _clearAllNotifications() async {
    /* final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('$clearAllNotifications'), // Replace with your endpoint
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          notifications.clear();
          unreadNotificationsCount = 0;
        });
      } else {
        throw Exception('Failed to clear all notifications.');
      }
    } catch (e) {
      print('Error clearing all notifications: $e');
    }*/
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
        title: Text(
          businessName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Stack(
                clipBehavior: Clip.none, // Allow overflow for the badge
                children: [
                  const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 28,
                  ),
                  if (unreadNotificationsCount > 0)
                    Positioned(
                      right: -3, // Adjust position of the badge
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadNotificationsCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                Scaffold.of(context)
                    .openDrawer(); // Open the notification drawer
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            color: Colors.white70,
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  filteredPastries = pastries; // Reset the filtered list
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.86, // Set drawer width
        elevation: 10, // Add some elevation for a shadow effect
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(0),
          ),
        ),
        child: Container(
          height: MediaQuery.of(context).size.height *
              0.7, // Limit drawer height to 70% of the screen
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(30),
              bottomRight: Radius.circular(0),
            ),
          ),
          child: Column(
            children: [
              // Header for the drawer
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.135,
                decoration: const BoxDecoration(
                  color: myColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width * 0.06,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              //const Divider(),

              // Notifications list
              Expanded(
                child: isLoadingNotifications
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : notifications.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No notifications available.',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 15),
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final notification = notifications[index];
                              final timestamp = notification[
                                  'createdAt']; // Ensure 'createdAt' is present
                              final formattedTime = timestamp != null
                                  ? _formatTimestamp(timestamp)
                                  : 'Unknown Time';

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 16),
                                  leading: Icon(
                                    notification['isRead']
                                        ? Icons.notifications_active
                                        : Icons.notifications_active,
                                    color: notification['isRead']
                                        ? myColor.withOpacity(.5)
                                        : myColor,
                                    size: 28,
                                  ),
                                  title: Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      notification['title'] ?? 'No Title',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: myColor,
                                      ),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notification['message'] ?? 'No Message',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _formatTimestamp(
                                            notification['createdAt']),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    final notificationId = notification['_id'];
                                    await _markSingleNotificationAsRead(
                                        notificationId);
                                  },
                                ),
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const Divider(),
                          ),
              ),

              // Clear notifications button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      notifications
                          .clear(); // Clear the notification list locally
                    });
                  },
                  icon: const Icon(Icons.clear_all, color: Colors.white70),
                  label: const Text(
                    'Clear All',
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: myColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
//////////
      onDrawerChanged: (isOpened) {
        setState(() {
          isDrawerOpen = isOpened;
        });
        if (!isOpened) {
          // Drawer closed, mark notifications as read
          _markNotificationsAsRead();
        }
      },
      body: Column(
        children: [
          if (_isSearching) // Show the search box only when searching
            Container(
              color: const Color.fromARGB(171, 243, 229, 245),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: _filterPastries,
                style: const TextStyle(color: myColor),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: myColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor:
                      Colors.white24, // Lighten the background of the box
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Opacity(
                  opacity: 0.2,
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Color.fromARGB(135, 209, 183, 208)
                        /*
                      image: DecorationImage(
                        image: AssetImage('assets/images/pastry.jpg'),
                        fit: BoxFit.cover,
                      ),*/
                        ),
                  ),
                ),
                GridView.builder(
                  padding: const EdgeInsets.all(10.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 items per row
                    crossAxisSpacing: 10, // Space between columns
                    mainAxisSpacing: 10, // Space between rows
                    childAspectRatio: .65, // Adjust for item shape
                  ),
                  itemCount: filteredPastries.length +
                      1, // Include "Add Product" button
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: _isAddingProduct
                            ? null
                            : () async {
                                setState(() {
                                  _isAddingProduct = true;
                                });

                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AddPastryProduct(),
                                  ),
                                );
                                await fetchPastries(); // Refresh data

                                setState(() {
                                  _isAddingProduct = false;
                                });
                              },
                        child: Card(
                          elevation: 4,
                          color: const Color.fromARGB(171, 243, 229, 245),
                          child: Center(
                            child: _isAddingProduct
                                ? const CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(myColor),
                                  )
                                : const Icon(
                                    Icons.add,
                                    size: 50,
                                    color: myColor,
                                  ),
                          ),
                        ),
                      );
                    }

                    final pastry = filteredPastries[index - 1];
                    return Card(
                      color: const Color.fromARGB(171, 243, 229, 245),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  height: 120, // Fixed height for the image
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: pastry['image'] != null &&
                                              pastry['image'].isNotEmpty
                                          ? NetworkImage(pastry['image'])
                                              as ImageProvider
                                          : const AssetImage(
                                              'assets/images/pastry.jpg'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                if (pastry['onSale'] ==
                                    true) // Check if the product is on sale
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color.fromARGB(180, 255, 0,
                                            0), // Fully transparent
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${pastry['saleAmount']}% SALE ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (pastry['onSale'] == true)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 0),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            200, 164, 159, 168),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        pastry['remainingTime'] ??
                                            'Loading...', // Display remaining time
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pastry['name'] ?? 'No Name',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (pastry['onSale'] == true) ...[
                              Row(
                                children: [
                                  Text(
                                    '${pastry['oldPrice']?.toStringAsFixed(2) ?? '0.00'}₪',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration
                                          .lineThrough, // Strike-through
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${pastry['salePrice']?.toStringAsFixed(2) ?? '0.00'}₪',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red, // Highlight sale price
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Text(
                                '${pastry['price']?.toStringAsFixed(2) ?? '0.00'}₪',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const Spacer(), // Pushes icons to the bottom
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final updatedProduct = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditPastryProduct(product: pastry),
                                      ),
                                    );

                                    if (updatedProduct != null) {
                                      setState(() {
                                        pastries[index - 1] = updatedProduct;
                                      });
                                    }
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.transparent,
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: const Icon(
                                      Icons.edit,
                                      color: myColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showDeleteConfirmationDialog(
                                    pastry['_id'],
                                    pastry['name'],
                                  ),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.transparent,
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: const Icon(
                                      Icons.delete,
                                      color: myColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Inside the Stack's children in the build method
                if (!isLoading &&
                    filteredPastries.isEmpty &&
                    _showNoProductsOverlay)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black
                          .withOpacity(0.5), // Semi-transparent dark background
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.all(20.0),
                          padding: const EdgeInsets.all(0.0),
                          decoration: BoxDecoration(
                            color: Colors
                                .white, // Slightly opaque white background
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/tutorial1.jpg', // Ensure this image exists
                                height: MediaQuery.of(context).size.height *
                                    0.4, // 30% of screen height
                                fit: BoxFit.contain,
                              ),
                              SizedBox(height: 10),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _showNoProductsOverlay =
                                          false; // Dismiss the overlay
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        myColor, // Use your existing color
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: const Text(
                                    'Got it!',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
