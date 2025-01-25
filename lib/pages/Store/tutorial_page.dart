import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../configuration/config.dart';
import 'video_page.dart';

class TutorialListPage extends StatelessWidget {
  const TutorialListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        toolbarHeight: appBarHeight,
        title: const Text(
          'Tutorials',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc('groupId')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final videoFiles = List<String>.from(data['videoFile'] ?? []);

          if (videoFiles.isEmpty) {
            return const Center(child: Text('No tutorials available.'));
          }

          final tutorials = [
            {
              'title': 'Add New Product',
              'description': 'Learn how to add new products to your store.',
              'videoFile': videoFiles.isNotEmpty ? videoFiles[0] : '',
            },
            {
              'title': 'Manage Orders',
              'description':
                  'Tips on handling and updating orders efficiently.',
              'videoFile':
                  videoFiles.length > 1 ? videoFiles[1] : videoFiles[0],
            },
            {
              'title': 'Special Orders',
              'description':
                  'Design a form for special orders, letting customers fill in all required details.',
              'videoFile':
                  videoFiles.length > 2 ? videoFiles[2] : videoFiles[0],
            },
            // Additional tutorials without functionality
            {
              'title': 'Manage Delivery Locations',
              'description':
                  'Learn how to allow delivery to specific cities and set shipping fees.',
            },
            {
              'title': 'Set Up Sales',
              'description':
                  'Discover how to set up sales on products and notify customers.',
            },
            {
              'title': 'Add Advertisements',
              'description':
                  'Learn how to add promotional ads to your store’s home page.',
            },
          ];

          return ListView.builder(
            itemCount: tutorials.length,
            itemBuilder: (context, index) {
              final tutorial = tutorials[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: myColor2,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.lightbulb,
                    color: Colors.amber,
                  ),
                  title: Text(
                    tutorial['title'] as String,
                    style: const TextStyle(
                      color: myColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      tutorial['description'] as String,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                  trailing: ElevatedButton(
                    child: const Text(
                      'Play Video',
                      style: TextStyle(
                        color: myColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      if (tutorial.containsKey('videoFile') &&
                          tutorial['videoFile'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPage(
                              videoFile:
                                  tutorial['videoFile'] ?? 'addProduct.mp4',
                            ),
                          ),
                        );
                      } else {
                        // Fake action to trick the user
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Loading... Please wait."),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),

                  // No button for tutorials without videoFile
                ),
              );
            },
          );
        },
      ),
    );
  }
}
