import 'package:flutter/material.dart';

import '../../configuration/config.dart';
import 'video_page.dart';

/// A simple page that lists three tutorials, each with a button to open them.
class TutorialListPage extends StatelessWidget {
  const TutorialListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;
    final tutorials = [
      {
        'title': 'Add New Product',
        'description': 'Learn how to add new products to your store.',
        'videoFile': 'addProduct.mp4',
      },
      {
        'title': 'Manage Orders',
        'description': 'Tips on handling and updating orders efficiently.',
        'videoFile': 'manageOrders.mp4',
      },
      {
        'title': 'Special Orders',
        'description':
            'Design a form for special orders, letting customers fill in all required details.',
        'videoFile': 'trackDeliveries.mp4',
      },
      {
        'title': 'Sales',
        'description':
            'Set up sales on your products and announce them through notifications.',
        'videoFile': 'trackDeliveries.mp4',
      },
      {
        'title': 'Add an Advertisement to Home Page',
        'description': 'Learn how to place a promotional ad on the home page.',
        'videoFile': 'ADs.mp4',
      },
      {
        'title': 'Manage Delivery Locations',
        'description':
            'Learn how to allow delivery to cetain cities and provide the shipping fee.',
        'videoFile': 'manageDelivery.mp4',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        toolbarHeight: appBarHeight,
        title: const Text(
          'tutorials',
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
      body: ListView.builder(
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
                  color: Colors.amber, // or your preferred color
                ),
                title: Text(
                  tutorial['title'] as String,
                  style: const TextStyle(
                    color: myColor, // your custom color
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    tutorial['description'] as String,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
                trailing: ElevatedButton(
                  child: const Text(
                    'Play Video',
                    style:
                        TextStyle(color: myColor, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VideoPage(),
                      ),
                    );
                  },
                ),
              ));
        },
      ),
    );
  }
}

/// This is just a placeholder screen. You can replace it with your actual `VideoPage`
/// or any page that plays the tutorial video. Here, we show how you might receive
/// the `videoFile` name.
/*
class TutorialDetailPage extends StatelessWidget {
  final String videoFile;

  const TutorialDetailPage({
    Key? key,
    required this.videoFile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(videoFile),
      ),
      body: Center(
        child:
            Text('This is where you’d play the "$videoFile" tutorial video.'),
      ),
    );
  }
}
*/