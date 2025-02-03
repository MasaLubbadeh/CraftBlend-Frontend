import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../configuration/config.dart';
import '../../pages/chatting/chat_page.dart';
import '../../services/authentication/auth_service.dart';

class AdminChats extends StatelessWidget {
  AdminChats({super.key});

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, String>> stores = [
    {
      'storeName': 'pastryShop',
      'logo':
          'https://firebasestorage.googleapis.com/v0/b/craftblend-c388a.firebasestorage.app/o/storeLogos_images%2Flogo_1737471224067.jpg?alt=media&token=cb820ccd-863e-430c-a576-d9983b7268f4',
    },
    {
      'storeName': 'flora',
      'logo':
          'https://firebasestorage.googleapis.com/v0/b/craftblend-c388a.firebasestorage.app/o/storeLogos_images%2Flogo_1737471474790.jpg?alt=media&token=c6e73694-68b1-44b7-866d-b2ac09bfb445',
    },
    {
      'storeName': 'crochet and more',
      'logo':
          'https://firebasestorage.googleapis.com/v0/b/craftblend-c388a.firebasestorage.app/o/storeLogos_images%2Flogo_1737471590986.jpg?alt=media&token=76c28dbb-3b96-4891-bfae-8fba503c4fdb',
    },
    {
      'storeName': 'lorem',
      'logo':
          'https://firebasestorage.googleapis.com/v0/b/craftblend-c388a.firebasestorage.app/o/storeLogos_images%2Flogo_1737472004797.jpg?alt=media&token=2ce7a5e1-e862-4a70-b9b3-b1a9ab9547dd',
    },
    {
      'storeName': 'Bread & Butter',
      'logo':
          'https://firebasestorage.googleapis.com/v0/b/craftblend-c388a.firebasestorage.app/o/storeLogos_images%2Flogo_1737472074973.jpg?alt=media&token=8bbf7120-5f98-4780-9610-46aaf6a04093',
    },
    {
      'storeName': 'pottery studio',
      'logo':
          'https://firebasestorage.googleapis.com/v0/b/craftblend-c388a.firebasestorage.app/o/storeLogos_images%2Flogo_1737472200913.jpg?alt=media&token=58748d67-5ef0-4780-819d-65daaa9a3c09',
    },
    {
      'storeName': 'cake shop',
      'logo':
          'https://firebasestorage.googleapis.com/v0/b/craftblend-c388a.firebasestorage.app/o/storeLogos_images%2Flogo_1737646737785.jpg?alt=media&token=e5d0d8b2-3792-497b-ae68-43b853f6652c',
    },
    {
      'storeName': 'sweet delights',
      'logo':
          'https://firebasestorage.googleapis.com/v0/b/craftblend-c388a.firebasestorage.app/o/storeLogos_images%2Flogo_1737808638020.jpg?alt=media&token=ecf0736a-0ef8-4b9f-9ccf-15047b64f573',
    },
  ];

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: myColor,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'C H A T S',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildUserList(),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection("Users").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text("An error occurred: ${snapshot.error}"),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No chats available.",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          );
        }

        final userList = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          itemCount: userList.length,
          itemBuilder: (context, index) {
            final userData = userList[index].data() as Map<String, dynamic>;
            return _buildUserListItem(userData, context);
          },
        );
      },
    );
  }

  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null || userData["email"] == currentUser.email) {
      return const SizedBox(); // Skip displaying the current user
    }

    // Find the logo for the current store
    final store = stores.firstWhere(
      (store) => store['storeName'] == userData['storeName'],
      orElse: () => {'logo': ''},
    );
    final logoUrl = store['logo'] ?? '';
    if (userData["userType"] == 'S') {
      return GestureDetector(
        onTap: () {
          // Navigate to chat page when tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                recieverEmail: userData["email"],
                receiverID: userData["uid"],
                firstName: userData["firstName"] ?? "Unknown",
                lastName: userData["lastName"] ?? "User",
                fullName: userData["storeName"] ?? "Unknown Store",
                userType: userData["userType"] ?? "Unknown",
                profileImageUrl: logoUrl.isNotEmpty
                    ? NetworkImage(logoUrl)
                    : const AssetImage('assets/images/default_logo.png')
                        as ImageProvider,
              ),
            ),
          );
        },
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: logoUrl.isNotEmpty
                      ? NetworkImage(logoUrl)
                      : const AssetImage('assets/images/default_logo.png')
                          as ImageProvider,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData["storeName"] ?? "Unknown Store",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Tap to start a conversation",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else
      return const SizedBox();
  }
}
